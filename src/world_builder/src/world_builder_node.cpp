// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include "world_builder/world_builder_node.hpp"

#include <cstdint>
#include <exception>
#include <functional>
#include <geometry_msgs/msg/transform_stamped.hpp>
#include <memory>
#include <mutex>
#include <sensor_msgs/image_encodings.hpp>
#include <tf2_eigen/tf2_eigen.hpp>

#include "world_builder/vdb_volume.hpp"

namespace world_builder
{

WorldBuilderNode::WorldBuilderNode(const rclcpp::NodeOptions & options)
: Node("world_builder", options), tf_buffer_(this->get_clock()), tf_listener_(tf_buffer_)
{
  declareParameters();
  createVolume();
  createSubscriptions();
  createServices();

  RCLCPP_INFO(get_logger(), "World builder node started");
  RCLCPP_INFO(get_logger(), " world frame: %s", world_frame_.c_str());
  RCLCPP_INFO(get_logger(), " depth topic: %s", depth_topic_.c_str());
  RCLCPP_INFO(get_logger(), " camera info: %s", camera_info_topic_.c_str());
  RCLCPP_INFO(get_logger(), " voxel size: %.4f m", volume_config_.voxel_size);
  RCLCPP_INFO(get_logger(), " truncation distance: %.4f m", volume_config_.truncation_distance);
}

void WorldBuilderNode::declareParameters()
{
  world_frame_ = declare_parameter<std::string>("world_frame", "map");

  depth_topic_ = declare_parameter<std::string>("depth_topic", "/camera/depth/image_rect_raw");

  camera_info_topic_ =
    declare_parameter<std::string>("camera_info_topic", "/camera/depth/camera_info");

  depth_scale_ = declare_parameter<double>("depth_scale", 0.001);

  volume_config_.voxel_size = declare_parameter<double>("voxel_size", 0.005);
  volume_config_.truncation_distance = declare_parameter<double>("truncation_distance", 0.02);
  volume_config_.max_weight = static_cast<float>(declare_parameter<double>("max_weight", 100.0));
}

void WorldBuilderNode::createVolume()
{
  volume_ = std::make_unique<VdbVolume>(volume_config_);

  RCLCPP_INFO(
    get_logger(),
    "Created VDB volume: voxel_size=%.4f m, "
    "truncation=%.4f m, "
    "max_weight=%.1f",
    volume_config_.voxel_size, volume_config_.truncation_distance, volume_config_.max_weight);
}

void WorldBuilderNode::createSubscriptions()
{
  const auto qos = rclcpp::SensorDataQoS();
  depth_sub_ = create_subscription<sensor_msgs::msg::Image>(
    depth_topic_, qos, std::bind(&WorldBuilderNode::depthCallback, this, std::placeholders::_1));

  camera_info_sub_ = create_subscription<sensor_msgs::msg::CameraInfo>(
    camera_info_topic_, qos,
    std::bind(&WorldBuilderNode::cameraInfoCallback, this, std::placeholders::_1));
}

void WorldBuilderNode::cameraInfoCallback(const sensor_msgs::msg::CameraInfo::ConstSharedPtr msg)
{
  camera_model_.fromCameraInfo(msg);

  have_camera_model_ = camera_model_.initialized();

  if (have_camera_model_) {
    camera_width_ = msg->width;
    camera_height_ = msg->height;
  } else {
    RCLCPP_WARN(get_logger(), "Received invalid CameraInfo");
  }
}

void WorldBuilderNode::depthCallback(const sensor_msgs::msg::Image::ConstSharedPtr msg)
{
  if (!have_camera_model_) {
    RCLCPP_WARN_THROTTLE(get_logger(), *get_clock(), 5000, "Waiting for camera info");
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
  // Metric conversion is controlled seprately by depth_scale_
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

  const std::size_t required_size =
    static_cast<std::size_t>(msg->step) * static_cast<std::size_t>(msg->height);

  if (msg->data.size() < required_size) {
    RCLCPP_ERROR(get_logger(), "Depth image data buffer is too small");

    return;
  }

  Eigen::Isometry3d T_world_camera;

  try {
    T_world_camera = lookupCameraPose(msg->header.frame_id, rclcpp::Time(msg->header.stamp));
  } catch (const tf2::TransformException & e) {
    RCLCPP_WARN_THROTTLE(
      get_logger(), *get_clock(), 2000,
      "Could not transform camera frame '%s' "
      "to world frame '%s': %s",
      msg->header.frame_id.c_str(), world_frame_.c_str(), e.what());
    return;
  }

  const auto intrinsics = cameraIntrinsics();

  // FIXME: Assumes native-endian, suitably aligned 16UC1 data.
  const auto * depth_data = reinterpret_cast<const std::uint16_t *>(msg->data.data());

  try {
    std::lock_guard<std::mutex> lock(volume_mutex_);

    volume_->integrateDepthImage(
      depth_data, static_cast<int>(msg->width), static_cast<int>(msg->height),
      static_cast<std::size_t>(msg->step), depth_scale_, intrinsics, T_world_camera);

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
  const geometry_msgs::msg::TransformStamped T = tf_buffer_.lookupTransform(
    world_frame_, camera_frame, timestamp, rclcpp::Duration::from_seconds(0.05));

  return tf2::transformToEigen(T);
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
