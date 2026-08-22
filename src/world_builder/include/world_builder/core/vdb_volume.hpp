// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#pragma once

#include <openvdb/openvdb.h>

#include <Eigen/Geometry>
#include <cstdint>
#include <string>

namespace world_builder
{
struct CameraIntrinsics
{
  double fx{};
  double fy{};
  double cx{};
  double cy{};
  int width{};
  int height{};
};

struct VdbVolumeConfig
{
  double voxel_size{0.005};
  double truncation_distance{0.02};
  float max_weight{100.0F};
};

class VdbVolume
{
public:
  explicit VdbVolume(const VdbVolumeConfig & config);

  void integrateDepthImage(
    const uint16_t * depth_data, int width, int height, std::size_t row_stride_bytes,
    double depth_scale, const CameraIntrinsics & intrinsics,
    const Eigen::Isometry3d & T_world_camera);

  void clear();

  void save(const std::string & filename) const;

  const openvdb::FloatGrid::Ptr & tsdfGrid() const;

  const openvdb::FloatGrid::Ptr & weightGrid() const;

  const VdbVolumeConfig & config() const;

private:
  void integratePixel(
    int u, int v, double depth, const CameraIntrinsics & intrinsics,
    const Eigen::Isometry3d & T_world_camera, openvdb::FloatGrid::Accessor & tsdf_accessor,
    openvdb::FloatGrid::Accessor & weight_accessor);

  void updateVoxel(
    const Eigen::Vector3d & world_position, float signed_distance, float observation_weight,
    openvdb::FloatGrid::Accessor & tsdf_accessor, openvdb::FloatGrid::Accessor & weight_accessor);

  VdbVolumeConfig config_;

  openvdb::FloatGrid::Ptr tsdf_;
  openvdb::FloatGrid::Ptr weight_;
};

}  // namespace world_builder
