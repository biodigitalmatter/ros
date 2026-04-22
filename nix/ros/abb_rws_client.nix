{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  abb-egm-msgs,
  abb-egm-rws-managers,
  abb-hardware-interface,
  abb-rapid-msgs,
  abb-rapid-sm-addin-msgs,
  abb-robot-msgs,
  ament-cmake,
  ament-cmake-gtest,
  ament-lint-auto,
  ament-lint-common,
  rclcpp,
  sensor-msgs,
  rosidl-default-generators,
  rosidl-default-runtime,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-rws-client";
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
  };

  sourceRoot = "source/abb_rws_client";

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  checkInputs = [
    ament-cmake-gtest
    ament-lint-auto
    ament-lint-common
  ];
  propagatedBuildInputs = [
    abb-egm-msgs
    abb-egm-rws-managers
    abb-hardware-interface
    abb-rapid-msgs
    abb-rapid-sm-addin-msgs
    abb-robot-msgs
    rclcpp
    sensor-msgs
    rosidl-default-runtime
  ];

  meta = {
    description = "TODO: Package description";
    license = with lib.licenses; [ asl20 ];
  };
}
