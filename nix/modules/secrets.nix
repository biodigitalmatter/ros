{ inputs, ... }:
{
  flake.modules = {
    nixos.secrets =
      { ... }:
      {
        imports = [
          inputs.sops-nix.nixosModules.sops
        ];
        sops.defaultSopsFile = ./secrets.sops.yaml;
      };
  };
}
