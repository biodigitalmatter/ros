{
  buildRosPackage,
  fetchFromGitHub,
  ament-cmake,
  catch-ros2,
  cv-bridge,
  geometry-msgs,
  pcl-conversions,
  rclcpp,
  ros-environment,
  rosbag2-cpp,
  rosbag2-transport,
  sensor-msgs,
  tf2-msgs,
  qt5,
}:
buildRosPackage {
  pname = "ros-jazzy-ros2-utils-tool";
  version = "0.13.0";

  src = fetchFromGitHub {
    owner = "MaxFleur";
    repo = "ros2_utils_tool";
    rev = "v0.13.0";
    sha256 = "sha256-JNg643dyvBnDTBMzxHDCpJLN+ENpR3Kee7KCFCCdPJo";
  };

  buildType = "ament_cmake";
  buildInputs = [
    ament-cmake
    catch-ros2 # to get through configure
    ros-environment # to set ROS_DISTRO for configure
  ];
  checkInputs = [ catch-ros2 ];
  propagatedBuildInputs = [
    cv-bridge
    geometry-msgs
    pcl-conversions
    rclcpp
    rosbag2-cpp
    rosbag2-transport
    sensor-msgs
    tf2-msgs
    qt5.qtbase
  ];
  nativeBuildInputs = [
    ament-cmake
    qt5.wrapQtAppsHook
  ];

  meta = {
    description = "The ros2_utils_tool package";
    license = [ "EUPLv1.2" ];
  };
}
