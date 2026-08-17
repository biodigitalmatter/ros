{
  ...
}:
{
  flake.modules.nixos.ssh =
    { config, ... }:
    let
      inherit (config.data) publicSshKeys;
    in
    {
      services.openssh = {
        enable = true;
        settings = {
          PasswordAuthentication = true;
        };
      };

      users.users = {
        root.openssh.authorizedKeys.keys = publicSshKeys;
        tetov.openssh.authorizedKeys.keys = publicSshKeys;
      };
    };
}
