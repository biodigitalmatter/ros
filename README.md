# bioDigital Matter ROS setup

## Setup

ROS Noetic installation on Ubuntu 20.04 assumed.

``` sh
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
