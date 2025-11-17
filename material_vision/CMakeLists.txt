cmake_minimum_required(VERSION 3.10)
project(material_vision VERSION 0.1.0)

find_package(ament_cmake REQUIRED)

# Install files
install(DIRECTORY launch DESTINATION share/${PROJECT_NAME})

ament_package()
