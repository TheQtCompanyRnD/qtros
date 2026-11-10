# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# QML TestCase: FrameNode hierarchies placed from transforms that the test
# itself latches on tf_static, through the public QML API. Needs the ROS
# runtime at run time (a Node spins a real rclcpp context).
qt_internal_add_test(tst_framenode_qml
    GUI
    QMLTEST
    SOURCES
        tst_framenode_qml.cpp
    LIBRARIES
        Qt::Quick
    TESTDATA
        data/tst_framenode.qml
)

qt_internal_extend_target(tst_framenode_qml CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_framenode_qml CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)
