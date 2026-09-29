# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0
{
  description = "ROS 2 research setup";

  inputs = {
    flake-parts.url = "github:hercules-ci/flake-parts";
    import-tree.url = "github:denful/import-tree";
    nix-ros-overlay = {
      url = "github:lopsided98/nix-ros-overlay/master";
      inputs.flake-utils.inputs.systems.follows = "systems";
    };
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

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nix-ros-overlay/nixpkgs";
    };

    nix-ros-workspace = {
      url = "github:hacker1024/nix-ros-workspace";
      flake = false;
    };

    nixpkgs-not-upstreamable = {
      url = "git+https://git.sr.ht/~tetov/nixpkgs-not-upstreamable";
      flake = false;
    };

    # package sources
    abb_libegm = {
      type = "github";
      owner = "ros-industrial";
      repo = "abb_libegm";
      rev = "2c9350abfb67131cae796805fed8cd6eeb2ab7f9";
      flake = false;
    };

    abb_librws = {
      type = "github";
      owner = "ros-industrial";
      repo = "abb_librws";
      rev = "9ba08371482f3975f364011db9b1368fa0fc6b32";
      flake = false;
    };

    # ROS packages
    abb_egm_rws_managers = {
      type = "github";
      owner = "ros-industrial";
      repo = "abb_egm_rws_managers";
      rev = "7e554e53b415df1bbd743392b84a055c499b63d2";
      flake = false;
    };

    abb_ros2 = {
      type = "github";
      owner = "PickNikRobotics";
      repo = "abb_ros2";
      rev = "05cbabe774ef026b1cd36fe6b253b55f55e16340";
      # ref = "rolling";
      flake = false;
    };

    abb_ros2_msgs = {
      type = "github";
      owner = "gbartyzel";
      repo = "abb_ros2_msgs";
      rev = "071bb1fc2148a7cd850a1ff550c5987e67da6bdd";
      # ref = "rolling";
      flake = false;
    };

    compas_rrc_ros = {
      type = "github";
      owner = "biodigitalmatter";
      repo = "compas_rrc_ros";
      rev = "f9e3cb5e2a2b100486f47f044c3702d77b9026a9"; # ros2
      # ref = "ros2";
      flake = false;
    };

    industrial_reconstruction = {
      type = "github";
      owner = "ros-industrial";
      repo = "industrial_reconstruction";
      rev = "90fdc690be9230480614b5cf96cc39c873de292c";
      # ref = "main";
      flake = false;
    };

    perception_open3d = {
      type = "github";
      owner = "ros-perception";
      repo = "perception_open3d";
      ref = "0.1.2";
      flake = false;
    };

    ros2_utils_tool = {
      type = "github";
      owner = "MaxFleur";
      repo = "ros2_utils_tool";
      ref = "v0.13.0";
      flake = false;
    };

    # open3d and deps
    open3d = {
      type = "github";
      owner = "isl-org";
      repo = "Open3D";
      ref = "v0.19.0";
      flake = false;
    };

    cutlass133 = {
      type = "github";
      owner = "NVIDIA";
      repo = "cutlass";
      ref = "v1.3.3";
      flake = false;
    };

    directx-headers16063 = {
      type = "github";
      owner = "microsoft";
      repo = "DirectX-Headers";
      ref = "v1.606.3";
      flake = false;
    };

    directx-math = {
      type = "github";
      owner = "microsoft";
      repo = "DirectXMath";
      ref = "may2022";
      flake = false;
    };

    poisson-recon = {
      type = "github";
      owner = "isl-org";
      repo = "Open3D-PoissonRecon";
      rev = "90f3f064e275b275cff445881ecee5a7c495c9e0";
      flake = false;
    };

    stdgpu = {
      type = "github";
      owner = "stotko";
      repo = "stdgpu";
      rev = "2588168d226bd17229dbf58d821549580791089d";
      flake = false;
    };

    tinygltf297 = {
      type = "github";
      owner = "syoyo";
      repo = "tinygltf";
      # open3D uses 2.4
      ref = "v2.9.7";
      flake = false;
    };

    uvatlas = {
      type = "github";
      owner = "microsoft";
      repo = "UVAtlas";
      ref = "may2022";
      flake = false;
    };
  };

  outputs =
    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } (
      { ... }:
      let
        rosDistro = "jazzy";
        localRosPkgsOverlayPath = ./nix/overlays/ros.nix;
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
            rosPackages = applyDistroOverlay (import localRosPkgsOverlayPath final) prev.rosPackages;
            packageSources = {
              inherit (inputs)
                abb_libegm
                abb_librws

                # ros packages
                abb_egm_rws_managers
                abb_ros2
                abb_ros2_msgs
                compas_rrc_ros
                industrial_reconstruction
                perception_open3d
                ros2_utils_tool

                # open3d and deps
                cutlass133
                directx-headers16063
                directx-math
                open3d
                poisson-recon
                stdgpu
                tinygltf297
                uvatlas
                ;
            };
            abb_libegm = final.callPackage ./nix/packages/abb_libegm/package.nix { };
            abb_librws = final.callPackage ./nix/packages/abb_librws/package.nix { };
            open3d = final.callPackage ./nix/packages/open3d/package.nix {
              pythonPackages = final.python3Packages;
            };

            pythonPackagesExtensions = prev.pythonPackagesExtensions ++ [
              (pyFinal: _pyPrev: {
                open3d = pyFinal.callPackage ./nix/packages/open3d/python.nix {
                  open3d = final.open3d.override {
                    pythonPackages = pyFinal;
                  };
                };
              })
            ];
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

            packages = builtins.intersectAttrs (import localRosPkgsOverlayPath pkgs null null) rosPkgScope // {
              open3d = pkgs.open3d;

              open3d-python = pkgs.python3Packages.open3d;

              open3d-python-cuda = pkgs.python3Packages.open3d.override {
                withCuda = true;
              };
            };

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
