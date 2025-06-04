{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  abb-irb1200-support,
  ament-cmake,
  joint-state-publisher,
  robot-state-publisher,
  rviz2,
  xacro,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-irb1200-5-90-moveit-config";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "7d0eb930dfbfc64bc620bbbd70dd31fdd512ee68";
    hash = "sha256-NMALtQTk3i3t4HWxUkm4COPl92BdSSA2yDOtAhNf78o=";
  };
  sourceRoot = "source/robot_specific_config/abb_irb1200_5_90_moveit_config";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  propagatedBuildInputs = [
    abb-irb1200-support
    joint-state-publisher
    robot-state-publisher
    rviz2
    xacro
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "MoveIt package for the ABB IRB 1200-5/0.9.";
    license = with lib.licenses; [ bsdOriginal ];
  };
}
