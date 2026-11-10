{
  lib,
  buildRosPackage,

  chess-vision,
  chess-vision-ros-interfaces,
  cv-bridge,
  geometry-msgs,
  launch-pytest,
  launch-ros,
  launch-testing,
  launch-testing-ros,
  opencv,
  python3Packages,
  rclpy,
  ros2bag,
  rosbag2-py,
  rosidl-runtime-py,
  sensor-msgs,
  tf2-msgs,
  tf2-ros,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision-ros";
  version = "0.1.0";

  src = ../../../../src/chess_vision_ros;

  buildType = "ament_python";
  propagatedBuildInputs = [
    chess-vision
    cv-bridge
    geometry-msgs
    launch-ros
    opencv
    python3Packages.click
    python3Packages.compas
    python3Packages.numpy
    rclpy
    ros2bag
    rosbag2-py
    rosidl-runtime-py
    sensor-msgs
    chess-vision-ros-interfaces
    tf2-msgs
    tf2-ros
  ];
  passthru.workspacePackages = {
    inherit
      launch-pytest
      launch-testing
      launch-testing-ros
      ;
  };
  nativeCheckInputs = [
    python3Packages.pytest
  ];
  meta = {
    description = "ROS wrapper for chess_vision";
    license = with lib.licenses; [ asl20 ];
  };
}
