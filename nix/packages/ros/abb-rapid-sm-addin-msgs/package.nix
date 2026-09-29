{
  packageSources,
  lib,
  buildRosPackage,

  abb-rapid-msgs,
  ament-cmake,
  ament-lint-common,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-rapid-sm-addin-msgs";
  version = "0-unstable-2022-08-15";

  src = packageSources.abb_ros2_msgs;
  sourceRoot = "source/abb_rapid_sm_addin_msgs";

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  checkInputs = [ ament-lint-common ];
  propagatedBuildInputs = [
    abb-rapid-msgs
    rosidl-default-runtime
    std-msgs
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Provides ROS message and service definitions, representing interaction
    with ABB robot controllers using the RobotWare StateMachine Add-In.";
    license = with lib.licenses; [ bsd3 ];
  };
}
