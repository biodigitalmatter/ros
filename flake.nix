{
  description = "Shell env for biodigitalmatter_ros";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    flake-parts.url = "github:hercules-ci/flake-parts";
  };

  outputs = inputs @ {flake-parts, ...}:
    flake-parts.lib.mkFlake {inherit inputs;} {
      imports = [];
      systems = ["x86_64-linux" "aarch64-linux"];
      perSystem = {
        config,
        self',
        inputs',
        pkgs,
        system,
        ...
      }: {
        devShells.default = pkgs.mkShell {
          buildInputs = with pkgs; [
            pre-commit
          ];
          shellHook = ''
            ${pkgs.pre-commit}/bin/pre-commit install
          '';
        };
        formatter = pkgs.alejandra;
      };
      flake = {};
    };
}
