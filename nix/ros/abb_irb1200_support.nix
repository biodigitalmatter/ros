{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  ament-cmake,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-irb1200-support";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "7d0eb930dfbfc64bc620bbbd70dd31fdd512ee68";
    hash = "sha256-NMALtQTk3i3t4HWxUkm4COPl92BdSSA2yDOtAhNf78o=";
  };
  sourceRoot = "source/robot_specific_config/abb_irb1200_support";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "ROS-Industrial support for the ABB IRB 1200 (and variants).";
    license = with lib.licenses; [ asl20 ];
  };
}
