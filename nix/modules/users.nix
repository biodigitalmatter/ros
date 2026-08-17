{ ... }:
{
  flake.modules.nixos.users =
    { ... }:
    {
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
