FROM gramaziokohler/ros-noetic-base:latest

LABEL maintainer "Anton Tetov <anton@tetov.se>"

# Create local catkin workspace
ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# copy repo to src
COPY . ./src/biodigitalmatter_ros

RUN source /opt/ros/${ROS_DISTRO}/setup.bash \
    && apt-get update \
    && rosdep update

RUN apt-get install python3-vcstool python3-catkin-tools -y

RUN vcs import src < src/biodigitalmatter_ros/dependencies.repos \
    && vcs import src < src/abb_robot_driver/pkgs.repos

RUN rosdep install -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO}

RUN /opt/ros/${ROS_DISTRO}/bin/catkin_make

RUN echo "source /usr/local/bin/ros_catkin_entrypoint.sh" >> /root/.bashrc
RUN echo 'source $CATKIN_WS/src/biodigitalmatter_ros/bashrc_fragment' >> /root/.bashrc

ENTRYPOINT ["roslaunch" "biodigitalmatter_ros" "bringup.lauch"]
CMD ["bash"]