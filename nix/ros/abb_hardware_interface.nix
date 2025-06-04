{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  abb-egm-rws-managers,
  ament-cmake,
  ament-cmake-gtest,
  ament-lint-auto,
  ament-lint-cmake,
  hardware-interface,
  pluginlib,
  rclcpp,
  rclcpp-lifecycle,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-hardware-interface";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "7d0eb930dfbfc64bc620bbbd70dd31fdd512ee68";
    hash = "sha256-NMALtQTk3i3t4HWxUkm4COPl92BdSSA2yDOtAhNf78o=";
  };
  sourceRoot = "source/abb_hardware_interface";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  checkInputs = [
    ament-cmake-gtest
    ament-lint-auto
    ament-lint-cmake
  ];
  propagatedBuildInputs = [
    abb-egm-rws-managers
    hardware-interface
    pluginlib
    rclcpp
    rclcpp-lifecycle
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "ABB EGM driver for ros2 control";
    license = with lib.licenses; [
      asl20
      bsd3
    ];
  };
}
