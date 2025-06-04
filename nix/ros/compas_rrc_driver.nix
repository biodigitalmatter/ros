{
  lib,
  fetchFromGitHub,
  buildRosPackage,
  compas-rrc-ros-interfaces,
  python3Packages,
  rclpy,
}:
buildRosPackage {
  pname = "ros-jazzy-compas-rrc-driver";
  version = "1.1.3";

  src = fetchFromGitHub {
    owner = "biodigitalmatter";
    repo = "compas_rrc_ros";
    rev = "f9e3cb5e2a2b100486f47f044c3702d77b9026a9"; # ros 2
    hash = "sha256-P8qGiSqLvYzrIZO/SfAm+JuR/wPozmsm945P27TaTxI=";
  };
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
