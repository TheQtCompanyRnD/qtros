# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Native TF runtime: wraps tf2_ros broadcasters/listener so QML apps don't have
# to hand-roll transform publishing and lookup. Distinct from QtRos2.Tf2Msgs
# (the wire types). Depends on QtRos2.Core (node/entity plumbing) and the
# geometry value types (TransformStamped).
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

qt_internal_add_module(Ros2Transforms
    EXCEPTIONS
    SOURCES
        qros2transformbroadcaster_p.h qros2transformbroadcaster.cpp
        qros2statictransformbroadcaster_p.h qros2statictransformbroadcaster.cpp
        qros2frametransformer_p.h qros2frametransformer.cpp
    LIBRARIES
        Qt::Qml
        # Ros2CorePrivate gives the private node/entity headers (qros2entity_p.h).
        # Private, not public: every header this module has is a _p.h, so no
        # consumer includes them, and Qt rejects a public link to a private
        # module anyway.
        Qt6::Ros2CorePrivate
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Qml
        # Declared here rather than in the target_link_libraries() below so that
        # qt_internal_add_module records it as a package dependency: a Qt target
        # only linked afterwards lands in INTERFACE_LINK_LIBRARIES, and then
        # Qt6Ros2TransformsConfig.cmake references an imported target its own
        # Dependencies.cmake never asked anyone to find.
        Qt6::QtRos2GeometryMessages
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

# The ROS packages are found through FindWrapRos2 rather than as Qt packages,
# so they stay here; the Qt ones are declared above.
target_link_libraries(Ros2Transforms PUBLIC
    rclcpp::rclcpp
    tf2::tf2
    tf2_ros::tf2_ros
    tf2_geometry_msgs::tf2_geometry_msgs
)
