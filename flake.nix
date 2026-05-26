{
  description = "ROS 2 research setup";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    systems.url = "github:nix-systems/default-linux";
    treefmt-nix.url = "github:numtide/treefmt-nix";

    nix-ros-workspace = {
      url = "github:hacker1024/nix-ros-workspace";
      flake = false;
    };

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
          let
            rosPkgScope = pkgs.rosPackages.${rosDistro};
          in
          {
            _module.args.pkgs = import inputs.nixpkgs {
              inherit system;
              overlays = [
                (import "${inputs.nixpkgs-not-upstreamable}/nix/overlay")
                inputs.nix-ros-overlay.overlays.default
                (import inputs.nix-ros-workspace { }).overlay
                inputs.self.overlays.default
              ];
            };

            checks = self'.packages // {
              colcon = pkgs.stdenv.mkDerivation {
                name = "colcon-check";
                src = inputs.self;

                nativeBuildInputs =
                  with pkgs;
                  [
                    colcon
                  ]
                  ++ (
                    with rosPkgScope;
                    [
                      ament-cmake
                      ament-cmake-core
                      workspace
                    ]
                    ++ workspace.propagatedBuildInputs
                  );

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
                rosPkgScope.workspace.env
                config.treefmt.build.devShell
              ];
            };

            legacyPackages = self'.packages;

            packages = builtins.intersectAttrs (import localRosPkgsOverlayPath pkgs null null) rosPkgScope;

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
