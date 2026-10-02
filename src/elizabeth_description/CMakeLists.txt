# SPDX-FileCopyrightText: (C) 2026 Anton Tetov Johansson <anton@tetov.se>
# SPDX-License-Identifier: Apache-2.0

 # https://reps.openrobotics.org/rep-2000/#jazzy-jalisco-may-2024---may-2029
cmake_minimum_required(VERSION 3.28.3)
project(elizabeth_description)

find_package(ament_cmake REQUIRED)

install(
  DIRECTORY launch urdf
  DESTINATION share/${PROJECT_NAME}
)

ament_package()
