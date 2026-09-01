# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Exercises QRos2Context's clean shutdown on SIGINT/SIGTERM. Links QtRos2Core and
# brings up a real rclcpp context/participant, so it is restricted to in-tree
# (developer) builds -- the same constraint as the C++ message tests, whose
# exported module config can't yet resolve its ROS deps for standalone consumers.
# UNIX-only: the test delivers a POSIX SIGTERM to a child process.
if(QT_BUILDING_QT AND UNIX)
    qt_internal_add_test(tst_shutdown
        SOURCES
            tst_shutdown.cpp
        LIBRARIES
            Qt::Ros2Core
    )
endif()
