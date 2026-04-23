# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(QT_SBOM_DEFAULT_QT_LICENSE_ID_LIBRARIES "QT_COMMERCIAL_OR_GPL3")

qt_find_package(WrapRos2 PROVIDED_TARGETS WrapRos2::WrapRos2)

# Populate ${QT_CONFIG_BUILD_DIR}/Qt6Ros2Core/ with the generator cmake files,
# Python package, and resource templates BEFORE find_package so the deployed
# rosidl_generator_qtros2Config.cmake (which uses ${CMAKE_CURRENT_LIST_DIR}/...)
# can be used directly without an extra source-tree specific one.
set(_qtros2_src "${CMAKE_CURRENT_SOURCE_DIR}/rosidl_generator_qtros2")

# QT_CONFIG_BUILD_DIR is set by qt_internal_project_setup() when building
# as part of the Qt superproject.  For standalone additional-module builds it
# may be empty or resolve to the Qt installation prefix (not writable).
# Fall back to a conventional location inside the binary tree so that the
# configure-time file(COPY) below always lands somewhere we own.
if(NOT QT_CONFIG_BUILD_DIR OR QT_CONFIG_BUILD_DIR STREQUAL "")
    set(_qtros2_config_build_dir "${CMAKE_BINARY_DIR}/lib/cmake")
else()
    set(_qtros2_config_build_dir "${QT_CONFIG_BUILD_DIR}")
endif()
set(_qtros2_cmake_dest "${_qtros2_config_build_dir}/Qt6Ros2Core")
unset(_qtros2_config_build_dir)

# Bootstrap: copy generator files into the build tree right now (configure
# time) so that find_package(rosidl_generator_qtros2) below can locate
# rosidl_generator_qtros2Config.cmake via the CACHE variable we set next.
# We use file(COPY) directly rather than qt_copy_or_install(COPY ...) because
# the latter may silently skip the copy when the destination is not writable.
file(MAKE_DIRECTORY "${_qtros2_cmake_dest}")
file(COPY
    "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
    "${_qtros2_src}/cmake/qtros2_generate_from_package.cmake"
    "${_qtros2_src}/cmake/analyze_idl_dependencies.cmake"
    "${_qtros2_src}/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
    DESTINATION "${_qtros2_cmake_dest}"
)
file(COPY
    "${_qtros2_src}/rosidl_generator_qtros2"
    "${_qtros2_src}/resource"
    DESTINATION "${_qtros2_cmake_dest}"
)

# Install rules (separate from the configure-time copy above).
qt_copy_or_install(FILES
    "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
    "${_qtros2_src}/cmake/qtros2_generate_from_package.cmake"
    "${_qtros2_src}/cmake/analyze_idl_dependencies.cmake"
    "${_qtros2_src}/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
    DESTINATION "${_qtros2_cmake_dest}"
)
qt_copy_or_install(DIRECTORY
    "${_qtros2_src}/rosidl_generator_qtros2"
    "${_qtros2_src}/resource"
    DESTINATION "${_qtros2_cmake_dest}"
)

unset(_qtros2_src)

set(rosidl_generator_qtros2_DIR "${_qtros2_cmake_dest}"
    CACHE PATH "Path to rosidl_generator_qtros2 cmake directory" FORCE)
unset(_qtros2_cmake_dest)
find_package(rosidl_generator_qtros2 REQUIRED)

add_subdirectory(core)
add_subdirectory(services)

# Phase 1: Foundation interfaces (no qtros2 dependencies)
add_subdirectory(interfaces/builtin)
add_subdirectory(interfaces/rcl)      # depends on builtin

# Phase 2: Messages (most depend only on builtin; geometry/action/etc. fixed in messages/CMakeLists.txt)
add_subdirectory(messages)

# Phase 3: Remaining interfaces that depend on message packages
add_subdirectory(interfaces/composition)      # depends on interfaces/rcl
add_subdirectory(interfaces/type_description) # depends on messages/service

