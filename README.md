# stone_clay_ros

## Setup

ROS Noetic installation on Ubuntu 20.04 assumed.

``` sh
sudo apt install python3-vcstool python3-catkin-tools
mkdir -p ~/ws_stone_clay/src
cd ~/ws_stone_clay/src
git clone https://github.com/biodigitalmatter/stone_clay_ros.git
cd ..
vcs import src < src/stone_clay_ros/dependencies.repos
vcs import src --input https://raw.githubusercontent.com/ros-industrial/abb_robot_driver/0f0424ea4a857adffa99c6fccafa9ef5329772e8/pkgs.repos
rosdep update
rosdep install --from-paths src --ignore-src
catkin build
```
