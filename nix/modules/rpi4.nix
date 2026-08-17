{
  inputs,
  lib,
  self,
  ...
}:

{
  # mainly based on https://fzakaria.com/2024/08/13/nixos-raspberry-pi-me
  # and https://wiki.nixos.org/wiki/NixOS_on_ARM/Raspberry_Pi
  flake.modules.nixos.rpi4 =
    {
      modulesPath,
      pkgs,
      ...
    }:
    {
      imports = [
        "${modulesPath}/installer/sd-card/sd-image-aarch64.nix"
        inputs.nixos-hardware.nixosModules.raspberry-pi-4
      ]
      ++ (with self.modules; [
        nixos."networking/wifiCredentials"
        nixos."networking/wpa_supplicant"
      ]);

      boot.supportedFilesystems.zfs = lib.mkForce false;

      fileSystems = {
        "/" = {
          device = "/dev/disk/by-label/NIXOS_SD";
          fsType = "ext4";
          options = [ "noatime" ];
        };
      };

      hardware.raspberry-pi.firmware.uboot = {
        enable = true;
        # TODO: remove when ubootRaspberryPiAarch64 shows up in pkgs
        # missing because old nixpkgs?
        package = pkgs.ubootRaspberryPi4_64bit;
      };

      nixpkgs = {
        overlays = [
          # Workaround: https://github.com/NixOS/nixpkgs/issues/154163
          # modprobe: FATAL: Module sun4i-drm not found in directory
          (_final: super: {
            makeModulesClosure = x: super.makeModulesClosure (x // { allowMissing = true; });
          })
        ];
      };

      networking = {
        usePredictableInterfaceNames = false;
      };

      sdImage.compressImage = false;

      security.sudo = {
        enable = true;
        wheelNeedsPassword = false;
      };

    };
}
