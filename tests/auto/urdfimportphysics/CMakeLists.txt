# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_internal_add_test(tst_urdfimportphysics
    GUI
    QMLTEST
    SOURCES
        tst_urdfimportphysics.cpp
    LIBRARIES
        Qt::Quick
        Qt::Quick3D
        Qt::Quick3DPhysics
    TESTDATA
        data/tst_urdfimportphysics.qml
)

qt_ros2_import_urdf(tst_urdfimportphysics
    simple_arm.urdf
    PHYSICS
)

qt_internal_extend_target(tst_urdfimportphysics CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_urdfimportphysics CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)
