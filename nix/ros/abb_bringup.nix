{
  lib,
  buildRosPackage,
  fetchFromGitHub,
  abb-irb1200-5-90-moveit-config,
  abb-irb1200-support,
  abb-resources,
  ament-cmake,
  ament-cmake-gtest,
  ament-lint-auto,
  ament-lint-cmake,
  controller-manager,
  joint-state-publisher,
  joint-trajectory-controller,
  launch,
  launch-ros,
  moveit-configs-utils,
  rclcpp,
  ros-testing,
  ros2-control,
  ros2-controllers,
  rviz2,
  trajectory-msgs,
  urdf,
  xacro,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-bringup";
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
  };

  sourceRoot = "source/abb_bringup";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  checkInputs = [
    abb-irb1200-5-90-moveit-config
    abb-irb1200-support
    abb-resources
    ament-cmake-gtest
    ament-lint-auto
    ament-lint-cmake
    rclcpp
    ros-testing
    trajectory-msgs
  ];
  propagatedBuildInputs = [
    controller-manager
    joint-state-publisher
    joint-trajectory-controller
    launch
    launch-ros
    moveit-configs-utils
    ros2-control
    ros2-controllers
    rviz2
    urdf
    xacro
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Launch file and run-time configurations, e.g. controllers.";
    license = with lib.licenses; [ asl20 ];
  };
}
