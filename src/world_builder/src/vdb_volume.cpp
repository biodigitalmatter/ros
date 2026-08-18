// SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
// SPDX-License-Identifier: Apache-2.0

#include "world_builder/vdb_volume.hpp"

namespace world_builder
{

VdbVolume::VdbVolume(const VdbVolumeConfig & config) : config_(config)
{
  if (config_.voxel_size <= 0.0) {
    throw std::invalid_argument("voxel_size must be > 0");
  }

  if (config_.truncation_distance <= 0.0) {
    throw std::invalid_argument("truncation_distance must be > 0");
  }

  if (config_.max_weight <= 0.0F) {
    throw std::invalid_argument("max_weight must be > 0");
  }

  openvdb::initialize();

  /*
   * The TSDF is normalized:
   *
   *   +1.0   at least truncation_distance in front of surface
   *    0.0   surface
   *   -1.0   at least truncation_distance behind surface
   *
   * Unobserved voxels have weight == 0, so the TSDF background value
   * itself should not be interpreted as an observation.
   */
  tsdf_ = openvdb::FloatGrid::create(1.0F);
  weight_ = openvdb::FloatGrid::create(0.0F);

  const auto xform = openvdb::math::Transform::createLinearTransform(config_.voxel_size);

  tsdf_->setTransform(xform->copy());
  weight_->setTransform(xform->copy());

  tsdf_->setName("tsdf");
  weight_->setName("weight");
}

void VdbVolume::integrateDepthImage(
  const uint16_t * depth_data, int width, int height, std::size_t row_stride_bytes,
  double depth_scale, const CameraIntrinsics & intrinsics, const Eigen::Isometry3d & T_world_camera)
{
  if (depth_data == nullptr) {
    throw std::invalid_argument("depth_data must not be null");
  }

  if (width <= 0 || height <= 0) {
    throw std::invalid_argument("depth image dimensions must be positive");
  }

  if (depth_scale <= 0.0) {
    throw std::invalid_argument("depth_scale must be > 0");
  }

  if (intrinsics.fx <= 0.0 || intrinsics.fy <= 0.0) {
    throw std::invalid_argument("invalid camera intrinsics");
  }

  const std::size_t minimum_stride = static_cast<std::size_t>(width) * sizeof(uint16_t);

  if (row_stride_bytes < minimum_stride) {
    throw std::invalid_argument("depth image row stride is too small");
  }

  auto tsdf_accessor = tsdf_->getAccessor();
  auto weight_accessor = weight_->getAccessor();

  /*
   * sensor_msgs/Image::step is a byte stride, so do not assume rows are
   * packed as width * sizeof(uint16_t).
   */
  const auto * bytes = reinterpret_cast<const std::uint8_t *>(depth_data);

  for (int v = 0; v < height; ++v) {
    const auto * row =
      reinterpret_cast<const uint16_t *>(bytes + static_cast<std::size_t>(v) * row_stride_bytes);

    for (int u = 0; u < width; ++u) {
      const uint16_t raw_depth = row[u];

      // librealsense uses zero for invalid Z16 measurements.
      if (raw_depth == 0) {
        continue;
      }

      const double depth = static_cast<double>(raw_depth) * depth_scale;

      integratePixel(u, v, depth, intrinsics, T_world_camera, tsdf_accessor, weight_accessor);
    }
  }
}

void VdbVolume::clear()
{
  tsdf_->clear();
  weight_->clear();
}

void VdbVolume::save(const std::string & filename) const
{
  if (filename.empty()) {
    throw std::invalid_argument("filename must not be empty");
  }

  openvdb::GridPtrVec grids;

  grids.push_back(tsdf_);
  grids.push_back(weight_);

  openvdb::io::File file(filename);
  file.write(grids);
  file.close();
}

const openvdb::FloatGrid::Ptr & VdbVolume::tsdfGrid() const { return tsdf_; }

const openvdb::FloatGrid::Ptr & VdbVolume::weightGrid() const { return weight_; }

const VdbVolumeConfig & VdbVolume::config() const { return config_; }

void VdbVolume::integratePixel(
  int u, int v, double depth, const CameraIntrinsics & intrinsics,
  const Eigen::Isometry3d & T_world_camera, openvdb::FloatGrid::Accessor & tsdf_accessor,
  openvdb::FloatGrid::Accessor & weight_accessor)
{
  /*
   * Depth images from realsense2_camera use Z-depth:
   * the depth value is the Z coordinate in the camera optical frame,
   * not Euclidean range along the viewing ray.
   *
   * Back-project using the pinhole camera model:
   *
   *   X = (u - cx) * Z / fx
   *   Y = (v - cy) * Z / fy
   *   Z = depth
   */
  const Eigen::Vector3d p_camera{
    (static_cast<double>(u) - intrinsics.cx) * depth / intrinsics.fx,
    (static_cast<double>(v) - intrinsics.cy) * depth / intrinsics.fy, depth};

  const Eigen::Vector3d camera_origin_world = T_world_camera.translation();

  const Eigen::Vector3d surface_world = T_world_camera * p_camera;

  const Eigen::Vector3d ray = surface_world - camera_origin_world;

  const double surface_range = ray.norm();

  if (surface_range <= 0.0) {
    return;
  }

  const Eigen::Vector3d ray_direction = ray / surface_range;

  /*
   * For the initial implementation we only activate voxels inside the
   * truncation band surrounding the measured surface.
   *
   * We therefore build a sparse surface TSDF rather than explicitly
   * representing all observed free space between camera and surface.
   */
  const double ray_start = std::max(0.0, surface_range - config_.truncation_distance);

  const double ray_end = surface_range + config_.truncation_distance;

  /*
   * Half-voxel sampling reduces the chance of skipping a voxel when a
   * ray crosses the grid diagonally.
   *
   * This is simple rather than optimal; proper voxel traversal can
   * replace this later.
   */
  const double step = config_.voxel_size * 0.5;

  for (double range = ray_start; range <= ray_end; range += step) {
    const Eigen::Vector3d position = camera_origin_world + ray_direction * range;

    /*
     * Positive before the measured surface, negative behind it.
     */
    const double sdf = surface_range - range;

    const double normalized_sdf =
      static_cast<float>(std::clamp(sdf / config_.truncation_distance, -1.0, 1.0));

    updateVoxel(position, static_cast<float>(normalized_sdf), 1.0F, tsdf_accessor, weight_accessor);
  }
}

void VdbVolume::updateVoxel(
  const Eigen::Vector3d & world_position, float signed_distance, float observation_weight,
  openvdb::FloatGrid::Accessor & tsdf_accessor, openvdb::FloatGrid::Accessor & weight_accessor)
{
  if (observation_weight <= 0.0F) {
    return;
  }

  const openvdb::Vec3d xyz{world_position.x(), world_position.y(), world_position.z()};

  const auto ijk = openvdb::Coord::round(tsdf_->worldToIndex(xyz));

  const float old_weight = weight_accessor.getValue(ijk);

  const float old_tsdf = tsdf_accessor.getValue(ijk);

  /*
   * Limit the amount of historical confidence accumulated in a voxel.
   *
   * Once saturated, new observations should still affect the TSDF, so
   * use the capped old weight when performing the average.
   */
  const float effective_old_weight = std::min(old_weight, config_.max_weight);

  const float effective_observation_weight = std::min(observation_weight, config_.max_weight);

  const float total_weight = effective_old_weight + effective_observation_weight;

  if (total_weight <= 0.0F) {
    return;
  }

  const float new_tsdf =
    (old_tsdf * effective_old_weight + signed_distance * effective_observation_weight) /
    total_weight;

  const float new_weight = std::min(total_weight, config_.max_weight);

  tsdf_accessor.setValue(ijk, new_tsdf);
  weight_accessor.setValue(ijk, new_weight);
}

}  // namespace world_builder
