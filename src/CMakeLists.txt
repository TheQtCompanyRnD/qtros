# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

set(QT_SBOM_DEFAULT_QT_LICENSE_ID_LIBRARIES "QT_COMMERCIAL_OR_GPL3")

qt_find_package(WrapRos2 PROVIDED_TARGETS
    WrapRos2::WrapRos2
    rclcpp::rclcpp
    rclcpp_action::rclcpp_action
    rosidl_runtime_cpp::rosidl_runtime_cpp
)

# Populate ${QT_CONFIG_BUILD_DIR}/Qt6Ros2Core/ with the generator cmake files,
# Python package, and resource templates BEFORE find_package so the deployed
# rosidl_generator_qtros2Config.cmake (which uses ${CMAKE_CURRENT_LIST_DIR}/...)
# can be used directly without an extra source-tree specific one.
set(_qtros2_src "${CMAKE_CURRENT_SOURCE_DIR}/rosidl_generator_qtros2")
# Build-tree location, used to populate the build dir for configure-time
# find_package() below. This is an absolute path under ${QT_CONFIG_BUILD_DIR}.
set(_qtros2_cmake_build_dest "${QT_CONFIG_BUILD_DIR}/Qt6Ros2Core")
# Install location, relative to the install prefix. qt_copy_or_install()'s
# DESTINATION must be this (NOT the absolute build dir), otherwise the generated
# install() rule writes into the build tree -- which, under a DESTDIR install
# (e.g. Yocto), lands as <sysroot>/<abs-build-path>/... instead of the prefix.
set(_qtros2_cmake_install_dest "${QT_CONFIG_INSTALL_DIR}/Qt6Ros2Core")

# In prefix builds qt_copy_or_install only generates install() rules and does not
# populate the build tree at configure time (qt_non_prefix_copy is a no-op when
# QT_WILL_INSTALL is TRUE). Explicitly copy the files so that the find_package()
# call below can locate them at configure time.
# NOTE: There's probably some idomatic Qt way to do this, but this works for now.
if(QT_WILL_INSTALL)
    file(COPY
        "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
        "${_qtros2_src}/cmake/qtros2_generate_from_package.cmake"
        "${_qtros2_src}/cmake/analyze_idl_dependencies.cmake"
        "${_qtros2_src}/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
        DESTINATION "${_qtros2_cmake_build_dest}"
    )
    file(COPY
        "${_qtros2_src}/rosidl_generator_qtros2"
        "${_qtros2_src}/resource"
        DESTINATION "${_qtros2_cmake_build_dest}"
    )
endif()

qt_copy_or_install(FILES
    "${CMAKE_SOURCE_DIR}/cmake/rosidl_generator_qtros2Config.cmake"
    "${_qtros2_src}/cmake/qtros2_generate_from_package.cmake"
    "${_qtros2_src}/cmake/analyze_idl_dependencies.cmake"
    "${_qtros2_src}/cmake/rosidl_generator_qtros2_generate_interfaces.cmake"
    DESTINATION "${_qtros2_cmake_install_dest}"
)
qt_copy_or_install(DIRECTORY
    "${_qtros2_src}/rosidl_generator_qtros2"
    "${_qtros2_src}/resource"
    DESTINATION "${_qtros2_cmake_install_dest}"
)
unset(_qtros2_src)
unset(_qtros2_cmake_install_dest)

# find_package() at configure time needs the build-tree copy populated above.
set(rosidl_generator_qtros2_DIR "${_qtros2_cmake_build_dest}"
    CACHE PATH "Path to rosidl_generator_qtros2 cmake directory" FORCE)
unset(_qtros2_cmake_build_dest)
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

# Phase 3: Hand-written runtime modules that depend on message packages
add_subdirectory(transforms)                  # depends on core + messages/geometry; wraps tf2_ros

