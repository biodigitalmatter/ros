{
  description = "ROS 2 research setup";

  inputs = {
    ros-dev-flake.url = "git+https://git.sr.ht/~tetov/ros-dev-flake";
    nixpkgs.follows = "ros-dev-flake/nixpkgs";
    nix-ros-overlay.follows = "ros-dev-flake/nix-ros-overlay";
    systems.follows = "ros-dev-flake/systems";
    flake-parts.follows = "ros-dev-flake/flake-parts";

    nixpkgs-depthai-core.url = "github:tetov/nixpkgs/depthai-core";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    nixpkgs-not-upstreamable = {
      url = "git+https://git.sr.ht/~tetov/nixpkgs-not-upstreamable";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      let
        rosDistro = "jazzy";
        localRosPkgsOverlayPath = ./nix/ros/overlay.nix;
      in
      {
        imports = [
          inputs.treefmt-nix.flakeModule
        ];

        systems = import inputs.systems;

        flake.overlays.default =
          let
            applyDistroOverlay =
              rosOverlay: rosPackages:
              rosPackages
              // builtins.mapAttrs (
                _rosDistro: rosPkgs: if rosPkgs ? overrideScope then rosPkgs.overrideScope rosOverlay else rosPkgs
              ) rosPackages;
          in
          final: prev: {
            rosPackages = applyDistroOverlay (import localRosPkgsOverlayPath prev) prev.rosPackages;
            abb_libegm = final.callPackage ./nix/abb_libegm/package.nix { };
            abb_librws = final.callPackage ./nix/abb_librws/package.nix { };
          };

        perSystem =
          {
            config,
            pkgs,
            self',
            system,
            ...
          }:
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                (import "${inputs.nixpkgs-not-upstreamable}/nix/overlay")
                inputs.ros-dev-flake.overlays.default
                inputs.self.overlays.default
              ];
            };

            checks = self'.packages;

            devShells.default =
              let
                extendedShell = inputs.ros-dev-flake.lib.extendShell system rosDistro (
                  with pkgs;
                  [
                    "cv-bridge"
                    "robot-calibration"
                    "ament-cmake-core"
                    "python-cmake-module"
                    "robot-calibration"
                    "rosbridge-server"
                    "axis-camera"
                    "foxglove-bridge"
                    colcon

                  ]
                );
              in
              pkgs.mkShell {
                inputsFrom = [
                  config.treefmt.build.devShell
                  extendedShell
                ];
                buildInputs = [
                  (pkgs.rosPackages.${rosDistro}.buildEnv {
                    wrapPrograms = false;
                    paths = builtins.attrValues (
                      removeAttrs self'.packages [
                        "biodigitalmatter-ros"
                        "chess-vision"
                        "chess-vision-ros"
                        "material-vision"
                      ]
                    );
                  })
                  (pkgs.python3.withPackages (
                    ps: with ps; [
                      compas
                      numpy
                      scipy
                    ]
                  ))
                ]
                ++ (with pkgs; [
                  nixd
                  docker-compose
                  opencv
                  # devtools
                  ruff
                  ty
                  basedpyright
                  config.treefmt.build.wrapper
                ]);
              };

            legacyPackages = self'.packages;

            packages = builtins.intersectAttrs (import localRosPkgsOverlayPath pkgs null
              null
            ) pkgs.rosPackages.${rosDistro};

            treefmt = {
              programs = {
                deadnix.enable = true;
                nixfmt.enable = true;
                nixf-diagnose.enable = true;
                ruff-check = {
                  enable = true;
                  extendSelect = [ "I" ]; # should sort
                };
                ruff-format.enable = true;
                xmllint.enable = true;
                yamlfmt.enable = true;
              };
            };
          };
      }
    );

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
