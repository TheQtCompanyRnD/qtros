# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Qt Quick 3D integration: scene-graph types that follow ROS data, starting
# with FrameNode, which places a Node at a TF frame. Kept apart from
# QtRos2.Transforms so that non-3D apps don't depend on Qt Quick 3D.
# FrameNode subclasses QQuick3DNode, which is private API.

# Ros2Transforms' link interface names the tf2 imported targets (and through
# tf2_geometry_msgs, orocos-kdl). Imported targets are directory-scoped, so
# find them here too, or this module's .prl generation can't resolve them.
find_package(tf2 REQUIRED)
find_package(tf2_ros REQUIRED)
find_package(tf2_geometry_msgs REQUIRED)

qt_internal_add_module(Ros2Quick3D
    EXCEPTIONS
    SOURCES
        qros2framenode_p.h qros2framenode.cpp
    LIBRARIES
        Qt6::Ros2CorePrivate
        Qt6::Ros2TransformsPrivate
    PUBLIC_LIBRARIES
        Qt::Core
        Qt::Gui
        Qt::Qml
        Qt::Quick3D
        Qt::Quick3DPrivate
        Qt6::Ros2Transforms
)

qt_internal_add_qml_module(Ros2Quick3D
    URI "QtRos2.Quick3D"
    VERSION "${PROJECT_VERSION}"
    DESIGNER_SUPPORTED
    DEPENDENCIES
        QtQuick3D/auto
        QtRos2.Core/auto
        QtRos2.Transforms/auto
    CLASS_NAME Ros2Quick3DPlugin
    PLUGIN_TARGET ros2quick3dplugin
    NO_PLUGIN_OPTIONAL
)
