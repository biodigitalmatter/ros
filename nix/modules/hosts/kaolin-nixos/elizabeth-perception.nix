{
  lib,
  ...
}:

{
  flake.modules.nixos."hosts/kaolin-nixos" =
    { pkgs, ... }:
    {
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

            environment = {
              ROS_DOMAIN_ID = "55";
              ROS_LOG_DIR = "%t/elizabeth-perception/%i";

              RCUTILS_LOGGING_USE_STDOUT = "1";
              RCUTILS_COLORIZED_OUTPUT = "0";
            };

            bindsTo = [ "dev-elizabeth-realsense_%i.device" ];
            after = [ "dev-elizabeth-realsense_%i.device" ];

            serviceConfig = {
              DynamicUser = true;

              Restart = "on-failure";
              RestartSec = 3;

              RuntimeDirectory = "elizabeth-perception/%i";

              SupplementaryGroups = [ "video" ];

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
          ACTION=="add", SUBSYSTEM=="usb", \
            ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b5b", \
            TAG+="systemd", \
            ENV{SYSTEMD_ALIAS}="/dev/elizabeth/realsense_d405", \
            ENV{SYSTEMD_WANTS}+="elizabeth-perception-realsense@d405.service"

          ACTION=="add", SUBSYSTEM=="usb", \
            ATTRS{idVendor}=="8086", ATTRS{idProduct}=="0b3a", \
            TAG+="systemd", \
            ENV{SYSTEMD_ALIAS}="/dev/elizabeth/realsense_d435i", \
            ENV{SYSTEMD_WANTS}+="elizabeth-perception-realsense@d435i.service"
        '';
        packages = [ pkgs.librealsense ];
      };
    };
}
