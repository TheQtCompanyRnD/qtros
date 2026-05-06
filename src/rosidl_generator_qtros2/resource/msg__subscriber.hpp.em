// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt subscriber class header
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
header_guard = build_include_guard(package_name, 'msg', context['header_file'] + '_subscriber')
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

#include <QtRos2Core/private/qros2subscriberbase_p.h>
#include "@(value_type_include)"
#ifndef Q_QDOC
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // for rclcpp::Subscription
#endif

namespace @(qt_namespace) {

/*!
 * @@brief Qt subscriber for @(ros_msg_type)
 *
 * Subscribes to @(qt_class_name) messages from a ROS 2 topic.
 * Can be used directly in QML with property bindings.
 */
class @(qt_export_macro) @(qt_class_name)Subscriber : public QRos2SubscriberBase
{
    Q_OBJECT
    QML_ELEMENT

    Q_PROPERTY(@(qt_class_name_full) message READ message NOTIFY messageReceived)

public:
    explicit @(qt_class_name)Subscriber(QObject* parent = nullptr);

    /*!
     * @@brief Get the last received message
     * @@return The last message received
     */
    @(qt_class_name_full) message() const { return m_message; }

    void setupConnection() override;
    void clearConnection() override;

Q_SIGNALS:
    /*!
     * @@brief Emitted when a new message is received
     * @@param msg The received message
     */
    void messageReceived(const @(qt_class_name_full)& msg);

protected:
    void checkHealth() override;

private:
    @(qt_class_name_full) m_message;
#ifndef Q_QDOC
    void handleMessage(const @(ros_msg_type)::SharedPtr msg);
    rclcpp::Subscription<@(ros_msg_type)>::SharedPtr m_subscription;
#endif
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
