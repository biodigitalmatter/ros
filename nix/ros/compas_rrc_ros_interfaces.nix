{
  lib,
  fetchFromGitHub,
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

  src = fetchFromGitHub {
    owner = "biodigitalmatter";
    repo = "compas_rrc_ros";
    rev = "f9e3cb5e2a2b100486f47f044c3702d77b9026a9"; # ros2
    hash = "sha256-P8qGiSqLvYzrIZO/SfAm+JuR/wPozmsm945P27TaTxI=";
  };
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
