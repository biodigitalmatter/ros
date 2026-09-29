{
  packageSources,
  lib,
  buildRosPackage,
  ament-cmake,

  abb-resources,
}:
buildRosPackage {
  pname = "ros-jazzy-abb-irb4600-support";
  version = "0-unstable-2025-07-14";

  src = packageSources.abb_ros2;
  sourceRoot = "source/robot_specific_config/abb_irb4600_support";

  buildType = "ament_cmake";
  buildInputs = [ ament-cmake ];
  nativeBuildInputs = [ ament-cmake ];

  passthru.workspacePackages = {
    inherit
      abb-resources
      ;
  };

  meta = {
    description = "
      ROS-Industrial support for the ABB IRB 4600 (and variants).";
    license = with lib.licenses; [ asl20 ];
  };
}
