{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  ament-cmake,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-resources";
  version = "0-unstable-2025-07-14";

  src = fetchFromGitHub {
    owner = "PickNikRobotics";
    repo = "abb_ros2";
    rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
    hash = "sha256-kr9nyK57OaYjasZGzH+DHFinwqPavxtpnklJpvHjqSQ=";
  };

  sourceRoot = "source/abb_resources";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Shared configuration data for ABB manipulators.";
    license = with lib.licenses; [ asl20 ];
  };
}
