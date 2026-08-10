{
  inputs,
  self,
  withSystem,
  ...
}:
{
  flake.nixosConfigurations =
    let
      mkHost =
        {
          hostName,
          system ? "x86_64-linux",
          extraModules ? [ ],
        }:
        withSystem system (
          { pkgs, ... }:
          inputs.nixpkgs.lib.nixosSystem {
            inherit system;
            modules = [
              {
                networking = { inherit hostName; };
                nixpkgs = { inherit pkgs; }; # from flake.nix
              }
              self.modules.nixos.core
              self.modules.nixos."hosts/${hostName}"
            ]
            ++ extraModules;
          }
        );
    in
    {
      kaolin-nixos = mkHost {
        hostName = "kaolin-nixos";
        system = "aarch64-linux";
        extraModules = [ self.modules.nixos.rpi4 ];
      };
    };

}
