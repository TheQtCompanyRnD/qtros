# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

cmake_minimum_required(VERSION 3.16)
project(qtros2_builtin_interfaces)

# Compiler settings
if(NOT CMAKE_CXX_STANDARD)
  set(CMAKE_CXX_STANDARD 17)
endif()

# Find dependencies
find_package(rosidl_generator_qtros2 REQUIRED)

#############################################################################
# Generate Qt wrappers for builtin_interfaces
#############################################################################

qtros2_generate_from_package(
  TARGET ${PROJECT_NAME}
  SOURCE_PACKAGE builtin_interfaces
  QML_MODULE_URI QtROS2.BuiltinInterfaces
)

if(BUILD_TESTING)
  find_package(ament_lint_auto REQUIRED)
  ament_lint_auto_find_test_dependencies()
endif()

qtros2_package(TARGET ${PROJECT_NAME})
