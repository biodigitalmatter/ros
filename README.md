# bioDigital Matter ROS setup

## Setup

ROS Noetic installation on Ubuntu 20.04 assumed.

```sh
grep -qxF 'source ~/catkin_ws/src/biodigitalmatter_ros/bashrc_fragment.sh' ~/.bashrc || echo 'source ~/catkin_ws/src/biodigitalmatter_ros/bashrc_fragment.sh' >> ~/.bashrc
sudo apt install python3-vcstool python3-catkin-tools
mkdir -p ~/catkin_ws/src
cd ~/catkin_ws/src
git clone https://github.com/biodigitalmatter/biodigitalmatter_ros.git
cd ..
vcs import src < src/biodigitalmatter_ros/dependencies.repos
vcs import src --input https://raw.githubusercontent.com/ros-industrial/abb_robot_driver/0f0424ea4a857adffa99c6fccafa9ef5329772e8/pkgs.repos
rosdep update
rosdep install --from-paths src --ignore-src -y
catkin build
```

Create an .env file based on .env.example adding the passwords needed.

## Launch

The entry point is:

```sh
roslaunch biodigitalmatter_ros bringup.launch
```

### Arguments

#### Switches

There are a few different arguments that turn on and off features. They are by
default set to false.

- `no_robots`: Don't start nodes relating to robot control that need a robot connected.
- `no_rrc`: Don't start compas_rrc_driver
- `no_rws`: Don't start rws related nodes, e.g. `rws_state_publisher`
- `no_rgb`: Don't start network camera nodes for RGB (normal) cameras that need
  cameras connected.
- `no_rgbd`: Don't start depth camera nodes that need cameras connected.
- `no_record`: Don't record all topics to file.

Example:

```sh
roslaunch biodigitalmatter_ros bringup.launch no_robots:=true no_record:=true
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
roslaunch biodigitalmatter_ros bringup.launch rgbd_camera:=D435i
```
