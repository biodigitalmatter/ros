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

        networking.firewall.allowedUDPPortRanges = [
          (
            let
              domainId = lib.toInt environmentVariables.ROS_DOMAIN_ID;
              from = 7400 + 250 * domainId;
              to = from + 200;
            in
            {
              inherit from to;
            }
          )
        ];

      };
  };
}
