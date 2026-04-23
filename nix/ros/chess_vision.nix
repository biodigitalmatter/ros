{
  lib,
  buildRosPackage,
  opencv,
  python3Packages,
}:
buildRosPackage {
  pname = "ros-jazzy-chess-vision";
  version = "0.1.0";

  src = ../../chess_vision;

  buildType = "ament_python";

  propagatedBuildInputs = [
    opencv
    python3Packages.numpy
    python3Packages.scipy
  ];

  nativeCheckInputs = [ python3Packages.pytest ];

  meta = {
    description = "detect charuco boards";
    license = with lib.licenses; [ asl20 ];
  };
}
