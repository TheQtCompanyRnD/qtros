# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause

cmake_minimum_required(VERSION 3.16)

project(robotarmcollision VERSION 1.0 LANGUAGES CXX)

set(CMAKE_CXX_STANDARD_REQUIRED ON)

find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D Quick3DPhysics Ros2Core)

qt_standard_project_setup(REQUIRES 6.8)

qt_add_executable(robotarmcollisionapp
    main.cpp
)

qt_add_qml_module(robotarmcollisionapp
    URI robotarmcollision
    VERSION 1.0
    QML_FILES
        Main.qml
    NO_CACHEGEN
)

# Generates the SimpleArm QML module (QtQuick3DPhysics rigid bodies and collision
# shapes) from the URDF, running balsam to convert the collision meshes.
qt_ros2_import_urdf(robotarmcollisionapp
    simple_arm.urdf
    PHYSICS
    ROS_BRIDGE
)

target_link_libraries(robotarmcollisionapp
	PUBLIC
        Qt6::Quick
        Qt6::Quick3D
        Qt6::Quick3DPhysics
)

install(TARGETS robotarmcollisionapp
    BUNDLE  DESTINATION .
    RUNTIME DESTINATION ${CMAKE_INSTALL_BINDIR}
    LIBRARY DESTINATION ${CMAKE_INSTALL_LIBDIR}
)

qt_generate_deploy_qml_app_script(
    TARGET robotarmcollisionapp
    OUTPUT_SCRIPT deploy_script
    MACOS_BUNDLE_POST_BUILD
    NO_UNSUPPORTED_PLATFORM_ERROR
    DEPLOY_USER_QML_MODULES_ON_UNSUPPORTED_PLATFORM
)
install(SCRIPT ${deploy_script})

