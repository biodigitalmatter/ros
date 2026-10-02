# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

{
  buildROSWorkspace,

  elizabeth-bringup,
  chess-vision,
  chess-vision-ros,
  chess-vision-ros-interfaces,
  elizabeth-description,
  elizabeth-moveit-config,
  elizabeth-perception,
  elizabeth-perception-filters,
  material-vision,
  world-builder,

  # shellPackages
  colcon,
  demo-nodes-cpp,
  joint-trajectory-controller,
  lemminx,
  moveit-setup-assistant,
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
}:
buildROSWorkspace {
  name = "elizabeth jazzy workspace";
  devPackages = {
    inherit
      elizabeth-bringup
      chess-vision
      chess-vision-ros
      chess-vision-ros-interfaces
      elizabeth-description
      elizabeth-moveit-config
      elizabeth-perception
      elizabeth-perception-filters
      material-vision
      world-builder
      ;
  };
  prebuiltPackages = { };

  prebuiltShellPackages = {
    inherit
      colcon
      demo-nodes-cpp
      joint-trajectory-controller
      lemminx
      moveit-setup-assistant
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
      ;
    python3 = python3.withPackages (
      ps: with ps; [
        colcon-argcomplete
        rosbags
      ]
    );
  };
}
