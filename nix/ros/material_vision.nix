{
  lib,
  buildRosPackage,
  ament-cmake,
  # industrial-reconstruction,
  tf2-ros,
  pcl-ros,
  sensor-msgs,
  realsense2-camera,
  realsense2-description,
}:
buildRosPackage {
  pname = "ros-jazzy-material-vision";
  version = "0.1.0";

  src = ../../material_vision;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  propagatedBuildInputs = [
    # depthai-ros
    # industrial-reconstruction
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
