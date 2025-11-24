{
  lib,
  buildRosPackage,
  tf2,
  tf2-ros,
  geometry-msgs,
  nav-msgs,
  ament-lint-auto,
  ament-lint-common,
  ament-xmllint,
}:
buildRosPackage {
  pname = "ros-jazzy-tf2-2-odom";
  version = "0.1.0";

  src = ../../tf2_2_odom;

  buildType = "ament_cmake";
  buildInputs = [
    tf2
    tf2-ros
    nav-msgs
    geometry-msgs
  ];

  checkDepends = [
    ament-lint-auto
    ament-lint-common
    ament-xmllint
  ];

  doCheck = true;

  meta = {
    description = "When you want odom but only got TF2";
    license = with lib.licenses; [ asl20 ];
  };
}
