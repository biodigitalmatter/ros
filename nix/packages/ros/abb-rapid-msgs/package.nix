{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  rosidl-default-generators,
  rosidl-default-runtime,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-rapid-msgs";
  version = "0-unstable-2022-08-15";

  src = packageSources.abb_ros2_msgs;
  sourceRoot = "source/abb_rapid_msgs";

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  propagatedBuildInputs = [ rosidl-default-runtime ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Provides ROS message definitions, representing RAPID data from ABB robot controllers.";
    license = with lib.licenses; [ bsd3 ];
  };
}
