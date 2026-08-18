# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

{
  buildROSWorkspace,

  biodigitalmatter-ros,
  chess-vision,
  chess-vision-ros,
  elizabeth-descriptions,
  elizabeth-perception,
  elizabeth-perception-filters,
  material-vision,
  world-builder,

  # shellPackages
  basedpyright,
  colcon,
  demo-nodes-cpp,
  lemminx,
  nixd,
  python3,
  ros2-utils-tool,
  rqt,
  rqt-action,
  rqt-bag,
  rqt-bag-plugins,
  rqt-graph,
  rqt-image-view,
  rqt-reconfigure,
  rqt-service-caller,
  rqt-tf-tree,
  rqt-topic,
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
      elizabeth-perception-filters
      material-vision
      world-builder
      ;
  };
  prebuiltPackages = { };

  prebuiltShellPackages = {
    inherit
      basedpyright
      colcon
      demo-nodes-cpp
      lemminx
      nixd
      ros2-utils-tool
      rqt
      rqt-action
      rqt-bag
      rqt-bag-plugins
      rqt-graph
      rqt-image-view
      rqt-reconfigure
      rqt-service-caller
      rqt-tf-tree
      rqt-topic
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
