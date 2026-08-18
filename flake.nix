# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0
{
  description = "ROS 2 research setup";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    nix-ros-overlay.url = "github:lopsided98/nix-ros-overlay/master";
    nixos-hardware = {
      url = "github:NixOS/nixos-hardware/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };
    nixpkgs.follows = "nix-ros-overlay/nixpkgs"; # IMPORTANT!!!
    sops-nix = {
      url = "github:Mic92/sops-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
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
          inputs.flake-parts.flakeModules.modules
          inputs.treefmt-nix.flakeModule
          (inputs.import-tree ./nix/modules)
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

                  export CI=1
                  export ROS_LOG_DIR=$(mktemp -d)

                  colcon test --return-code-on-test-failure \
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
              ];

              packages = [ config.treefmt.build.wrapper ];

              shellHook =
                let
                  # https://github.com/lopsided98/nix-ros-overlay/issues/810
                  # https://github.com/lopsided98/nix-ros-overlay/issues/544
                  # https://github.com/NixOS/nixpkgs/issues/41340
                  # https://gcc.gnu.org/bugzilla/show_bug.cgi?id=111527
                  dedupeNixCflags = pkgs.writers.writePython3 "dedupe_nix_cflags" { } ''
                    import os
                    import shlex
                    import sys

                    name = sys.argv[1]
                    args = shlex.split(os.environ.get(name, ""))

                    paired = {"-isystem", "-idirafter", "-include", "-imacros"}

                    seen = set()
                    out = []
                    i = 0

                    while i < len(args):
                        arg = args[i]

                        if arg in paired and i + 1 < len(args):
                            item = (arg, args[i + 1])
                            if item not in seen:
                                seen.add(item)
                                out.extend(item)
                            i += 2
                            continue

                        if arg not in seen:
                            seen.add(arg)
                            out.append(arg)

                        i += 1

                    print(" ".join(shlex.quote(x) for x in out))
                  '';
                in
                ''
                  export NIX_CFLAGS_COMPILE="$(${dedupeNixCflags} NIX_CFLAGS_COMPILE)"
                  export NIX_CFLAGS_COMPILE_FOR_TARGET="$(${dedupeNixCflags} NIX_CFLAGS_COMPILE_FOR_TARGET)"

                  addToSearchPath CMAKE_MODULE_PATH "${pkgs.openvdb.dev}/lib/cmake/OpenVDB"
                '';

              NRWS_DOMAIN_ID = "55";
              RMW_IMPLEMENTATION = "rmw_fastrtps_cpp";
              FASTDDS_BUILTIN_TRANSPORTS = "LARGE_DATA";
            };

            legacyPackages = self'.packages;

            packages = builtins.intersectAttrs (import localRosPkgsOverlayPath pkgs null null) rosPkgScope;

            treefmt = {
              programs = {
                clang-format.enable = true;
                clang-tidy = {
                  enable = true;
                  compileCommandsPath = "build/";
                };
                cmake-format.enable = true;
                deadnix.enable = true;
                nixfmt.enable = true;
                nixf-diagnose.enable = true;
                ruff-check.enable = true;
                ruff-format.enable = true;
                xmllint.enable = true;
                yamlfmt.enable = true;
              };
              settings.excludes = [
                "src/*/vendor/*"
                "*.sops.yaml"
              ];
            };
          };
      }
    );

  nixConfig = {
    extra-substituters = [ "https://ros.cachix.org" ];
    extra-trusted-public-keys = [ "ros.cachix.org-1:dSyZxI8geDCJrwgvCOHDoAfOm5sV1wCPjBkKL+38Rvo=" ];
  };
}
