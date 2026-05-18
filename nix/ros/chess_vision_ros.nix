{
  lib,
  buildRosPackage,
  chess-vision,
  cv-bridge,
  geometry-msgs,
  launch-pytest,
  opencv,
  python3Packages,
  rclpy,
  sensor-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision-ros";
  version = "0.1.0";

  src = ../../chess_vision_ros;

  buildType = "ament_python";
  propagatedBuildInputs = [
    chess-vision
    cv-bridge
    geometry-msgs
    launch-pytest
    opencv
    python3Packages.compas
    python3Packages.numpy
    rclpy
    sensor-msgs
  ];

  meta = {
    description = "ROS wrapper for chess_vision";
    license = with lib.licenses; [ asl20 ];
  };
}
