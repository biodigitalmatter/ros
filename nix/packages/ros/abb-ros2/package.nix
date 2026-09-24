{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  ament-cmake,
  ament-lint-auto,
  ament-lint-common,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-ros2";
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
  };

  sourceRoot = "source/abb_ros2";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  checkInputs = [
    ament-lint-auto
    ament-lint-common
  ];

  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Meta package containing everything to run an ABB robot or simulation with ROS 2";
    license = with lib.licenses; [ asl20 ];
  };
}
