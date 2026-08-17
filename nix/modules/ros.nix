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
      {
        data.ros.envVars = {
          ROS_DOMAIN_ID = "55";
          RMW_IMPLEMENTATION = "rmw_fastrtps_cpp";
          FASTDDS_BUILTIN_TRANSPORTS = "LARGE_DATA";
        };

        environment.variables = config.data.ros.envVars;

        networking.firewall.allowedUDPPortRanges = [
          (
            let
              domainId = lib.toInt config.data.ros.envVars.ROS_DOMAIN_ID;
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
