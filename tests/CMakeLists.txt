# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

if(QT_BUILD_STANDALONE_TESTS)
    # WrapRos2 finds rclcpp and related ROS2 targets, which Qt6::Ros2Core's
    # link interface depends on. It must be found before Qt6::Ros2Core is
    # imported by qt_internal_find_standalone_parts_qt_packages.
    find_package(WrapRos2 QUIET)
endif()
qt_build_tests()
