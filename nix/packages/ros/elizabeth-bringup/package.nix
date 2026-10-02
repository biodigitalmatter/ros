{
  lib,
  buildRosPackage,

  abb-rws-client,
  axis-camera,
  compas-rrc-driver,
  docker-compose,
  elizabeth-description,
  elizabeth-perception,
  rosbridge-server,
  rosbag2-transport,
  tf2-ros,
  python3Packages,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-bringup";
  version = "0.1.0";

  src = ../../../../src/elizabeth_bringup;

  buildType = "ament_python";
  passthru.workspacePackages = {
    inherit
      abb-rws-client
      axis-camera
      compas-rrc-driver
      docker-compose
      elizabeth-description
      elizabeth-perception
      rosbridge-server
      rosbag2-transport
      tf2-ros
      ;
  };
  nativeCheckInputs = [
    python3Packages.pytest
  ];
  meta = {
    description = "ROS bringup for Elizabeth";
    license = with lib.licenses; [ mit ];
  };
}
