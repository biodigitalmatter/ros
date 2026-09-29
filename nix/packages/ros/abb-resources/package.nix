{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-resources";
  version = "0-unstable-2025-07-14";

  src = packageSources.abb_ros2;

  sourceRoot = "source/abb_resources";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Shared configuration data for ABB manipulators.";
    license = with lib.licenses; [ asl20 ];
  };
}
