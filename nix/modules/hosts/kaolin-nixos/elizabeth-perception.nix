{
  lib,
  ...
}:

{
  flake.modules.nixos."hosts/kaolin-nixos" =
    { config, pkgs, ... }:
    {
      # TODO: Remove after debugging
      networking.firewall.enable = false;
      systemd.services = {
        "elizabeth-perception-realsense@" =
          let
            ros = pkgs.rosPackages.jazzy;
            perceptionEnv = ros.buildROSWorkspace {
              name = "elizabeth-perception-runtime";
              prebuiltPackages = {
                inherit (ros)
                  elizabeth-perception
                  ;
              };
            };
          in
          {
            description = "Elizabeth Perception ROS 2 launch, start attached realsense camera (%i)";

            environment = config.data.ros.environmentVariables // {
              ROS_LOG_DIR = "%t/elizabeth-perception/%i";

              RCUTILS_LOGGING_USE_STDOUT = "1";
              RCUTILS_COLORIZED_OUTPUT = "0";
            };

            wantedBy = [ "dev-elizabeth-realsense_%i.device" ];
            bindsTo = [ "dev-elizabeth-realsense_%i.device" ];
            after = [ "dev-elizabeth-realsense_%i.device" ];

            serviceConfig = {
              DynamicUser = true;

              Restart = "on-failure";
              RestartSec = 3;

              RuntimeDirectory = "elizabeth-perception/%i";

              SupplementaryGroups = [
                "plugdev"
                "video"
              ];

              ExecStart = "${lib.getExe' perceptionEnv "ros2"} launch elizabeth_perception rgbd_realsense.launch.yaml camera_model:=%i";
            };

            unitConfig = {
              StartLimitIntervalSec = 30;
              StartLimitBurst = 3;
            };
          };
      };
      services.udev = {
        extraRules = ''
          ACTION=="add", \
            SUBSYSTEM=="usb", \
            ENV{DEVTYPE}=="usb_device", \
            ATTR{idVendor}=="8086", \
            ATTR{idProduct}=="0b5b", \
            TAG+="systemd", \
            ENV{SYSTEMD_ALIAS}="/dev/elizabeth/realsense_d405"

          ACTION=="add", \
            SUBSYSTEM=="usb", \
            ENV{DEVTYPE}=="usb_device", \
            ATTR{idVendor}=="8086", \
            ATTR{idProduct}=="0b3a", \
            TAG+="systemd", \
            ENV{SYSTEMD_ALIAS}="/dev/elizabeth/realsense_d435i"
        '';
        packages = [ pkgs.librealsense ];
      };
      users.groups.plugdev = { }; # realsense udev rules uses plugdev
    };
}
