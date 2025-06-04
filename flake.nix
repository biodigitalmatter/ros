{
  description = "ROS 2 research setup";

  inputs = {
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";

    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    flake-parts.url = "github:hercules-ci/flake-parts";
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      let
        rosDistro = "jazzy";
        localRosPkgsOverlay = ./nix/ros/overlay.nix;
      in
      {
        imports = [
          inputs.treefmt-nix.flakeModule
        ];

        systems = [
          "aarch64-linux"
          "x86_64-linux"
        ];

        flake.overlays.default =
          let
            applyDistroOverlay =
              rosOverlay: rosPackages:
              rosPackages
              // builtins.mapAttrs (
                rosDistro: rosPkgs: if rosPkgs ? overrideScope then rosPkgs.overrideScope rosOverlay else rosPkgs
              ) rosPackages;
          in
          final: prev: {
            rosPackages = applyDistroOverlay (import localRosPkgsOverlay) prev.rosPackages;
          };

        perSystem =
          {
            pkgs,
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                inputs.nix-ros-overlay.overlays.default
                inputs.self.overlays.default
                (_: prev: {
                  abb_libegm = prev.callPackage ./nix/abb_libegm/package.nix { };
                  abb_librws = prev.callPackage ./nix/abb_librws/package.nix { };
                })
              ];
            };

            devShells.default = import ./shell.nix {
              inherit pkgs rosDistro;
              extraPkgs = {
                inherit (pkgs)
                  cmake
                  docker-compose
                  gnumake
                  nixd
                  ;
              };
              extraPaths = [ ];
            };

            legacyPackages = pkgs.rosPackages;
            packages = builtins.intersectAttrs (import localRosPkgsOverlay null
              null
            ) pkgs.rosPackages.${rosDistro};

            checks = builtins.intersectAttrs (import localRosPkgsOverlay null
              null
            ) pkgs.rosPackages.${rosDistro};
            treefmt = {
              programs = {
                nixfmt.enable = true;
                nixf-diagnose.enable = true;
                yamlfmt.enable = true;
              };
              pkgs = import inputs.nixpkgs-unstable { inherit system; }; # nixf-diagnose
              projectRootFile = "flake.nix";
            };
          };
      }
    );

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
