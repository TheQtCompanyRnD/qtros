# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Native TF runtime: wraps tf2_ros broadcasters/listener so QML apps don't have
# to hand-roll transform publishing and lookup. Distinct from QtRos2.Tf2Msgs
# (the wire types). Depends on QtRos2.Core (node/entity plumbing) and the
# geometry value types (TransformStamped).
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)

qt_internal_add_module(Ros2Transforms
    EXCEPTIONS
    SOURCES
        qros2transformbroadcaster_p.h qros2transformbroadcaster.cpp
        qros2statictransformbroadcaster_p.h qros2statictransformbroadcaster.cpp
        qros2frametransformer_p.h qros2frametransformer.cpp
    LIBRARIES
        Qt::Qml
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Qml
)

qt_internal_add_qml_module(Ros2Transforms
    URI "QtRos2.Transforms"
    VERSION "${PROJECT_VERSION}"
    DESIGNER_SUPPORTED
    DEPENDENCIES
        QtQuick/auto
        QtRos2.Core/auto
        QtRos2.GeometryMsgs/auto
    CLASS_NAME Ros2TransformsPlugin
    PLUGIN_TARGET ros2transformsplugin
    NO_PLUGIN_OPTIONAL
)

# Ros2CorePrivate gives the private node/entity headers (qros2entity_p.h etc.);
# plus the geometry value-type module and tf2_ros.
target_link_libraries(Ros2Transforms PUBLIC
    Qt6::Ros2CorePrivate
    QtRos2GeometryMessages
    rclcpp::rclcpp
    tf2::tf2
    tf2_ros::tf2_ros
)
