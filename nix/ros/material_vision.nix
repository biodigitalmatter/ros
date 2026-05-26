{
  lib,
  buildRosPackage,
  ament-cmake,
  launch-ros,
  pcl-ros,
  realsense2-camera,
  realsense2-description,
  sensor-msgs,
  tf2-ros,
}:
buildRosPackage {
  pname = "ros-jazzy-material-vision";
  version = "0.1.0";

  src = ../../src/material_vision;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  propagatedBuildInputs = [
    launch-ros
    pcl-ros
    realsense2-camera
    realsense2-description
    sensor-msgs
    tf2-ros
  ];

  meta = {
    description = "Build a model of what you're building";
    license = with lib.licenses; [ asl20 ];
  };
}
