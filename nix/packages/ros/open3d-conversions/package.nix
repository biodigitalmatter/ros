{
  lib,
  buildRosPackage,
  fetchFromGitHub,

  ament-cmake,
  eigen,
  open3d,
  rclcpp,
  rcpputils,
  sensor-msgs,
}:

buildRosPackage rec {
  pname = "ros-jazzy-open3d-conversions";
  version = "0.1.2";

  src = fetchFromGitHub {
    owner = "ros-perception";
    repo = "perception_open3d";
    tag = version;
    sha256 = "sha256-BR9Roqcw1UD+E++hn/vhZKF/cqfvzYoYWcYG6vdZf0Q=";
  };

  buildType = "ament_cmake";

  nativeBuildInputs = [
    ament-cmake
  ];

  buildInputs = [
    eigen
    open3d
    rclcpp
    rcpputils
    sensor-msgs
  ];

  meta = {
    description = "The ros2_utils_tool package";
    license = lib.licenses.asl20;
  };
}
