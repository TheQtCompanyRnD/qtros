# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Exercises QRos2Node / QRos2Entity destruction order (use-after-free regression).
# Links QtRos2Core and uses its private headers, so in-tree (developer) builds only,
# matching the other C++ tests. No rclcpp context is created (nodes are never
# componentComplete()'d), so it needs no ROS runtime.
if(QT_BUILDING_QT)
    qt_internal_add_test(tst_nodelifecycle
        SOURCES
            tst_nodelifecycle.cpp
        LIBRARIES
            Qt::Ros2CorePrivate
    )
endif()
