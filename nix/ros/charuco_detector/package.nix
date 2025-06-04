{
  lib,
  buildRosPackage,
  fetchFromGitHub,
  ament-cmake,
  ament-lint-auto,
  ament-lint-common,
  charuco-detector-interfaces,
  geometry-msgs,
  rclcpp,
  sensor-msgs,
  std-msgs,
}:
buildRosPackage {
  pname = "ros-jazzy-charuco-detector";
  version = "0.0.0";

  src = fetchFromGitHub {
    owner = "errrr0501";
    repo = "charuco_detector_ROS2";
    rev = "1e6841c88fe473272b125fcc1e3aba29a5a12f28";
    sha256 = "0s9kfzzy46fqb6yi4jdzpgifjlb45rkafymcb5ygihw0f8l9xc5h";
  };

  buildType = "ament_cmake";
  sourceRoot = "source/charuco_detector";
  patchFlags = "-p2";
  patches = [
    ./0001-fix-changes-needed-for-jazzy.patch
  ];
  buildInputs = [ ament-cmake ];
  checkInputs = [
    ament-lint-auto
    ament-lint-common
  ];
  propagatedBuildInputs = [
    charuco-detector-interfaces
    geometry-msgs
    rclcpp
    sensor-msgs
    std-msgs
  ];
  nativeBuildInputs = [ ament-cmake ];

  meta = {
    description = "Detector of ChArUco patterns using the cv::aruco::CharucoBoard.";
    license = with lib.licenses; [ bsd3 ];
  };
}
