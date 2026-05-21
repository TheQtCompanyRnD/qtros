# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

if(NOT QT_FEATURE_ros2_urdfviewer)
    message(NOTICE "Skipping urdfviewer: Python 3 with packages 'urdf_parser_py' and 'jinja2' is required.")
    return()
endif()

find_package(Qt6 COMPONENTS Widgets QuickWidgets Qml QUIET)
if(NOT TARGET Qt::Widgets OR NOT TARGET Qt::QuickWidgets OR NOT TARGET Qt::Qml)
    message(NOTICE "Skipping urdfviewer: missing Qt::Widgets, Qt::QuickWidgets or Qt::Qml")
    return()
endif()

# Python executable is set by src/core/configure.cmake via QT_INTERNAL_ROS2_BRIDGE_PYTHON.
set(URDF2Q3D_PYTHON_EXECUTABLE_CMAKE "")
if(QT_INTERNAL_ROS2_BRIDGE_PYTHON)
    file(TO_CMAKE_PATH "${QT_INTERNAL_ROS2_BRIDGE_PYTHON}" URDF2Q3D_PYTHON_EXECUTABLE_CMAKE)
endif()

configure_file(
    "${CMAKE_CURRENT_SOURCE_DIR}/src/importer_config.h.in"
    "${CMAKE_CURRENT_BINARY_DIR}/generated/importer_config.h"
    @ONLY
)
unset(URDF2Q3D_PYTHON_EXECUTABLE_CMAKE)

qt_get_tool_target_name(target_name urdfviewer)
qt_internal_add_tool(${target_name}
    TOOLS_TARGET Ros2Core
    SOURCES
        src/main.cpp
        src/ImporterWindow.h
        src/ImporterWindow.cpp
    LIBRARIES
        Qt::Core
        Qt::Gui
        Qt::Widgets
        Qt::Quick
        Qt::QuickWidgets
        Qt::Qml
        Qt::Ros2Core
)
# Install the Python exporter script to libexec so urdfviewer can locate it
# at runtime via QLibraryInfo::LibraryExecutablesPath.
# Use an absolute destination so qt_copy_or_install works in both prefix and
# non-prefix builds (in the latter, file(COPY) needs an absolute path).
qt_path_join(_urdfviewer_libexec_dir "${CMAKE_INSTALL_PREFIX}" "${INSTALL_LIBEXECDIR}")
qt_copy_or_install(
    PROGRAMS "${CMAKE_CURRENT_SOURCE_DIR}/script/urdf2quickexporter.py"
    DESTINATION "${_urdfviewer_libexec_dir}"
)
qt_copy_or_install(
    DIRECTORY "${CMAKE_CURRENT_SOURCE_DIR}/script/templates/urdfviewer"
    DESTINATION "${_urdfviewer_libexec_dir}/templates"
)
unset(_urdfviewer_libexec_dir)

qt_internal_return_unless_building_tools()

target_include_directories(${target_name} PRIVATE
    "${CMAKE_CURRENT_BINARY_DIR}/generated"
)
