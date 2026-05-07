# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_standard_project_setup(REQUIRES 6.8)

qt_internal_add_manual_test(manual_test_urdfrobotarm
    GUI
    SOURCES
        main.cpp
    LIBRARIES
        Qt::Ros2Core
        Qt::Quick3D
)

qt_add_qml_module(manual_test_urdfrobotarm
    URI io.qt.tests.manual.urdfrobotarm
    VERSION 1.0
    QML_FILES
        Main.qml
    RESOURCES
    NO_CACHEGEN
)

qt_ros2_import_urdf(manual_test_urdfrobotarm
    simple_arm.urdf
    PHYSICS
)
