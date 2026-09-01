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
    build_field_props_for_pubsub,
    build_include_guard,
    build_message_context,
    build_single_field_info,
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
sf = build_single_field_info(package_name, message)
fps = build_field_props_for_pubsub(package_name, message)
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
@[if sf]@
@[  if sf['extra_inc'] and not sf['extra_inc'].endswith('.hpp')]@
#include @(sf['extra_inc'])
@[  elif sf['extra_inc']]@
#include "@(sf['extra_inc'])"
@[  end if]@
@[else]@
#include "@(value_type_include)"
@[end if]@
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

@[if fps]@
@[  for fp in fps]@
    Q_PROPERTY(@(fp['qt_type']) @(fp['prop_name']) READ @(fp['prop_name']) NOTIFY @(fp['signal_name']))
@[  end for]@
@[end if]@
@[if sf]@
    Q_PROPERTY(@(sf['qt_type']) message READ message NOTIFY messageReceived)
@[else]@
    Q_PROPERTY(@(qt_class_name_full) message READ message NOTIFY messageReceived)
@[end if]@

public:
    explicit @(qt_class_name)Subscriber(QObject* parent = nullptr);

@[if fps]@
@[  for fp in fps]@
    @(fp['qt_type']) @(fp['prop_name'])() const { return @(fp['getter_expr']); }
@[  end for]@
@[end if]@
    /*!
     * @@brief Get the last received message
     * @@return The last message received
     */
@[if sf]@
    @(sf['qt_type']) message() const { return m_message; }
@[else]@
    @(qt_class_name_full) message() const { return m_message; }
@[end if]@

    void setupConnection() override;
    void clearConnection() override;

Q_SIGNALS:
@[if fps]@
@[  for fp in fps]@
    void @(fp['signal_name'])(@(fp['param_decl']));
@[  end for]@
@[end if]@
    /*!
     * @@brief Emitted when a new message is received
     * @@param msg The received message
     */
@[if sf]@
    void messageReceived(@(sf['param_decl']));
@[else]@
    void messageReceived(const @(qt_class_name_full)& msg);
@[end if]@

protected:
    void checkHealth() override;

private:
@[if sf]@
    @(sf['qt_type']) m_message;
@[else]@
    @(qt_class_name_full) m_message;
@[end if]@
#ifndef Q_QDOC
    void handleMessage(const @(ros_msg_type)::SharedPtr msg);
    rclcpp::Subscription<@(ros_msg_type)>::SharedPtr m_subscription;
#endif
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
