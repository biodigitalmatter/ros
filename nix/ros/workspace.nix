{
  buildROSWorkspace,

  biodigitalmatter-ros,
  chess-vision,
  chess-vision-ros,
  elizabeth-descriptions,
  elizabeth-perception,
  material-vision,

  # shellPackages
  basedpyright,
  colcon,
  nixd,
  python3,
  ros2-utils-tool,
  ruff,
  rviz2,
  ty,
}:
buildROSWorkspace {
  name = "biodigitalmatter_ros jazzy workspace";
  devPackages = {
    inherit
      biodigitalmatter-ros
      chess-vision
      chess-vision-ros
      elizabeth-descriptions
      elizabeth-perception
      material-vision
      ;
  };
  prebuiltPackages = { };

  prebuiltShellPackages = {
    inherit
      basedpyright
      colcon
      nixd
      ros2-utils-tool
      ruff
      rviz2
      ty
      ;
    python3 = python3.withPackages (
      ps: with ps; [
        colcon-argcomplete
        rosbags
      ]
    );
  };
}
