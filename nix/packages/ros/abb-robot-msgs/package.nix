{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  ament-lint-auto,
  ament-lint-cmake,
  ament-lint-common,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-robot-msgs";
  version = "0-unstable-2022-08-15";

  src = packageSources.abb_ros2_msgs;
  sourceRoot = "source/abb_robot_msgs";

  buildType = "ament_cmake";
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
    rosidl-default-runtime
    std-msgs
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Provides ROS message and service definitions, representing basic interaction with ABB robot controllers.";
    license = with lib.licenses; [ bsd3 ];
  };
}
