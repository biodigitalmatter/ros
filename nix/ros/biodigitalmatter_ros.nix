{
  lib,
  buildRosPackage,

  abb-rws-client,
  axis-camera,
  compas-rrc-driver,
  docker-compose,
  rosbridge-server,
}:
buildRosPackage {
  pname = "ros-jazzy-biodigitalmatter-ros";
  version = "0.1.0";

  src = ../../src/biodigitalmatter_ros;

  buildType = "ament_python";

  passthru.workspacePackages = {
    inherit
      abb-rws-client
      axis-camera
      compas-rrc-driver
      docker-compose
      rosbridge-server
      ;
  };

  meta = {
    description = "ROS setup for biodigital matter lab";
    license = with lib.licenses; [ mit ];
  };
}
