{
  lib,
  buildRosPackage,
  ament-cmake,

  ament-lint-auto,
  ament-lint-cmake,
  ament-lint-common,
  geometry-msgs,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision-ros-interfaces";
  version = "0.1.0";

  src = ../../../../src/chess_vision_ros_interfaces;

  buildType = "ament_cmake";

  nativeBuildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  checkInputs = [
    ament-lint-auto
    ament-lint-cmake
    ament-lint-common
  ];

  propagatedBuildInputs = [
    geometry-msgs
    rosidl-default-runtime
    std-msgs
  ];

  meta = {
    description = "Interfaces for chess_vision_ros";
    license = with lib.licenses; [ asl20 ];
  };
}
