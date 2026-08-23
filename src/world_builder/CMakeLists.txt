# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

# https://reps.openrobotics.org/rep-2000/#jazzy-jalisco-may-2024---may-2029
cmake_minimum_required(VERSION 3.28.3)
project(world_builder VERSION 0.1.0)

if(NOT CMAKE_C_STANDARD)
  set(CMAKE_C_STANDARD 99)
endif()

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

set(CMAKE_CXX_STANDARD_REQUIRED ON)
set(CMAKE_CXX_EXTENSIONS OFF)

if(CMAKE_COMPILER_IS_GNUCXX OR CMAKE_CXX_COMPILER_ID MATCHES "Clang")
  add_compile_options(-Wall -Wextra -Wpedantic)
endif()

#
# dependencies
#

# for openvdb
list(APPEND CMAKE_MODULE_PATH
  "${CMAKE_CURRENT_SOURCE_DIR}/vendor/OpenVDB/cmake"
)

find_package(ament_cmake REQUIRED)
find_package(rclcpp REQUIRED)

find_package(image_geometry REQUIRED)
find_package(message_filters REQUIRED)
find_package(rosidl_default_generators REQUIRED)
find_package(sensor_msgs REQUIRED)
find_package(std_srvs REQUIRED)
find_package(tf2 REQUIRED)
find_package(tf2_eigen REQUIRED)
find_package(tf2_ros REQUIRED)

find_package(OpenVDB REQUIRED)
find_package(Eigen3 REQUIRED)
find_package(Microsoft.GSL CONFIG REQUIRED)
find_package(tl-expected CONFIG REQUIRED)

#
# srv/msg
#

rosidl_generate_interfaces(${PROJECT_NAME}
  "srv/SaveVolume.srv"
)

rosidl_get_typesupport_target(
  cpp_typesupport_target
  ${PROJECT_NAME}
  "rosidl_typesupport_cpp"
)

#
# targets
#

add_library(world_builder_core
  src/core/vdb_volume.cpp
)

target_include_directories(world_builder_core
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(world_builder_core
  PUBLIC
    OpenVDB::openvdb
    Eigen3::Eigen
)

add_library(world_builder_ros
  src/ros/world_builder_node.cpp
)

target_include_directories(world_builder_ros
  PUBLIC
    $<BUILD_INTERFACE:${CMAKE_CURRENT_SOURCE_DIR}/include>
    $<INSTALL_INTERFACE:include>
)

target_link_libraries(world_builder_ros
  world_builder_core
  Eigen3::Eigen
  "${cpp_typesupport_target}"
  Microsoft.GSL::GSL
  tl::expected
)

ament_target_dependencies(world_builder_ros
  rclcpp
  image_geometry
  message_filters
  sensor_msgs
  std_srvs
  tf2
  tf2_eigen
  tf2_ros
)

add_executable(world_builder_node
  src/ros/main.cpp
)

target_link_libraries(world_builder_node
  PRIVATE
    world_builder_ros
)

#
# install
#

install(
  DIRECTORY include/
  DESTINATION include
)

install(
  TARGETS
    world_builder_core
    world_builder_ros
    world_builder_node

  EXPORT export_world_builder

  ARCHIVE DESTINATION lib
  LIBRARY DESTINATION lib
  RUNTIME DESTINATION lib/${PROJECT_NAME}
)

#
# tests
#

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  file(GLOB_RECURSE AMENT_LINT_AUTO_FILE_EXCLUDE
    vendor/**/*
  )

  ament_lint_auto_find_test_dependencies()

  find_package(ament_cmake_pytest REQUIRED)
  set(_pytest_tests
    tests/ros/test_world_builder_node.py
  )
  foreach(_test_path ${_pytest_tests})
    get_filename_component(_test_name ${_test_path} NAME_WE)
    ament_add_pytest_test(${_test_name} ${_test_path}
      APPEND_ENV PYTHONPATH=${CMAKE_CURRENT_BINARY_DIR}
      TIMEOUT 60
      WORKING_DIRECTORY ${CMAKE_SOURCE_DIR}
    )
  endforeach()

  find_package(ament_cmake_gtest REQUIRED)

  ament_add_gtest(test_vdb_volume
    tests/core/test_vdb_volume.cpp
  )

  target_link_libraries(test_vdb_volume
    world_builder_core
  )
endif()

#
# export
#

ament_export_targets(
  export_world_builder
  HAS_LIBRARY_TARGET
)

ament_export_dependencies(
  rclcpp
  image_geometry
  message_filters
  sensor_msgs
  std_srvs
  tf2
  tf2_eigen
  tf2_ros
  OpenVDB
  Eigen3
)

ament_package()
