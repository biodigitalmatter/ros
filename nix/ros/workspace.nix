{
  buildROSWorkspace,

  biodigitalmatter-ros,
  chess-vision,
  chess-vision-ros,
  elizabeth-descriptions,
  material-vision,

  # shellPackages
  basedpyright,
  colcon,
  nixd,
  python3,
  ros2-utils-tool,
  ruff,
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
