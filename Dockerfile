FROM ros:noetic

LABEL maintainer "Anton Tetov <anton@tetov.se>"

SHELL ["/bin/bash","-c"]

# Create local catkin workspace
ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# copy repo to src
COPY . ./src/biodigitalmatter_ros

RUN . /opt/ros/${ROS_DISTRO}/setup.bash \
    && apt-get update \
    && rosdep update

RUN apt-get install git python3-catkin-tools python3-vcstool -y

RUN vcs import src < src/biodigitalmatter_ros/dependencies.repos \
    && vcs import src < src/abb_robot_driver/pkgs.repos

RUN rosdep install -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO}

RUN . /opt/ros/${ROS_DISTRO}/setup.bash && catkin build

COPY ros_catkin_entrypoint.sh /usr/local/bin/ros_catkin_entrypoint.sh

RUN chmod +x /usr/local/bin/ros_catkin_entrypoint.sh

# Always source ros_catkin_entrypoint.sh when launching bash (e.g. when attaching to container)
RUN echo "source /usr/local/bin/ros_catkin_entrypoint.sh" >> /root/.bashrc

ENTRYPOINT ["/usr/local/bin/ros_catkin_entrypoint.sh"]
CMD ["bash"]
