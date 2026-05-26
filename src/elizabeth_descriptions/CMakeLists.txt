cmake_minimum_required(VERSION 3.10)
project(elizabeth_descriptions VERSION 0.1.0)

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY launch urdf
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
