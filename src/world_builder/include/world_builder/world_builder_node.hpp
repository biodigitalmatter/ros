// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <Eigen/Geometry>
#include <memory>
#include <mutex>
#include <rclcpp/rclcpp.hpp>
#include <sensor_msgs/msg/camera_info.hpp>
#include <sensor_msgs/msg/image.hpp>
#include <std_srvs/srv/trigger.hpp>
#include <string>
#include <tf2_ros/buffer.hpp>
#include <tf2_ros/transform_listener.hpp>

#include "world_builder/srv/save_volume.hpp"
#include "world_builder/vdb_volume.hpp"

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

  void cameraInfoCallback(const sensor_msgs::msg::CameraInfo::SharedPtr msg);

  void depthCallback(const sensor_msgs::msg::Image::SharedPtr msg);

  void createServices();

  void saveCallback(
    const std::shared_ptr<world_builder::srv::SaveVolume::Request> request,
    std::shared_ptr<world_builder::srv::SaveVolume::Response> response);

  void clearCallback(
    const std::shared_ptr<std_srvs::srv::Trigger::Request> request,
    std::shared_ptr<std_srvs::srv::Trigger::Response> response);

  Eigen::Isometry3d lookupCameraPose(
    const std::string & camera_frame, const rclcpp::Time & timestamp);

  rclcpp::Subscription<sensor_msgs::msg::CameraInfo>::SharedPtr camera_info_sub_;

  rclcpp::Subscription<sensor_msgs::msg::Image>::SharedPtr depth_sub_;

  rclcpp::Service<world_builder::srv::SaveVolume>::SharedPtr save_service_;
  rclcpp::Service<std_srvs::srv::Trigger>::SharedPtr clear_service_;

  tf2_ros::Buffer tf_buffer_;
  tf2_ros::TransformListener tf_listener_;

  std::unique_ptr<VdbVolume> volume_;
  std::mutex volume_mutex_;

  CameraIntrinsics intrinsics_;
  bool have_intrinsics_{false};

  std::string world_frame_;
  std::string depth_topic_;
  std::string camera_info_topic_;

  double depth_scale_{0.001};

  VdbVolumeConfig volume_config_;
};

}  // namespace world_builder
