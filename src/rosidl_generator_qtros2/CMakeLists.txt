# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

cmake_minimum_required(VERSION 3.16)
project(rosidl_generator_qtros2)

find_package(ament_cmake REQUIRED)
find_package(ament_cmake_python REQUIRED)

# Install Python package
ament_python_install_package(${PROJECT_NAME})

# Install CMake files
install(
  DIRECTORY cmake
  DESTINATION share/${PROJECT_NAME}
)

# Install resource templates
install(
  DIRECTORY resource
  DESTINATION share/${PROJECT_NAME}
)

# Install marker file for rosidl
install(
  FILES rosidl_generator_qtros2-extras.cmake
  DESTINATION share/${PROJECT_NAME}/cmake
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

ament_package(
  CONFIG_EXTRAS "rosidl_generator_qtros2-extras.cmake"
)
