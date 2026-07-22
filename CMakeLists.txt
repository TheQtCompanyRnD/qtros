# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

cmake_minimum_required(VERSION 3.16)

include(.cmake.conf)
project(QtRos2
    VERSION "${QT_REPO_MODULE_VERSION}"
    DESCRIPTION "Qt ROS2 Bridge Module"
    HOMEPAGE_URL "https://qt.io/"
    LANGUAGES CXX C
)

find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS BuildInternals)

include(cmake/QtRos2Macros.cmake)

# This should be called as early as possible, just after find_package(BuildInternals) where it is
# defined.
qt_internal_project_setup()

find_package(Qt6 ${PROJECT_VERSION} CONFIG REQUIRED COMPONENTS Core Network Quick)
find_package(Qt6 ${PROJECT_VERSION} QUIET CONFIG OPTIONAL_COMPONENTS Concurrent QuickTest)

if(WATCHOS)
    message(NOTICE "Skipping the build as the condition \"NOT WATCHOS\" is not met.")
    return()
endif()
if(NOT TARGET Qt::Quick)
    message(NOTICE "Skipping the build as the condition \"TARGET Qt::Quick\" is not met.")
    return()
endif()

qt_build_repo()
