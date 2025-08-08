{
  lib,
  buildRosPackage,
  cv-bridge,
  opencv,
  python3Packages,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision";
  version = "0.0.0";

  src = ../../chess_vision;

  buildType = "ament_python";
  propagatedBuildInputs = [
    cv-bridge
    opencv
    python3Packages.numpy
    python3Packages.scipy
  ];

  meta = {
    description = "detect charco boards";
    license = with lib.licenses; [ mit ];
  };
}
