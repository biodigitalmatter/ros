#!/bin/sh
set -e

: "${ROS_DISTRO:?ROS_DISTRO is not set}"
. "/opt/ros/$ROS_DISTRO/setup.sh"
. "/ros2_ws/install/setup.sh"

exec "$@"
