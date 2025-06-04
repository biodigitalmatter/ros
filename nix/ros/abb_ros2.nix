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
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "7d0eb930dfbfc64bc620bbbd70dd31fdd512ee68";
    hash = "sha256-NMALtQTk3i3t4HWxUkm4COPl92BdSSA2yDOtAhNf78o=";
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
