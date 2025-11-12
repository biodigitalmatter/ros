{
  description = "ROS 2 research setup";

  inputs = {
    ros-dev-flake.url = "git+https://git.sr.ht/~tetov/ros-dev-flake";
    nixpkgs.follows = "ros-dev-flake/nixpkgs";
    nix-ros-overlay.follows = "ros-dev-flake/nix-ros-overlay";
    systems.follows = "ros-dev-flake/systems";
    flake-parts.follows = "ros-dev-flake/flake-parts";

    nixpkgs-depthai-core.url = "github:tetov/nixpkgs/depthai-core";
    nixpkgs-unstable.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    treefmt-nix.url = "github:numtide/treefmt-nix";
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
                rosDistro: rosPkgs: if rosPkgs ? overrideScope then rosPkgs.overrideScope rosOverlay else rosPkgs
              ) rosPackages;
          in
          final: prev: {
            rosPackages = applyDistroOverlay (import localRosPkgsOverlayPath) prev.rosPackages;
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
                inputs.ros-dev-flake.overlays.default
                inputs.self.overlays.default
                (_: prev: {
                  abb_libegm = prev.callPackage ./nix/abb_libegm/package.nix { };
                  abb_librws = prev.callPackage ./nix/abb_librws/package.nix { };
                  inherit (inputs.nixpkgs-depthai-core.legacyPackages.${system}) cpr fp16 libnop;
                })
              ];
            };

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
                    docker-compose
                    nixd
                    colcon
                    opencv
                    (pkgs.python3.withPackages (
                      ps: with ps; [
                        scipy
                        numpy
                      ]
                    ))
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
                    paths = with self'.packages; [
                      biodigitalmatter-ros
                      chess-vision
                      abb-bringup
                      abb-rws-client
                      compas-rrc-driver
                    ];
                  })
                ];

              };
            legacyPackages = pkgs.rosPackages;
            packages = builtins.intersectAttrs (import localRosPkgsOverlayPath null
              null
            ) pkgs.rosPackages.${rosDistro};
            checks = builtins.intersectAttrs (import localRosPkgsOverlayPath null
              null
            ) pkgs.rosPackages.${rosDistro};
            treefmt = {
              programs = {
                nixfmt.enable = true;
                nixf-diagnose.enable = true;
                ruff-check.enable = true;
                ruff-format.enable = true;
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
