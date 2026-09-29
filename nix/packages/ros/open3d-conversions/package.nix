{
  packageSources,
  lib,
  buildRosPackage,

  ament-cmake,
  eigen,
  open3d,
  rclcpp,
  rcpputils,
  sensor-msgs,
}:

buildRosPackage {
  pname = "ros-jazzy-open3d-conversions";
  version = "0.1.2";

  src = packageSources.perception_open3d;

  buildType = "ament_cmake";

  nativeBuildInputs = [
    ament-cmake
  ];

  buildInputs = [
    eigen
    open3d
    rclcpp
    rcpputils
    sensor-msgs
  ];

  meta = {
    license = lib.licenses.asl20;
  };
}
