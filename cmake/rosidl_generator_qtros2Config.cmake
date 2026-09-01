# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause
#
# rosidl_generator_qtros2Config.cmake
#
# Deployed alongside Qt6Ros2Core cmake files so that
# find_package(rosidl_generator_qtros2) works from the build or install tree.
# The Python package and resource templates are deployed as siblings of this file.

if(rosidl_generator_qtros2_FOUND)
    return()
endif()

# Generator binary
set(rosidl_generator_qtros2_BIN
    "${CMAKE_CURRENT_LIST_DIR}/rosidl_generator_qtros2/__init__.py"
)

# Generator cmake hook
set(rosidl_generator_qtros2_GENERATOR_FILES
    "${CMAKE_CURRENT_LIST_DIR}/rosidl_generator_qtros2_generate_interfaces.cmake"
)

# EmPy template directory
set(rosidl_generator_qtros2_TEMPLATE_DIR
    "${CMAKE_CURRENT_LIST_DIR}/resource"
)

# Python path
# Make the Python package importable for execute_process() calls that invoke
# "python -m rosidl_generator_qtros2" during configure time generation.
if(DEFINED ENV{PYTHONPATH})
    set(ENV{PYTHONPATH} "${CMAKE_CURRENT_LIST_DIR}:$ENV{PYTHONPATH}")
else()
    set(ENV{PYTHONPATH} "${CMAKE_CURRENT_LIST_DIR}")
endif()

# User-facing cmake macros
include("${CMAKE_CURRENT_LIST_DIR}/qtros2_generate_from_package.cmake")

set(rosidl_generator_qtros2_FOUND TRUE)
