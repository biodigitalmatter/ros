final: prev:
let
  inherit (final) callPackage;
in
{
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
  biodigitalmatter-ros = callPackage ./biodigitalmatter_ros.nix { };
  charuco-detector = callPackage ./charuco_detector/package.nix { };
  charuco-detector-interfaces = callPackage ./charuco_detector_interfaces.nix { };
  compas-rrc-driver = callPackage ./compas_rrc_driver.nix { };
  compas-rrc-ros-interfaces = callPackage ./compas_rrc_ros_interfaces.nix { };
}
