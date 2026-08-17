{ ... }:
{
  flake.modules.nixos.users =
    { ... }:
    {
      nix.settings.trusted-users = [
        "root"
        "@wheel"
      ];
      users = {
        mutableUsers = false;
        users.tetov = {
          isNormalUser = true;
          extraGroups = [
            "networkmanager"
            "plugdev"
            "video"
            "wheel"
            "wireshark"
          ];
        };

      };
    };
}
