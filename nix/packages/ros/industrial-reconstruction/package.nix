{
  packageSources,
  lib,
  buildRosPackage,

  cv-bridge,
  geometry-msgs,
  industrial-reconstruction-msgs,
  launch,
  launch-ros,
  message-filters,
  python3Packages,
  rclpy,
  sensor-msgs,
  std-msgs,
  tf2-msgs,
  tf2-ros,
  visualization-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-industrial-reconstruction";
  version = "0.0.0";

  src = packageSources.industrial_reconstruction;

  buildType = "ament_python";
  sourceRoot = "source/industrial_reconstruction";

  propagatedBuildInputs = [
    cv-bridge
    geometry-msgs
    industrial-reconstruction-msgs
    launch
    launch-ros
    message-filters
    rclpy
    sensor-msgs
    std-msgs
    tf2-msgs
    tf2-ros
    visualization-msgs
  ]
  ++ (with python3Packages; [
    (open3d.override {
      withCuda = true;
    })
    pyquaternion
  ]);

  meta = {
    description = "A ROS2 reconstruction utility leveraging TSDF from Open3D";
    license = with lib.licenses; [ asl20 ];
  };
}
