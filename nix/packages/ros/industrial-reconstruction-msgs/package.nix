{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  geometry-msgs,
  launch,
  launch-ros,
  rclpy,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
  tf2-ros,
}:
buildRosPackage {
  pname = "ros-jazzy-industrial-reconstruction-msgs";
  version = "0.0.0";

  src = packageSources.industrial_reconstruction;
  sourceRoot = "source/industrial_reconstruction_msgs";

  buildType = "ament_cmake";

  nativeBuildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  propagatedBuildInputs = [
    geometry-msgs
    launch
    launch-ros
    rclpy
    rosidl-default-runtime
    std-msgs
    tf2-ros
  ];

  meta = {
    description = "A collection of ROS interfaces for industrial_reconstruction";
    license = with lib.licenses; [ asl20 ];
  };
}
