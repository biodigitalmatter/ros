{
  packageSources,
  lib,
  buildRosPackage,

  compas-rrc-ros-interfaces,
  python3Packages,
  rclpy,
}:
buildRosPackage {
  pname = "ros-jazzy-compas-rrc-driver";
  version = "1.1.3";

  src = packageSources.compas_rrc_ros;
  sourceRoot = "source/compas_rrc_driver";

  buildType = "ament_python";
  propagatedBuildInputs = [
    compas-rrc-ros-interfaces
    python3Packages.requests
    rclpy
  ];

  meta = {
    description = "COMPAS RRC: ROS Driver";
    license = with lib.licenses; [ mit ];
  };
}
