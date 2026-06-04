{
  lib,
  buildRosPackage,
  ament-cmake,

  abb-irb4600-support,
  robot-state-publisher,
  xacro,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-descriptions";
  version = "0.1.0";

  src = ../../src/elizabeth_descriptions;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  passthru.workspacePackages = {
    inherit
      abb-irb4600-support
      robot-state-publisher
      xacro
      ;
  };

  meta = {
    description = "elizabeth (IRB 4600 on caterpillar tracks) description";
    license = with lib.licenses; [ asl20 ];
  };
}
