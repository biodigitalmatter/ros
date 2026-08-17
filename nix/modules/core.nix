{
  self,
  ...
}:

{
  flake.modules.nixos.core =
    { ... }:
    {
      imports = with self.modules.nixos; [
        networking
        nix
        secrets
        ssh
        users
        self.modules.generic.data
      ];

      hardware.enableRedistributableFirmware = true;

      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh.enable = true;
      time.timeZone = "Europe/Stockholm";
    };
}
