# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

# toplevel packages
toplevelPackages:
# ros scope
final: _prev:
let
  inherit (final) callPackage;
in
{
  liblzf = toplevelPackages.liblzf.overrideAttrs (old: {
    postFixup = (old.postFixup or "") + ''
      mkdir -p $dev/include/liblzf $dev/lib/cmake/liblzf
      ln -s ../lzf.h $dev/include/liblzf/lzf.h
      ln -s ../lzfP.h $dev/include/liblzf/lzfP.h
      cat > $dev/lib/cmake/liblzf/liblzf-config.cmake <<EOF
      if(NOT TARGET liblzf::liblzf)
        add_library(liblzf::liblzf SHARED IMPORTED)
        set_target_properties(liblzf::liblzf PROPERTIES
          IMPORTED_LOCATION "${toplevelPackages.liblzf}/lib/liblzf.so.1.0.0"
          INTERFACE_INCLUDE_DIRECTORIES "${toplevelPackages.liblzf.dev}/include"
        )
      endif()
      set(liblzf_FOUND TRUE)
      EOF
    '';
  });

  # own
  open3d = callPackage ../open3d/package.nix { };
  workspace = callPackage ./workspace.nix { };
  biodigitalmatter-ros = callPackage ./biodigitalmatter_ros.nix { };
  chess-vision = callPackage ./chess_vision.nix { };
  chess-vision-ros = callPackage ./chess_vision_ros.nix { };
  elizabeth-descriptions = callPackage ./elizabeth_descriptions.nix { };
  elizabeth-perception = callPackage ./elizabeth_perception.nix { };
  elizabeth-perception-filters = callPackage ./elizabeth_perception_filters.nix { };
  material-vision = callPackage ./material_vision.nix { };
  world-builder = callPackage ./world_builder.nix { };

  # name collision
  tl-expected = toplevelPackages.tl-expected;

  # deps
  abb-egm-msgs = callPackage ./abb_egm_msgs.nix { };
  abb-egm-rws-managers = callPackage ./abb_egm_rws_managers.nix { };
  abb-hardware-interface = callPackage ./abb_hardware_interface.nix { };
  abb-irb4600-support = callPackage ./abb_irb4600_support.nix { };
  abb-rapid-msgs = callPackage ./abb_rapid_msgs.nix { };
  abb-rapid-sm-addin-msgs = callPackage ./abb_rapid_sm_addin_msgs.nix { };
  abb-resources = callPackage ./abb_resources.nix { };
  abb-robot-msgs = callPackage ./abb_robot_msgs.nix { };
  # abb-ros2 = callPackage ./abb_ros2.nix { }; unused, empty metapackage
  abb-rws-client = callPackage ./abb_rws_client.nix { };
  compas-rrc-driver = callPackage ./compas_rrc_driver.nix { };
  compas-rrc-ros-interfaces = callPackage ./compas_rrc_ros_interfaces.nix { };
  ros2-utils-tool = callPackage ./ros2-utils-tool.nix { };
}
