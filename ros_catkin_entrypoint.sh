#!/bin/bash

source "/opt/ros/$ROS_DISTRO/setup.bash"

export CATKIN_WS=${CATKIN_WS:-$HOME/catkin_ws}

if [ -f $CATKIN_WS/devel/setup.bash ] ; then 
  source $CATKIN_WS/devel/setup.bash
fi

if [ -f $CATKIN_WS/src/biodigitalmatter_ros/.env ] ; then 
  set -a # automatically export all vars
  source $CATKIN_WS/src/biodigitalmatter_ros/.env
  set +a
fi

mkdir -p ~/rosbags

exec "$@"
