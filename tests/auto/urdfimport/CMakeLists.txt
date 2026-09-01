# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_internal_add_test(tst_urdfimport
    GUI
    QMLTEST
    SOURCES
        tst_urdfimport.cpp
    LIBRARIES
        Qt::Quick
        Qt::Quick3D
    TESTDATA
        data/tst_urdfimport.qml
)

qt_ros2_import_urdf(tst_urdfimport
    simple_arm.urdf
)

qt_internal_extend_target(tst_urdfimport CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_urdfimport CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)
