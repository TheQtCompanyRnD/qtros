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
message_has_header = context['message_has_header']
publisher_base = context['publisher_base']
header_guard = build_include_guard(package_name, 'msg', context['header_file'] + '_publisher')
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

#include <QtRos2Core/private/qros2publisherbase_p.h>
@[if message_has_header]@
#include <QtRos2Core/private/qros2stampedpublisherbase_p.h>
@[end if]@
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
#include <rclcpp/rclcpp.hpp>  // for rclcpp::Publisher
#endif

namespace @(qt_namespace) {

/*!
 * @@brief Qt publisher for @(ros_msg_type)
 *
 * Publishes @(qt_class_name) messages to a ROS 2 topic.
 * Can be used directly in QML.
 */
class @(qt_export_macro) @(qt_class_name)Publisher : public @(publisher_base)
{
    Q_OBJECT
    QML_ELEMENT

@[if fps]@
@[  for fp in fps]@
    Q_PROPERTY(@(fp['qt_type']) @(fp['prop_name']) READ @(fp['prop_name']) WRITE @(fp['setter_name']) NOTIFY @(fp['signal_name']))
@[  end for]@
@[end if]@
@[if sf and sf['prop_name']]@
    Q_PROPERTY(@(sf['qt_type']) @(sf['prop_name']) READ @(sf['prop_name']) WRITE @(sf['setter_name']) NOTIFY @(sf['signal_name']))
@[end if]@

public:
    explicit @(qt_class_name)Publisher(QObject* parent = nullptr);

@[if fps]@
@[  for fp in fps]@
    @(fp['qt_type']) @(fp['prop_name'])() const { return @(fp['getter_expr']); }
@[  end for]@
    using QRos2PublisherBase::publish;
@[end if]@
@[if sf and sf['prop_name']]@
    @(sf['qt_type']) @(sf['prop_name'])() const { return @(sf['member_name']); }
    using QRos2PublisherBase::publish;
@[end if]@
    /*!
     * @@brief Publish a message
     * @@param msg The message to publish
     */
@[if sf]@
    Q_INVOKABLE void publish(@(sf['param_decl']));
@[else]@
    Q_INVOKABLE void publish(const @(qt_class_name_full)& msg);
@[end if]@

@[if fps]@
public Q_SLOTS:
@[  for fp in fps]@
    void @(fp['setter_name'])(@(fp['param_decl']));
@[  end for]@

@[end if]@
@[if sf and sf['prop_name']]@
public Q_SLOTS:
    void @(sf['setter_name'])(@(sf['param_decl']));

@[end if]@
@[if fps]@
Q_SIGNALS:
@[  for fp in fps]@
    void @(fp['signal_name'])(@(fp['param_decl']));
@[  end for]@

@[end if]@
@[if sf and sf['prop_name']]@
Q_SIGNALS:
    void @(sf['signal_name'])(@(sf['param_decl']));

@[end if]@
protected:
    void setupConnection() override;
    void clearConnection() override;
    void checkHealth() override;
@[if fps or (sf and sf['prop_name'])]@
    void publishStoredState() override;
@[end if]@

private:
@[if fps]@
    @(qt_class_name_full) m_message;
@[end if]@
@[if sf and sf['prop_name']]@
    @(sf['qt_type']) @(sf['member_name']){};
@[end if]@
#ifndef Q_QDOC
    rclcpp::Publisher<@(ros_msg_type)>::SharedPtr m_publisher;
#endif
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
