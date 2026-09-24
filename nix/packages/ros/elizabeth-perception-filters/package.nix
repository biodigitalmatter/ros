{
  lib,
  buildRosPackage,

  launch-pytest,
  python3Packages,
  rclpy,
  sensor-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-perception_filters";
  version = "0.1.0";

  src = ../../src/elizabeth_perception_filters;

  buildType = "ament_python";

  propagatedBuildInputs = [
    python3Packages.numpy
    python3Packages.pytest
    rclpy
    sensor-msgs
  ];

  passthru.workspacePackages = {
    inherit launch-pytest;
  };

  nativeCheckInputs = [ python3Packages.pytest ];

  meta = {
    description = "perception filters";
    license = with lib.licenses; [ asl20 ];
  };
}
