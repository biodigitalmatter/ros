{
  lib,
  buildRosPackage,
  ament-cmake,

  abb-irb4600-support,
  joint-state-publisher,
  robot-state-publisher,
  tf2-ros,
  xacro,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-description";
  version = "0.1.0";

  src = ../../../../src/elizabeth_description;

  buildType = "ament_cmake";
  nativeBuildInputs = [ ament-cmake ];
  passthru.workspacePackages = {
    inherit
      abb-irb4600-support
      joint-state-publisher
      robot-state-publisher
      tf2-ros
      xacro
      ;
  };
  meta = {
    description = "elizabeth (IRB 4600 on caterpillar tracks) description";
    license = with lib.licenses; [ asl20 ];
  };
}
