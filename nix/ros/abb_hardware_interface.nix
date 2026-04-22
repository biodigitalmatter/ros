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
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
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
