{
  lib,
  buildRosPackage,
  ament-cmake,

  depth-image-proc,
  # depthai
  realsense2-camera,
  realsense2-description,
  xacro,
  robot-state-publisher,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-perception";
  version = "0.1.0";

  src = ../../src/elizabeth_perception;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  passthru.workspacePackages = {
    inherit
      depth-image-proc
      # depthai
      realsense2-camera
      realsense2-description
      robot-state-publisher
      xacro
      ;
  };

  meta = {
    description = "setup for cameras on elizabeth (IRB 4600 on caterpillar tracks)";
    license = with lib.licenses; [ asl20 ];
  };
}
