{
  lib,
  buildRosPackage,
  abb-bringup,
  abb-rws-client,
  axis-camera,
  compas-rrc-driver,
  cv-bridge,
  docker-compose,
  robot-calibration,
  rosbridge-server,
}:
buildRosPackage {
  pname = "ros-jazzy-biodigitalmatter-ros";
  version = "0.1.0";

  src = ../../biodigitalmatter_ros;

  buildType = "ament_python";
  propagatedBuildInputs = [
    abb-bringup
    abb-rws-client
    axis-camera
    compas-rrc-driver
    cv-bridge
    docker-compose
    robot-calibration
    rosbridge-server
  ];

  meta = {
    description = "ROS setup for biodigital matter lab";
    license = with lib.licenses; [ mit ];
  };
}
