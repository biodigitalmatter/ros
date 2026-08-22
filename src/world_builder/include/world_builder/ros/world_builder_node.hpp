// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <Eigen/Geometry>
#include <image_geometry/pinhole_camera_model.hpp>
#include <message_filters/subscriber.hpp>
#include <sensor_msgs/msg/camera_info.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <std_srvs/srv/trigger.hpp>
#include <tf2_ros/buffer.hpp>
#include <tf2_ros/message_filter.hpp>
#include <tf2_ros/transform_listener.hpp>

#include "world_builder/core/vdb_volume.hpp"
#include "world_builder/srv/save_volume.hpp"

namespace world_builder
{

class WorldBuilderNode : public rclcpp::Node
{
public:
  explicit WorldBuilderNode(const rclcpp::NodeOptions & options = rclcpp::NodeOptions());

private:
  void declareParameters();

  void createVolume();

  void createSubscriptions();

  void cameraInfoCallback(const sensor_msgs::msg::CameraInfo::ConstSharedPtr msg);

  void depthCallback(const sensor_msgs::msg::Image::ConstSharedPtr msg);

  void createServices();

  void saveCallback(
    const std::shared_ptr<world_builder::srv::SaveVolume::Request> request,
    std::shared_ptr<world_builder::srv::SaveVolume::Response> response);

  void clearCallback(
    const std::shared_ptr<std_srvs::srv::Trigger::Request> request,
    std::shared_ptr<std_srvs::srv::Trigger::Response> response);

  Eigen::Isometry3d lookupCameraPose(
    const std::string & camera_frame, const rclcpp::Time & timestamp);

  CameraIntrinsics cameraIntrinsics() const;

  rclcpp::Subscription<sensor_msgs::msg::CameraInfo>::SharedPtr camera_info_sub_;

  message_filters::Subscriber<sensor_msgs::msg::Image> depth_sub_;

  std::shared_ptr<tf2_ros::MessageFilter<sensor_msgs::msg::Image>> depth_filter_;

  rclcpp::Service<world_builder::srv::SaveVolume>::SharedPtr save_service_;
  rclcpp::Service<std_srvs::srv::Trigger>::SharedPtr clear_service_;

  tf2_ros::Buffer tf_buffer_;
  tf2_ros::TransformListener tf_listener_;
  std::uint32_t tf_filter_queue_size_{10};

  std::unique_ptr<VdbVolume> volume_;
  std::mutex volume_mutex_;

  image_geometry::PinholeCameraModel camera_model_;
  bool have_camera_model_{false};
  std::uint32_t camera_width_{0};
  std::uint32_t camera_height_{0};
  CameraIntrinsics intrinsics_;

  std::string world_frame_;
  std::string depth_topic_;
  std::string camera_info_topic_;

  double depth_scale_{0.001};

  VdbVolumeConfig volume_config_;
};

}  // namespace world_builder
