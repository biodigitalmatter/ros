{ inputs, ... }:
{
  flake.modules = {
    nixos.core =
      { ... }:
      {
        imports = [
          inputs.sops-nix.nixosModules.sops
        ];
        sops.defaultSopsFile = ./secrets.sops.yaml;
      };
  };
}
