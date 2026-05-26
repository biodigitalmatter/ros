# toplevel packages
pkgs:
# ros scope
final: prev:
let
  inherit (final) callPackage;
  inherit (pkgs) fetchpatch2;
in
{
  # own
  biodigitalmatter-ros = callPackage ./biodigitalmatter_ros.nix { };
  chess-vision = callPackage ./chess_vision.nix { };
  chess-vision-ros = callPackage ./chess_vision_ros.nix { };
  elizabeth-descriptions = callPackage ./elizabeth-descriptions.nix { };
  material-vision = callPackage ./material_vision.nix { };

  # patched
  launch-pytest = prev.launch-pytest.overrideAttrs (
    _finalAttrs: previousAttrs: {
      patches = (previousAttrs.patches or [ ]) ++ [
        (fetchpatch2 {
          relative = "launch_pytest";
          url = "https://github.com/ros2/launch/pull/967.patch";
          hash = "sha256-x1NJ10I/mzU88hs+xnkI0sA/bv1PCjo9XLq4pC9CYeg=";
        })
      ];
    }
  );

  # deps
  abb-bringup = callPackage ./abb_bringup.nix { };
  abb-egm-msgs = callPackage ./abb_egm_msgs.nix { };
  abb-egm-rws-managers = callPackage ./abb_egm_rws_managers.nix { };
  abb-hardware-interface = callPackage ./abb_hardware_interface.nix { };
  # abb-irb1200 required for abb-bringup
  abb-irb1200-5-90-moveit-config = callPackage ./abb_irb1200_5_90_moveit_config.nix { };
  abb-irb1200-support = callPackage ./abb_irb1200_support.nix { };
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
