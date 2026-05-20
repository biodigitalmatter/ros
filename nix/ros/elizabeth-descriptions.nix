{
  lib,
  buildRosPackage,
  ament-cmake,
}:
buildRosPackage {
  pname = "ros-jazzy-elizabeth-descriptions";
  version = "0.1.0";

  src = ../../elizabeth_descriptions;

  buildType = "ament_cmake";

  nativeBuildInputs = [ ament-cmake ];

  propagatedBuildInputs = [ ];

  meta = {
    description = "elizabeth (IRB 4600 on caterpillar tracks) description";
    license = with lib.licenses; [ asl20 ];
  };
}
