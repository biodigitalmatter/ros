# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  buildRosPackage,
  ament-cmake,

  geometry-msgs,
  rclcpp,
  sensor-msgs,
  tf2-ros,
  tf2-eigen,
  openvdb,
  eigen,
  microsoft-gsl,
  tl-expected,

  # from openvdb
  boost,
  c-blosc,
  tbb,
  zlib,

  # test
  ament-cmake-clang-format,
  ament-cmake-gtest,
  ament-cmake-pytest,
}:
buildRosPackage {
  pname = "ros-jazzy-world-builder";
  version = "0.1.0";

  src = ../../src/world_builder;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  buildInputs = [
    boost
    c-blosc
    eigen
    microsoft-gsl
    openvdb.dev
    tbb.dev
    tl-expected
    zlib.dev
  ];

  propagatedBuildInputs = [
    geometry-msgs
    rclcpp
    sensor-msgs
    tf2-ros
    tf2-eigen
  ];

  passthru.workspacePackages = {
    inherit
      ament-cmake-clang-format
      ament-cmake-gtest
      ament-cmake-pytest
      ;
  };

  meta = {
    description = "Collect and combine depth maps to voxel models";
    license = with lib.licenses; [ asl20 ];
  };
}
