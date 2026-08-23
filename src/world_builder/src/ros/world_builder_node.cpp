// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include "world_builder/ros/world_builder_node.hpp"

#include <sensor_msgs/image_encodings.hpp>
#include <stdexcept>
#include <tf2_eigen/tf2_eigen.hpp>

#include "world_builder/core/vdb_volume.hpp"
#include "world_builder/ros/world_builder_config.hpp"

namespace world_builder
{

WorldBuilderNode::WorldBuilderNode(const rclcpp::NodeOptions & options)
: Node("world_builder", options), tf_buffer_(this->get_clock()), tf_listener_(tf_buffer_)
{
  auto config_result = loadWorldBuilderConfigFromRosParameters(*this);
  if (!config_result) {
    throw std::invalid_argument(
      "Invalid argument in world builder configuration " + config_result.error());
  }

  config_ = std::move(*config_result);

  RCLCPP_INFO(get_logger(), "World builder node started");
  RCLCPP_INFO(get_logger(), " world frame: %s", config_.world_frame.c_str());
  RCLCPP_INFO(get_logger(), " depth topic: %s", config_.depth_topic.c_str());
  RCLCPP_INFO(get_logger(), " camera info: %s", config_.camera_info_topic.c_str());
  RCLCPP_INFO(get_logger(), " voxel size: %.4f m", config_.volume.voxel_size);
  RCLCPP_INFO(get_logger(), " truncation distance: %.4f m", config_.volume.truncation_distance);

  createVolume();
  createSubscriptions();
  createServices();
}

void WorldBuilderNode::createVolume()
{
  volume_ = std::make_unique<VdbVolume>(config_.volume);

  RCLCPP_INFO(
    get_logger(),
    "Created VDB volume: voxel_size=%.4f m, "
    "truncation=%.4f m, "
    "max_weight=%.1f",
    config_.volume.voxel_size, config_.volume.truncation_distance, config_.volume.max_weight);
}

void WorldBuilderNode::createSubscriptions()
{
  camera_info_sub_ = create_subscription<sensor_msgs::msg::CameraInfo>(
    config_.camera_info_topic, rclcpp::SensorDataQoS(),
    std::bind(&WorldBuilderNode::cameraInfoCallback, this, std::placeholders::_1));

  depth_sub_.subscribe(this, config_.depth_topic, rmw_qos_profile_sensor_data);

  depth_filter_ = std::make_shared<tf2_ros::MessageFilter<sensor_msgs::msg::Image>>(
    depth_sub_, tf_buffer_, config_.world_frame, config_.tf_filter_queue_size,
    this->get_node_logging_interface(), this->get_node_clock_interface());

  depth_filter_->registerCallback(
    std::bind(&WorldBuilderNode::depthCallback, this, std::placeholders::_1));
}

void WorldBuilderNode::cameraInfoCallback(const sensor_msgs::msg::CameraInfo::ConstSharedPtr msg)
{
  camera_model_.fromCameraInfo(msg);

  have_camera_model_ = camera_model_.initialized();

  if (have_camera_model_) {
    camera_width_ = msg->width;
    camera_height_ = msg->height;

    intrinsics_ = cameraIntrinsics();

  } else {
    RCLCPP_WARN(get_logger(), "Received invalid CameraInfo");
  }
}

void WorldBuilderNode::depthCallback(const sensor_msgs::msg::Image::ConstSharedPtr msg)
{
  if (!have_camera_model_) {
    return;
  }

  if (msg->width == 0 || msg->height == 0) {
    RCLCPP_WARN(get_logger(), "Received empty depth image");
    return;
  }

  if (msg->width != camera_width_ || msg->height != camera_height_) {
    RCLCPP_WARN_THROTTLE(
      get_logger(), *get_clock(), 5000,
      "Depth image dimensions %ux%u do not match "
      "CameraInfo dimensions %ux%u",
      msg->width, msg->height, camera_width_, camera_height_);

    return;
  }

  // NOTE: Currently accepts uint16_t single-channel depth (OpenCV 16UC1)
  // Metric conversion is controlled separately by depth_scale_
  if (msg->encoding != sensor_msgs::image_encodings::TYPE_16UC1) {
    RCLCPP_WARN_THROTTLE(
      get_logger(), *get_clock(), 5000, "Unsupported depth encoding: %s", msg->encoding.c_str());
    return;
  }

  const std::size_t minimum_step = static_cast<std::size_t>(msg->width) * sizeof(std::uint16_t);

  if (msg->step < minimum_step) {
    RCLCPP_ERROR(
      get_logger(), "Invalid depth image step: %u, expected at least %zu", msg->step, minimum_step);
    return;
  }

  // paranoid check
  // msg->height > 0 as per check above. No risk of division by zero.
  if (
    static_cast<std::size_t>(msg->step) >
    std::numeric_limits<std::size_t>::max() / static_cast<std::size_t>(msg->height)) {
    RCLCPP_ERROR(get_logger(), "Depth image size overflows size_t");

    return;
  }

  const std::size_t required_size =
    static_cast<std::size_t>(msg->step) * static_cast<std::size_t>(msg->height);

  if (msg->data.size() < required_size) {
    RCLCPP_ERROR(get_logger(), "Depth image data buffer is too small");

    return;
  }

  if (msg->header.frame_id.empty()) {
    RCLCPP_WARN_THROTTLE(get_logger(), *get_clock(), 5, "Depth image has empty frame_id");

    return;
  }

  Eigen::Isometry3d T_world_camera;

  try {
    T_world_camera = lookupCameraPose(msg->header.frame_id, rclcpp::Time(msg->header.stamp));

  } catch (const tf2::TransformException & e) {
    RCLCPP_WARN_THROTTLE(
      get_logger(), *get_clock(), 2000, "Couldn't look up transform: %s", e.what());
    return;
  }

  if (msg->is_bigendian != 0) {
    RCLCPP_WARN_THROTTLE(get_logger(), *get_clock(), 5000, "Big-endian depth images not supported");
    return;
  }

  // FIXME: Assumes native-endian, suitably aligned 16UC1 data.
  const auto * depth_data = reinterpret_cast<const std::uint16_t *>(msg->data.data());

  try {
    std::lock_guard<std::mutex> lock(volume_mutex_);

    volume_->integrateDepthImage(
      depth_data, static_cast<int>(msg->width), static_cast<int>(msg->height),
      static_cast<std::size_t>(msg->step), config_.depth_scale, intrinsics_, T_world_camera);

  } catch (const std::exception & e) {
    RCLCPP_ERROR(get_logger(), "Failed to integrate depth image: %s", e.what());
  }
}

void WorldBuilderNode::createServices()
{
  save_service_ = create_service<world_builder::srv::SaveVolume>(
    "~/save",
    std::bind(&WorldBuilderNode::saveCallback, this, std::placeholders::_1, std::placeholders::_2));

  clear_service_ = create_service<std_srvs::srv::Trigger>(
    "~/clear",
    std::bind(
      &WorldBuilderNode::clearCallback, this, std::placeholders::_1, std::placeholders::_2));
}

void WorldBuilderNode::saveCallback(
  const std::shared_ptr<world_builder::srv::SaveVolume::Request> request,
  std::shared_ptr<world_builder::srv::SaveVolume::Response> response)
{
  if (request->filename.empty()) {
    response->success = false;
    response->message = "Filename must not be empty";
    return;
  }

  try {
    std::lock_guard<std::mutex> lock(volume_mutex_);
    volume_->save(request->filename);

    response->success = true;
    response->message = "Saved volume to " + request->filename;

    RCLCPP_INFO(get_logger(), "%s", response->message.c_str());

  } catch (const std::exception & e) {
    response->success = false;
    response->message = e.what();

    RCLCPP_ERROR(get_logger(), "Failed to save volume: %s", e.what());
  }
}

void WorldBuilderNode::clearCallback(
  const std::shared_ptr<std_srvs::srv::Trigger::Request> /* request */,
  std::shared_ptr<std_srvs::srv::Trigger::Response> response)
{
  try {
    std::lock_guard<std::mutex> lock(volume_mutex_);

    volume_->clear();

    response->success = true;
    response->message = "Volume cleared";

    RCLCPP_INFO(get_logger(), "Volume cleared");

  } catch (const std::exception & e) {
    response->success = false;
    response->message = e.what();

    RCLCPP_ERROR(get_logger(), "Failed to clear volume: %s", e.what());
  }
}

Eigen::Isometry3d WorldBuilderNode::lookupCameraPose(
  const std::string & camera_frame, const rclcpp::Time & timestamp)
{
  const auto xform = tf_buffer_.lookupTransform(config_.world_frame, camera_frame, timestamp);

  return tf2::transformToEigen(xform);
}

CameraIntrinsics WorldBuilderNode::cameraIntrinsics() const
{
  return CameraIntrinsics{
    camera_model_.fx(),
    camera_model_.fy(),
    camera_model_.cx(),
    camera_model_.cy(),
    static_cast<int>(camera_width_),
    static_cast<int>(camera_height_)};
}

}  // namespace world_builder
