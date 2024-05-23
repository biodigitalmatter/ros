source /opt/ros/noetic/setup.bash

export CATKIN_WS=~/catkin_ws

if [ -f $CATKIN_WS/devel/setup.bash ] ; then 
  source $CATKIN_WS/devel/setup.bash
fi

if [ -f $CATKIN_WS/src/biodigitalmatter_ros/.env ] ; then 
  set -a # automatically export all vars
  source $CATKIN_WS/src/biodigitalmatter_ros/.env
  set +a
fi

mkdir -p ~/rosbags
