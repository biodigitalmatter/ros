{
  nix-ros-overlay ? builtins.fetchTarball "https://github.com/lopsided98/nix-ros-overlay/archive/master.tar.gz",
  pkgs ? import nix-ros-overlay { },
  rosDistro ? "jazzy",
  extraPkgs ? { },
  extraPaths ? [ ],
  withPackages ? _: [ ],
  extraShellHook ? "",
}:
pkgs.mkShell {
  name = "ros2nix ${rosDistro} shell";
  packages = [
    (pkgs.rosPackages.${rosDistro}.buildEnv {
      wrapPrograms = false;
      paths = [
        pkgs.colcon
        pkgs.rosPackages.${rosDistro}.ros-core

        # Work around https://github.com/lopsided98/nix-ros-overlay/pull/624
        pkgs.rosPackages.${rosDistro}.ament-cmake-core
        pkgs.rosPackages.${rosDistro}.python-cmake-module
      ]
      ++ (
        with pkgs;
        with pkgs.rosPackages.${rosDistro};
        with extraPkgs;
        [
          biodigitalmatter-ros
          # biodigitalmatter_ros deps
          abb-bringup
          abb-rws-client
          axis-camera
          compas-rrc-driver
          docker-compose
          cv-bridge
          robot-calibration
          rosbridge-server
          # depthai
          depthai-ros

          chess-vision
          # chess-vision deps
          cv-bridge
          opencv
          (python.withPackages (
            ps: with ps; [
              scipy
              numpy
            ]
          ))

          ros2-utils-tool
          rosbag2
        ]
      )
      ++ builtins.attrValues extraPkgs
      ++ extraPaths
      ++ withPackages (pkgs // pkgs.rosPackages.${rosDistro});
    })
  ];
  shellHook = ''
    # Setup ROS 2 shell completion. Doing it in direnv is useless.
    if [[ ! $DIRENV_IN_ENVRC ]]; then
        eval "$(${pkgs.python3Packages.argcomplete}/bin/register-python-argcomplete ros2)"
        eval "$(${pkgs.python3Packages.argcomplete}/bin/register-python-argcomplete colcon)"
    fi
  ''
  + extraShellHook;
}
