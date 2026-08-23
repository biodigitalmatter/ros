// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include <gtest/gtest.h>

#include <cstdint>
#include <limits>

#include "world_builder/ros/world_builder_config.hpp"

namespace world_builder
{
namespace
{

RawWorldBuilderConfig validRawConfig()
{
  return RawWorldBuilderConfig{
    std::string("map"),
    std::string("/camera/depth/camera_info"),
    std::string("/camera/depth/image_rect_raw"),
    10,
    0.001,
    0.005,
    0.02,
    100.0,
  };
}

TEST(WorldBuilderConfigTest, ParsesValidConfig)
{
  const auto raw = validRawConfig();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_TRUE(result.has_value());

  const auto & config = result.value();

  EXPECT_EQ(config.world_frame, raw.world_frame);
  EXPECT_EQ(config.camera_info_topic, raw.camera_info_topic);
  EXPECT_EQ(config.depth_topic, raw.depth_topic);

  EXPECT_EQ(config.tf_filter_queue_size, 10U);
  EXPECT_DOUBLE_EQ(config.depth_scale, 0.001);

  EXPECT_DOUBLE_EQ(config.volume.voxel_size, 0.005);
  EXPECT_DOUBLE_EQ(config.volume.truncation_distance, 0.02);
  EXPECT_FLOAT_EQ(config.volume.max_weight, 100.0F);
}

TEST(WorldBuilderConfigTest, RejectsEmptyWorldFrame)
{
  auto raw = validRawConfig();
  raw.world_frame.clear();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "world_frame must not be empty");
}

TEST(WorldBuilderConfigTest, RejectsEmptyCameraInfoTopic)
{
  auto raw = validRawConfig();
  raw.camera_info_topic.clear();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "camera_info_topic must not be empty");
}

TEST(WorldBuilderConfigTest, RejectsEmptyDepthTopic)
{
  auto raw = validRawConfig();
  raw.depth_topic.clear();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "depth_topic must not be empty");
}

TEST(WorldBuilderConfigTest, RejectsZeroTfFilterQueueSize)
{
  auto raw = validRawConfig();
  raw.tf_filter_queue_size = 0;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "tf_filter_queue_size must be larger than 0");
}

TEST(WorldBuilderConfigTest, RejectsNegativeTfFilterQueueSize)
{
  auto raw = validRawConfig();
  raw.tf_filter_queue_size = -1;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "tf_filter_queue_size is out of range");
}

TEST(WorldBuilderConfigTest, RejectsTfFilterQueueSizeLargerThanUint32)
{
  auto raw = validRawConfig();

  raw.tf_filter_queue_size =
    static_cast<std::int64_t>(std::numeric_limits<std::uint32_t>::max()) + 1;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "tf_filter_queue_size is out of range");
}

TEST(WorldBuilderConfigTest, AcceptsMaximumUint32TfFilterQueueSize)
{
  auto raw = validRawConfig();

  raw.tf_filter_queue_size = static_cast<std::int64_t>(std::numeric_limits<std::uint32_t>::max());

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_TRUE(result.has_value());
  EXPECT_EQ(result->tf_filter_queue_size, std::numeric_limits<std::uint32_t>::max());
}

TEST(WorldBuilderConfigTest, RejectsZeroDepthScale)
{
  auto raw = validRawConfig();
  raw.depth_scale = 0.0;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "depth_scale must be finite and > 0");
}

TEST(WorldBuilderConfigTest, RejectsNegativeDepthScale)
{
  auto raw = validRawConfig();
  raw.depth_scale = -0.001;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "depth_scale must be finite and > 0");
}

TEST(WorldBuilderConfigTest, RejectsInfiniteDepthScale)
{
  auto raw = validRawConfig();

  raw.depth_scale = std::numeric_limits<double>::infinity();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "depth_scale must be finite and > 0");
}

TEST(WorldBuilderConfigTest, RejectsNanDepthScale)
{
  auto raw = validRawConfig();

  raw.depth_scale = std::numeric_limits<double>::quiet_NaN();

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "depth_scale must be finite and > 0");
}

TEST(WorldBuilderConfigTest, RejectsMaxWeightOutsideFloatRange)
{
  auto raw = validRawConfig();

  raw.volume_max_weight = static_cast<double>(std::numeric_limits<float>::max()) * 2.0;

  const auto result = parseWorldBuilderConfig(raw);

  ASSERT_FALSE(result.has_value());
  EXPECT_EQ(result.error(), "volume_max_weight is out of range");
}

}  // namespace
}  // namespace world_builder
