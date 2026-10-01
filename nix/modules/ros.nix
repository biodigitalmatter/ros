{
  lib,
  ...
}:
{
  flake.modules = {
    generic.data =
      { ... }:
      {
        options.data.ros = {
          envVars = lib.mkOption {
            type = with lib.types; attrsOf str;
            description = "Environment variables to set for ROS processes";
          };
        };
      };
    nixos.ros =
      { config, ... }:
      let
        inherit (config.data.ros) environmentVariables;
      in
      {
        environment.variables = environmentVariables;

        networking.firewall =
          let
            domainId = lib.toInt environmentVariables.ROS_DOMAIN_ID;
            from = 7400 + 250 * domainId;
            to = from + 249;
            portRange = {
              inherit from to;
            };
          in
          {
            allowedTCPPortRanges = [ portRange ];
            allowedUDPPortRanges = [ portRange ];
          };

      };
  };
}
