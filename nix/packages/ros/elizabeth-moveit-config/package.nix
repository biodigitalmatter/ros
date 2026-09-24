{
  lib,
  buildRosPackage,
  ament-cmake,

  controller-manager,
  joint-state-publisher,
  joint-state-publisher-gui,
  robot-state-publisher,
  topic-tools,
  xacro,
}:

buildRosPackage {
  pname = "ros-jazzy-elizabeth-moveit-config";
  version = "0.1.0";

  src = ../../../../src/elizabeth_moveit_config;

  buildType = "ament_cmake";
  nativebuildinputs = [ ament-cmake ];
  passthru.workspacePackages = {
    inherit
      controller-manager
      joint-state-publisher
      joint-state-publisher-gui
      robot-state-publisher
      topic-tools
      xacro
      ;
  };
  meta = {
    description = "MoveIt2 config for the Elizabeth robot platform";
    license = with lib.licenses; [ asl20 ];
  };
  buildInputs = [ ament-cmake ];
}
