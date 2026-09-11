# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0
{
  lib,
  buildRosPackage,
  ament-cmake,

  eigen,
  geometry-msgs,
  image-geometry,
  microsoft-gsl,
  openvdb,
  rclcpp,
  sensor-msgs,
  tf2-eigen,
  tf2-ros,
  tl-expected-nixpkgs,

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
    tl-expected-nixpkgs
    zlib.dev
    image-geometry
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
