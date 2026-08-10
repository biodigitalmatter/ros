{
  ...
}:

{
  flake.modules.nixos.core =
    { ... }:
    {
      hardware.enableRedistributableFirmware = true;

      i18n.defaultLocale = "en_US.UTF-8";

      services.openssh.enable = true;
      time.timeZone = "Europe/Stockholm";
    };
}
