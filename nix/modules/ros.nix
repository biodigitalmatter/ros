{
  ...
}:
let
  ROS_DOMAIN_ID = 55;
  udpPortRange =
    let
      from = 7400 + 250 * ROS_DOMAIN_ID;
      to = from + 200;
    in
    {
      inherit from to;
    };
in
{
  flake.modules.nixos.ros =
    { ... }:
    {
      environment.variables = { inherit ROS_DOMAIN_ID; };
      networking.firewall.allowedUDPPortRanges = [
        udpPortRange
      ];
    };
}
