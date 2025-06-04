{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  abb-rapid-msgs,
  ament-cmake,
  ament-lint-common,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-rapid-sm-addin-msgs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "gbartyzel";
    repo = "abb_ros2_msgs";
    rev = "071bb1fc2148a7cd850a1ff550c5987e67da6bdd";
    hash = "sha256-d6u9wAep9Rerz7sKvy4/x90acorF5mz9o8k6SRxdk9o=";
  };
  sourceRoot = "source/abb_rapid_sm_addin_msgs";

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  checkInputs = [ ament-lint-common ];
  propagatedBuildInputs = [
    abb-rapid-msgs
    rosidl-default-runtime
    std-msgs
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Provides ROS message and service definitions, representing interaction
    with ABB robot controllers using the RobotWare StateMachine Add-In.";
    license = with lib.licenses; [ bsd3 ];
  };
}
