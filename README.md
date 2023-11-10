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
rosdep install --from-paths src --ignore-src
catkin build
```
