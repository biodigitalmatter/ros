#pragma once

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
}  // namespace world_builder
