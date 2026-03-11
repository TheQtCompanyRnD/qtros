// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt publisher class header
@# ===================================================
@#
@# Template arguments:
@# - package_name
@# - interface_path
@# - message
@# - spec
@{
from rosidl_generator_qtros2.template_helpers import (
    build_include_guard,
    build_message_context,
)

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
qt_class_name_full = context['qt_class_name_full']
ros_msg_type = context['ros_msg_type']
ros_include = context['ros_include']
value_type_include = context['value_type_include']
header_guard = build_include_guard(package_name, 'msg', context['header_file'] + '_publisher')
qt_export_macro = f'Q_{qt_module_name.upper()}_EXPORT'
qt_build_define = f'QT_BUILD_{qt_module_name.upper()}_LIB'
}@
#ifndef @(header_guard)
#define @(header_guard)

#include <QtCore/qglobal.h>
#if defined(@(qt_build_define))
#  define @(qt_export_macro) Q_DECL_EXPORT
#else
#  define @(qt_export_macro) Q_DECL_IMPORT
#endif

#include <QtRos2Core/private/qros2publisherbase_p.h>
#include "@(value_type_include)"
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // for rclcpp::Publisher

namespace @(qt_namespace) {

/**
 * @@brief Qt publisher for @(ros_msg_type)
 *
 * Publishes @(qt_class_name) messages to a ROS 2 topic.
 * Can be used directly in QML.
 */
class @(qt_export_macro) @(qt_class_name)Publisher : public QRos2PublisherBase
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit @(qt_class_name)Publisher(QObject* parent = nullptr);

    /**
     * @@brief Publish a message
     * @@param msg The message to publish
     */
    Q_INVOKABLE void publish(const @(qt_class_name_full)& msg);

protected:
    void setupConnection() override;
    void clearConnection() override;
    void checkHealth() override;

private:
    rclcpp::Publisher<@(ros_msg_type)>::SharedPtr m_publisher;
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
