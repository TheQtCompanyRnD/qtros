# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

# Helper variables for downstream projects (populated when find_package(rosidl_generator_qtros2) is called)

find_package(ament_cmake_core QUIET REQUIRED)

set(rosidl_generator_qtros2_BIN
  "${rosidl_generator_qtros2_DIR}/../../../lib/python3.12/site-packages/rosidl_generator_qtros2/__init__.py"
)

set(rosidl_generator_qtros2_GENERATOR_FILES
  "${rosidl_generator_qtros2_DIR}/rosidl_generator_qtros2_generate_interfaces.cmake"
)

set(rosidl_generator_qtros2_TEMPLATE_DIR
  "${rosidl_generator_qtros2_DIR}/../resource"
)

# Include only the user-facing helper macros (NOT the generator script itself)
# The generator script is included automatically by ament_execute_extensions()
include("${rosidl_generator_qtros2_DIR}/qtros2_generate_from_package.cmake")
include("${rosidl_generator_qtros2_DIR}/qtros2_package.cmake")
