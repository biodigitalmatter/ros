{
  lib,
  self,
  ...
}:
let
  sopsKey = "network/envfile";
in
{
  flake.modules.nixos = {
    networking = {
      sops.secrets.${sopsKey} = { };

      networking = {
        useDHCP = true;
      };
    };

    rpi4 = {
      imports = [
        self.modules.nixos."networking/wpa_supplicant"
      ];

      networking = {
        usePredictableInterfaceNames = false;
      };
    };

    "networking/wpa_supplicant" =
      { config, ... }:
      {
        networking = {
          networkmanager.enable = lib.mkForce false;
          wireless = {
            enable = true;
            secretsFile = config.sops.secrets.${sopsKey}.path;
            networks = {
              GL-X3000-59f.pskRaw = "ext:GL_X3000_59f_psk";
              Terra.pskRaw = "ext:Terra_psk";
              # no eduroam defined in this format please
            };
          };
        };
      };
  };
}
