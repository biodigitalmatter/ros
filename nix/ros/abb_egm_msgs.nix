{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  ament-cmake,
  rosidl-default-generators,
  rosidl-default-runtime,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-egm-msgs";
  version = "1.0.0";

  src = fetchFromGitHub {
    owner = "gbartyzel";
    repo = "abb_ros2_msgs";
    rev = "071bb1fc2148a7cd850a1ff550c5987e67da6bdd";
    hash = "sha256-d6u9wAep9Rerz7sKvy4/x90acorF5mz9o8k6SRxdk9o=";
  };
  sourceRoot = "source/abb_egm_msgs";

  buildType = "ament_cmake";
  nativeBuildInputs = [
    ament-cmake
    rosidl-default-generators
  ];
  propagatedBuildInputs = [
    rosidl-default-runtime
    std-msgs
  ];
  meta = {
    description = "Provides ROS message definitions, representing Externally Guided Motion (EGM) data from ABB robot controllers.";
    license = with lib.licenses; [ bsd3 ];
  };
}
