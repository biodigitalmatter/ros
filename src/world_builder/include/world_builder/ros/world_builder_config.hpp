#pragma once

#include <cstdint>
#include <rclcpp/rclcpp.hpp>
#include <string>
#include <tl/expected.hpp>

#include "world_builder/core/vdb_volume.hpp"

namespace world_builder
{

struct RawWorldBuilderConfig
{
  std::string world_frame;
  std::string camera_info_topic;
  std::string depth_topic;

  std::int64_t tf_filter_queue_size;

  double depth_scale;

  double volume_voxel_size;
  double volume_truncation_distance;
  double volume_max_weight;
};

struct WorldBuilderConfig
{
  std::string world_frame;
  std::string camera_info_topic;
  std::string depth_topic;

  std::uint32_t tf_filter_queue_size;

  double depth_scale;

  VdbVolumeConfig volume;
};

using WorldBuilderConfigResult = tl::expected<WorldBuilderConfig, std::string>;

WorldBuilderConfigResult parseWorldBuilderConfig(const RawWorldBuilderConfig & raw);

WorldBuilderConfigResult loadWorldBuilderConfigFromRosParameters(rclcpp::Node & node);

}  // namespace world_builder
