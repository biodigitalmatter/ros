{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  ament-cmake,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-irb1200-support";
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
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
