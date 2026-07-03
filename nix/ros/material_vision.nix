{
  lib,
  buildRosPackage,
  ament-cmake,

  depth-image-proc,
  launch-ros,
  pcl-ros,
  python3Packages,
  realsense2-camera,
  realsense2-description,
  sensor-msgs,
  tf2-ros,
}:
buildRosPackage {
  pname = "ros-jazzy-material-vision";
  version = "0.1.0";

  src = ../../src/material_vision;

  buildType = "ament_python";

  nativeBuildInputs = [ ament-cmake ];

  passthru.workspacePackages = {
    inherit
      depth-image-proc
      launch-ros
      pcl-ros
      realsense2-camera
      realsense2-description
      sensor-msgs
      tf2-ros
      ;
  };

  nativeCheckInputs = [
    python3Packages.pytest
  ];

  meta = {
    description = "Build a model of what you're building";
    license = with lib.licenses; [ asl20 ];
  };
}
