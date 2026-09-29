{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-egm-msgs";
  version = "0-unstable-2022-08-15";

  src = packageSources.abb_ros2_msgs;
  sourceRoot = "source/abb_egm_msgs";

  buildType = "ament_cmake";

  nativeBuildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  propagatedBuildInputs = [
    rosidl-default-runtime
    std-msgs
  ];

  meta = {
    description = "Provides ROS message definitions, representing Externally Guided Motion (EGM) data from ABB robot controllers.";
    license = with lib.licenses; [ bsd3 ];
  };
}
