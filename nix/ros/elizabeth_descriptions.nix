{
  lib,
  buildRosPackage,
  ament-cmake,

  xacro,
  robot-state-publisher,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-descriptions";
  version = "0.1.0";

  src = ../../src/elizabeth_descriptions;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  passthru.workspacePackages = {
    inherit
      robot-state-publisher
      xacro
      ;
  };

  meta = {
    description = "elizabeth (IRB 4600 on caterpillar tracks) description";
    license = with lib.licenses; [ asl20 ];
  };
}
