# bioDigital Matter ROS setup

## Setup

ROS 2 Jazzy installation on Ubuntu 24.04 (Noble) assumed.

### 0. Preparations

``` sh
mkdir -p ~/biod_underlay/src
mkdir -p ~/biod_overlay/src

sudo apt update
sudo apt install git python3-vcstool -y

rosdep update

git clone https://github.com/biodigitalmatter/ros.git ~/biod_overlay/src/biodigitalmatter_ros
```

### 1. Underlay for dependencies

``` sh
cd ~/biod_underlay
vcs import src < ~/biod_overlay/src/biodigitalmatter_ros/dependencies.repos

source /opt/ros/jazzy/setup.bash

rosdep install --from-paths src --ignore-src -y
colcon build
```

### 2. Overlay

Create an `.env` file based on `.env.example` adding the passwords needed.

```sh
cd ~/biod_overlay

source ~/biod_underlay/install/setup.bash

PIP_BREAK_SYSTEM_PACKAGES=1 rosdep install --from-paths src --ignore-src -y
colcon build --symlink-install
```

## Troubleshooting

If CMAKE can't find PCL when installing vdb_mapping:

``` bash
sudo mkdir /lib/x86_64-linux-gnu/cmake/pcl/include
sudo ln -s /usr/include/pcl-*/pcl /lib/x86_64-linux-gnu/cmake/pcl/include/pcl
```

## Launch

The entry point is:

```sh
ros2 launch biodigitalmatter_ros bringup.launch.yaml
```

## Following not implemented for jazzy properly yet

### Arguments

#### Switches

There are a few different arguments that turn on and off features. They are by
default set to false.

- `no_robots`: Don't start nodes relating to robot control that need a robot connected.
- `no_rrc`: Don't start `compas_rrc_driver`
- `no_rws`: Don't start rws related nodes, e.g. `rws_state_publisher`
- `no_rgb`: Don't start network camera nodes for RGB (normal) cameras that need
  cameras connected.
- `no_rgbd`: Don't start depth camera nodes that need cameras connected.
- `no_record`: Don't record all topics to file.

Example:

```sh
ros2 launch biodigitalmatter_ros bringup.launch.xml no_robots:=true no_record:=true
```

#### Robot settings

The relevant ones are:

- `robot_ip`:
- `robot_model`:

#### RGB camera settings

The relevant ones are

- `rgb_ip`
- `rgb_name`
- `rgb_user`
- `rgb_pw`

#### RGBD camera settings

The relevant ones are

- `rgbd_camera`: Currently `D435i` for RealSense camera or `OAK-D-POE` for
  Luxonis camera. Defaults to `OAK-D-POE`.

```sh
ros2 launch biodigitalmatter_ros bringup.launch.xml rgbd_camera:=D435i
```

### Launch setups

#### Kaolin on robot

#### Kaolin

```bash
ros2 launch biodigitalmatter_ros bringup.launch.xml no_robots:=true no_rgb:=true no_record:=true
```

#### Cook

```bash
ros2 launch biodigitalmatter_ros bringup.launch.xml no_rgbd:=true no_rrc:=true rgb_pw:=MASKED
```
