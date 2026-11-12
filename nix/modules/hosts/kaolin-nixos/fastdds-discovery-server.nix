# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

{
  lib,
  ...
}:

{
  flake.modules.nixos."hosts/kaolin-nixos" =
    { pkgs, ... }:
    let
      address = "192.168.8.5";
      port = 11811;
      server = "${address}:${toString port}";
      fastddsDiscoveryServer = lib.getExe' pkgs.rosPackages.jazzy.fastrtps "fast-discovery-server";
    in
    {
      data.ros.environmentVariables = {
        ROS_AUTOMATIC_DISCOVERY_RANGE = "SYSTEM_DEFAULT";
        ROS_DISCOVERY_SERVER = server;
      };

      environment.variables.ROS_SUPER_CLIENT = "TRUE";

      networking.firewall.allowedUDPPorts = [ port ];

      systemd.services = {
        fastdds-discovery-server = {
          description = "Fast DDS discovery server";
          wantedBy = [ "multi-user.target" ];
          wants = [ "network-online.target" ];
          after = [ "network-online.target" ];

          serviceConfig = {
            DynamicUser = true;
            ExecStart = "${fastddsDiscoveryServer} -i 0 -l ${address} -p ${toString port}";
            Restart = "on-failure";
            RestartSec = 3;
          };
        };

        "elizabeth-perception-realsense@" = {
          wants = [ "fastdds-discovery-server.service" ];
          after = [ "fastdds-discovery-server.service" ];
        };
      };
    };
}
