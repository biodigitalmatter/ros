{
  description = "ROS 2 research setup";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    systems.url = "github:nix-systems/default-linux";
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
        workspacePackageNames = [
          "biodigitalmatter-ros"
          "chess-vision"
          "chess-vision-ros"
          "elizabeth-descriptions"
          "material-vision"
        ];
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
          let
            workspacePackages = map (
              name:
              self'.packages.${name} or (throw "Unknown workspace package '${name}' in workspacePackageNames")
            ) workspacePackageNames;

            workspaceRosEnv = pkgs.rosPackages.${rosDistro}.buildEnv {
              wrapPrograms = false;
              paths =
                with pkgs.rosPackages.${rosDistro};
                [
                  ament-cmake
                  ament-cmake-core
                ]
                ++ workspacePackages;
            };
          in
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                (import "${inputs.nixpkgs-not-upstreamable}/nix/overlay")
                inputs.nix-ros-overlay.overlays.default
                inputs.self.overlays.default
              ];
            };

            checks = self'.packages // {
              colcon = pkgs.stdenv.mkDerivation {
                name = "colcon-check";
                src = inputs.self;

                inputsFrom = [
                  self'.devShells.default
                ];

                nativeBuildInputs = with pkgs; [
                  colcon
                  pkg-config
                  workspaceRosEnv
                ];

                dontConfigure = true;
                doCheck = true;
                dontWrapQtApps = true;

                buildPhase = ''
                  runHook preBuild

                  colcon build --symlink-install

                  runHook postBuild
                '';

                checkPhase = ''
                  runHook preCheck

                  source install/setup.bash

                  CI=1 colcon test --return-code-on-test-failure \
                    --event-handlers=console_direct+

                  runHook postCheck
                '';

                installPhase = ''
                  runHook preInstall

                  touch $out

                  runHook postInstall
                '';

              };
            };

            devShells.default = pkgs.mkShell {
              name = "ros2nix ${rosDistro} shell";

              inputsFrom = [
                config.treefmt.build.devShell
                workspaceRosEnv
              ];

              buildInputs = with pkgs; [
                (python3.withPackages (
                  ps: with ps; [
                    argcomplete
                    compas
                    numpy
                    rosbags
                  ]
                ))
                colcon
                docker-compose
                opencv
                pkg-config
                # devtools
                basedpyright
                config.treefmt.build.wrapper
                nixd
                ruff
                ty
              ];
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
