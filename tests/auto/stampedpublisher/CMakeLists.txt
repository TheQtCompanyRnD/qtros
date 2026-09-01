# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# QML TestCase: an end-to-end publish->subscribe roundtrip demonstrating the
# autoStamp behaviors (forward an explicit stamp, auto-fill a zero stamp from the
# node clock, leave it zero when disabled) through the public QML API. Needs the
# ROS runtime at run time (a Node spins a real rclcpp context).
qt_internal_add_test(tst_stampedpublisher_qml
    GUI
    QMLTEST
    SOURCES
        tst_stampedpublisher_qml.cpp
    LIBRARIES
        Qt::Quick
    TESTDATA
        data/tst_autostamp.qml
)

qt_internal_extend_target(tst_stampedpublisher_qml CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_stampedpublisher_qml CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)

# C++ QTest: exercises the fill-if-zero policy directly via the protected
# applyAutoStamp() (there is no public C++ API). In-tree (developer) builds only,
# like the other C++ tests, since it links the private Core library.
if(QT_BUILDING_QT)
    qt_internal_add_test(tst_stampedpublisher
        SOURCES
            tst_stampedpublisher.cpp
        LIBRARIES
            Qt::Ros2CorePrivate
    )
endif()
