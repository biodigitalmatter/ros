// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include <gtest/gtest.h>
#include <openvdb/openvdb.h>

#include <cstdint>

#include "world_builder/core/vdb_volume.hpp"

namespace world_builder
{
namespace
{

constexpr VdbVolumeConfig defaultConfig() { return VdbVolumeConfig{0.01, 0.03, 100.0F}; }

TEST(VdbVolumeTest, ConstructsEmptyVolume)
{
  VdbVolume volume(defaultConfig());

  ASSERT_NE(volume.tsdfGrid(), nullptr);
  ASSERT_NE(volume.weightGrid(), nullptr);

  EXPECT_EQ(volume.tsdfGrid()->activeVoxelCount(), 0);
  EXPECT_EQ(volume.weightGrid()->activeVoxelCount(), 0);
}

TEST(VdbVolumeTest, HasExpectedVoxelSize)
{
  constexpr auto config = defaultConfig();

  VdbVolume volume(config);

  const auto voxel_size = volume.tsdfGrid()->voxelSize();

  EXPECT_DOUBLE_EQ(voxel_size.x(), config.voxel_size);
  EXPECT_DOUBLE_EQ(voxel_size.y(), config.voxel_size);
  EXPECT_DOUBLE_EQ(voxel_size.z(), config.voxel_size);
}

TEST(VdbVolumeTest, ClearRemoveVoxels)
{
  VdbVolume volume(defaultConfig());
  auto accessor = volume.tsdfGrid()->getAccessor();

  accessor.setValue(openvdb::Coord(1, 2, 3), 0.5F);

  ASSERT_GT(volume.tsdfGrid()->activeVoxelCount(), 0);

  volume.clear();

  EXPECT_EQ(volume.tsdfGrid()->activeVoxelCount(), 0);
  EXPECT_EQ(volume.weightGrid()->activeVoxelCount(), 0);
}

TEST(VdbVolumeTest, IntegratesDepthImage)
{
  VdbVolume volume(defaultConfig());

  constexpr CameraIntrinsics intrinsics{100.0, 100.0, 1.0, 1.0, 3, 3};

  constexpr std::uint16_t depth[] = {
    1000, 1000, 1000,  //
    1000, 1000, 1000,  //
    1000, 1000, 1000,
  };

  const Eigen::Isometry3d T_world_camera = Eigen::Isometry3d::Identity();

  volume.integrateDepthImage(
    depth, 3, 3, 3 * sizeof(std::uint16_t), 0.001, intrinsics, T_world_camera);

  EXPECT_GT(volume.tsdfGrid()->activeVoxelCount(), 0);

  EXPECT_GT(volume.weightGrid()->activeVoxelCount(), 0);
}

TEST(VdbVolumeTest, SurfaceHasTsdfNearZero)
{
  constexpr auto config = defaultConfig();

  VdbVolume volume(config);

  /*
   * Dummy camera producing image with a single pixel (w=h=1)
   *
   *   pixel has coord:          u, v = 0, 0
   *   principal point at pixel: cx, cy = 0, 0
   *   given depth value: 1.0 m
   *
   * Pinhole back-projection:
   *
   *   X = (u - cx) * Z / fx = 0
   *   Y = (v - cy) * Z / fy = 0
   *   Z = depth             = 1.0 m
   *
   *   focal lengths fx and fy are irrelevant for this ray because both (u - cx) and (v - cy) are
   *   zero. They still need to be non-zero though.
   *
   */

  constexpr CameraIntrinsics intrinsics{100., 100., 0., 0., 1, 1};

  constexpr std::uint16_t depth[] = {1000};  // with depth_scale = 0.001;

  const Eigen::Isometry3d T_world_camera = Eigen::Isometry3d::Identity();

  volume.integrateDepthImage(depth, 1, 1, sizeof(std::uint16_t), 0.001, intrinsics, T_world_camera);

  // our known point (with value 1000)
  const openvdb::Vec3d xyz{0.0, 0.0, 1.0};

  // the voxel centre is not exactly at at z = 1.0, unless the voxel lattice happens to align
  const auto ijk = openvdb::Coord::round(volume.tsdfGrid()->worldToIndex(xyz));

  const auto tsdf_accessor = volume.tsdfGrid()->getConstAccessor();

  const auto weight_accessor = volume.weightGrid()->getConstAccessor();

  // ensure observed and make sure we don't get voxel background value
  EXPECT_TRUE(weight_accessor.isValueOn(ijk));

  // positive value means at least one observation contributed to this voxel
  EXPECT_GT(weight_accessor.getValue(ijk), 0.0F);

  // TSDF 0 means at surface. Will only be exactly zero if voxel lattice is aligned
  EXPECT_NEAR(tsdf_accessor.getValue(ijk), 0.0F, 0.2F);
}

}  // namespace

}  // namespace world_builder
