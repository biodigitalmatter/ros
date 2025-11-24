cmake_minimum_required(VERSION 3.10)
project(tf2_2_odom VERSION 0.1.0)


if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)
find_package(nav_msgs REQUIRED)
find_package(geometry_msgs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)

add_executable(tf2_2_odom src/tf2_2_odom_node.cpp)
ament_target_dependencies(
  tf2_2_odom
  rclcpp
  nav_msgs
  geometry_msgs
  tf2
  tf2_ros
)

install(TARGETS tf2_2_odom
  DESTINATION lib/${PROJECT_NAME})

ament_package()
