{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  ament-lint-auto,
  ament-lint-common,
  rosidl-default-generators,
  rosidl-default-runtime,
}:
buildRosPackage {
  pname = "ros-jazzy-compas-rrc-ros-interfaces";
  version = "1.1.3";

  src = packageSources.compas_rrc_ros;
  sourceRoot = "source/compas_rrc_ros_interfaces";

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  checkInputs = [
    ament-lint-auto
    ament-lint-common
  ];
  propagatedBuildInputs = [ rosidl-default-runtime ];
  nativeBuildInputs = [
    ament-cmake
    rosidl-default-generators
  ];

  meta = {
    description = "COMPAS RRC: ROS interface";
    license = with lib.licenses; [ mit ];
  };
}
