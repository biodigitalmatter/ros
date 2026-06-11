{
  lib,
  buildRosPackage,

  chess-vision,
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
  sensor-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision-ros";
  version = "0.1.0";

  src = ../../src/chess_vision_ros;

  buildType = "ament_python";

  propagatedBuildInputs = [
    chess-vision
    cv-bridge
    geometry-msgs
    opencv
    python3Packages.compas
    python3Packages.numpy
    rclpy
    sensor-msgs
  ];

  passthru.workspacePackages = {
    inherit
      launch-pytest
      launch-ros

      launch-testing
      launch-testing-ros
      ros2bag
      ;
  };

  meta = {
    description = "ROS wrapper for chess_vision";
    license = with lib.licenses; [ asl20 ];
  };
}
