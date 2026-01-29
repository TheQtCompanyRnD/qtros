# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

cmake_minimum_required(VERSION 3.16)
project(qtros2_type_description_interfaces)

if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

find_package(ament_cmake REQUIRED)
find_package(type_description_interfaces QUIET)

if(NOT type_description_interfaces_FOUND)
  message(WARNING "qtros2_type_description_interfaces: type_description_interfaces is not available on this ROS 2 distro. Installing a stub target so dependents can still build.")
  add_library(${PROJECT_NAME}_qtcpp INTERFACE)
  install(TARGETS ${PROJECT_NAME}_qtcpp EXPORT ${PROJECT_NAME}_qtcpp__targets)
  ament_export_targets(${PROJECT_NAME}_qtcpp__targets HAS_LIBRARY_TARGET)
  ament_package()
  return()
endif()

find_package(rosidl_generator_qtros2 REQUIRED)

qtros2_generate_from_package(
  TARGET ${PROJECT_NAME}
  SOURCE_PACKAGE type_description_interfaces
  QML_MODULE_URI QtROS2.TypeDescriptionInterfaces
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

qtros2_package(TARGET ${PROJECT_NAME})
