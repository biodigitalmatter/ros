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
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
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
