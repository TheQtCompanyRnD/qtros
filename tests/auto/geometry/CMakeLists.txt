# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Quick3D is used by the QtQuick3D-quaternion footgun test; it is not pulled in
# at this scope otherwise (only qt_ros2_import_urdf finds it elsewhere).
find_package(Qt6 REQUIRED COMPONENTS Quick Quick3D)

# QML TestCase suite: value-type conversions exercised from QML
# (basic QML types, QtQuick3D types, JS-object structured values, factories).
qt_internal_add_test(tst_geometry_qml
    GUI
    QMLTEST
    SOURCES
        tst_geometry_qml.cpp
    LIBRARIES
        Qt::Quick
        Qt::Quick3D
    TESTDATA
        data/tst_quaternion.qml
        data/tst_vector3.qml
        data/tst_point.qml
        data/tst_pose.qml
        data/tst_twist.qml
        data/tst_transform.qml
)

qt_internal_extend_target(tst_geometry_qml CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_geometry_qml CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)

# C++ QTest: gadget <-> ROS C++ message struct round-trips (not reachable from QML).
# In-tree (developer) builds only: it links the message module as a C++ library,
# which standalone consumers (qt-cmake-standalone-test) can't yet resolve because
# the exported module config doesn't find_package its ROS / sibling deps. The QML
# tests above cover the QML API and build standalone.
if(QT_BUILDING_QT)
    qt_internal_add_test(tst_geometry
        SOURCES
            tst_geometry.cpp
        LIBRARIES
            Qt::Gui
            QtRos2GeometryMessages
    )
endif()
