FROM ros:noetic-perception-focal

LABEL maintainer "Anton Tetov <anton@tetov.se>"

SHELL ["/bin/bash","-c"]

# Create local catkin workspace
ENV CATKIN_WS=/root/catkin_ws
RUN mkdir -p $CATKIN_WS/src
WORKDIR $CATKIN_WS

# copy repo to src
COPY . ./src/biodigitalmatter_ros

RUN apt-get update

RUN apt-get upgrade -y

RUN rosdep update

RUN apt-get install -y     \
      git                  \
      iputils-ping         \
      net-tools            \
      python3-catkin-tools \
      python3-vcstool

RUN vcs import src < src/biodigitalmatter_ros/dependencies.repos
RUN vcs import src < src/abb_robot_driver/pkgs.repos

RUN rosdep install -y --from-paths . --ignore-src --rosdistro ${ROS_DISTRO} \
      --skip-keys=depthai 

# https://github.com/luxonis/depthai-ros/issues/540
RUN cd /tmp \ 
      && git clone --recursive https://github.com/luxonis/depthai-core.git --branch v2.24.0 \
      && cmake -Hdepthai-core -Bdepthai-core/build -DBUILD_SHARED_LIBS=ON -DCMAKE_INSTALL_PREFIX=/usr/local \
      && cmake --build depthai-core/build --target install \
      && rm -r depthai-core

RUN source /opt/ros/${ROS_DISTRO}/setup.bash && catkin build

COPY --chmod=755 ros_catkin_entrypoint.sh /usr/local/bin

# Always source ros_catkin_entrypoint.sh when launching bash (e.g. when attaching to container)
RUN echo "source /usr/local/bin/ros_catkin_entrypoint.sh" >> /root/.bashrc

ENTRYPOINT ["/usr/local/bin/ros_catkin_entrypoint.sh"]
CMD ["bash"]
