# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(QT_SBOM_DEFAULT_QT_LICENSE_ID_LIBRARIES "QT_COMMERCIAL_OR_GPL3")

qt_find_package(WrapRos2 PROVIDED_TARGETS WrapRos2::WrapRos2)

# Populate ${QT_CONFIG_BUILD_DIR}/Qt6Ros2Core/ with the generator cmake files,
# Python package, and resource templates BEFORE find_package so the deployed
# rosidl_generator_qtros2Config.cmake (which uses ${CMAKE_CURRENT_LIST_DIR}/...)
# can be used directly without an extra source-tree specific one.
set(_qtros2_src "${CMAKE_CURRENT_SOURCE_DIR}/rosidl_generator_qtros2")
set(_qtros2_cmake_dest "${QT_CONFIG_BUILD_DIR}/Qt6Ros2Core")

qt_copy_or_install(COPY
    "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
    "${_qtros2_src}/cmake/qtros2_generate_from_package.cmake"
    "${_qtros2_src}/cmake/analyze_idl_dependencies.cmake"
    "${_qtros2_src}/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
    DESTINATION "${_qtros2_cmake_dest}"
)
qt_copy_or_install(COPY
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

