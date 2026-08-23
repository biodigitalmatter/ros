// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include "world_builder/ros/world_builder_config.hpp"

#include <cmath>
#include <cstdint>
#include <gsl/narrow>

namespace world_builder
{

WorldBuilderConfigResult parseWorldBuilderConfig(const RawWorldBuilderConfig & raw)
{
  // also throws rclcpp::exceptions::InvalidTopicNameError
  if (raw.world_frame.empty()) {
    return tl::unexpected("world_frame must not be empty");
  }

  if (raw.camera_info_topic.empty()) {
    return tl::unexpected("camera_info_topic must not be empty");
  }

  if (raw.depth_topic.empty()) {
    return tl::unexpected("depth_topic must not be empty");
  }

  std::uint32_t tf_filter_queue_size;

  try {
    tf_filter_queue_size = gsl::narrow<std::uint32_t>(raw.tf_filter_queue_size);
  } catch (const gsl::narrowing_error &) {
    return tl::unexpected("tf_filter_queue_size is out of range");
  }

  if (tf_filter_queue_size == 0) {
    return tl::unexpected("tf_filter_queue_size must be larger than 0");
  }

  if (raw.depth_scale <= 0.0 || !std::isfinite(raw.depth_scale)) {
    return tl::unexpected("depth_scale must be finite and > 0");
  }

  float volume_max_weight;

  try {
    volume_max_weight = gsl::narrow<float>(raw.volume_max_weight);
  } catch (const gsl::narrowing_error &) {
    return tl::unexpected("volume_max_weight is out of range");
  }

  return WorldBuilderConfig{
    raw.world_frame,
    raw.camera_info_topic,
    raw.depth_topic,
    tf_filter_queue_size,
    raw.depth_scale,
    VdbVolumeConfig{raw.volume_voxel_size, raw.volume_truncation_distance, volume_max_weight}};
}

WorldBuilderConfigResult loadWorldBuilderConfigFromRosParameters(rclcpp::Node & node)
{
  const RawWorldBuilderConfig raw{

    node.declare_parameter<std::string>("world_frame", "map"),
    node.declare_parameter<std::string>("camera_info_topic", "/camera/depth/camera_info"),

    node.declare_parameter<std::string>("depth_topic", "/camera/depth/image_rect_raw"),

    node.declare_parameter<std::int64_t>("tf_filter_queue_size", 10),

    node.declare_parameter<double>("depth_scale", 0.001),

    node.declare_parameter<double>("voxel_size", 0.005),

    node.declare_parameter<double>("truncation_distance", 0.02),

    node.declare_parameter<double>("max_weight", 100.0),
  };

  return parseWorldBuilderConfig(raw);
}
}  // namespace world_builder
