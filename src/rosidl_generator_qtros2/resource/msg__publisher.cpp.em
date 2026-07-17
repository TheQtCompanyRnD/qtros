// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt publisher class implementation
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
    build_message_context,
    build_single_field_info,
    extract_doc_info,
)

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
qt_class_name_full = context['qt_class_name_full']
qml_value_type_name = context['qml_value_type_name']
qml_module_uri = context['qml_module_uri']
ros_msg_type = context['ros_msg_type']
ros_include = context['ros_include']
header_file = context['header_file']
message_has_header = context['message_has_header']
publisher_base = context['publisher_base']
sf = build_single_field_info(package_name, message)
fps = build_field_props_for_pubsub(package_name, message)
doc_info = extract_doc_info(message, interface_path=interface_path)
msg_brief = doc_info['brief']
msg_brief_continuation = doc_info['brief_continuation']
msg_details = doc_info['details']
deprecated = doc_info['deprecated']
deprecated_since = doc_info['deprecated_since']
deprecated_tag = ('[' + deprecated_since + '] ') if deprecated_since else ''
}@
#include "@(header_file)_publisher.hpp"
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // rclcpp::Publisher
#include <QDebug>

namespace @(qt_namespace) {

/*!
    \qmltype @(qt_class_name)Publisher
    \inqmlmodule @(qml_module_uri)
    \inherits PublisherBase
@[if msg_brief]@
    \brief Publishes \c @(ros_msg_type) messages — @(msg_brief)
@[for line in msg_brief_continuation]@
    @(line)
@[end for]@
@[else]@
    \brief Publishes \c @(ros_msg_type) messages to a ROS 2 topic.
@[end if]@
@[if deprecated]@
    \deprecated @(deprecated_tag)
@[end if]@

@[for line in msg_details]@
    @(line)
@[end for]@
@[if msg_details]@

@[end if]@
@[if sf]@
    @(qt_class_name)Publisher publishes @(sf['qml_doc_type']) values to a ROS 2 topic.
@[else]@
    @(qt_class_name)Publisher publishes \l @(qml_value_type_name) values to a ROS 2 topic.
@[end if]@
    Set the \c topic and \c node properties, then call \c publish() to send messages.
@[if sf and sf['prop_name']]@
    Alternatively, bind the \l @(sf['prop_name']) property to publish
    automatically whenever the bound value changes.
@[end if]@

@[if sf]@
    \sa @(qt_class_name)Subscriber
@[else]@
    \sa @(qt_class_name)Subscriber, @(qml_value_type_name)
@[end if]@
*/

/*!
@[if sf]@
    \qmlmethod void @(qt_class_name)Publisher::publish(@(sf['qml_doc_type']) @(sf['field_name']))

    Publishes \a @(sf['field_name']) to the ROS 2 topic set by the \l topic property.
@[else]@
    \qmlmethod void @(qt_class_name)Publisher::publish(@(qml_value_type_name) msg)

    Publishes \l @(qml_value_type_name) \a msg to the ROS 2 topic set by the \l topic property.
@[end if]@
    Does nothing if the publisher is not connected.
*/

@[if fps]@
@[  for fp in fps]@
/*!
    \qmlproperty @(fp['qml_doc_type']) @(qt_class_name)Publisher::@(fp['prop_name'])

    The \c @(fp['prop_name']) field value included in the next publish.
    Setting this property emits \l @(fp['signal_name']) and, when
    \l {PublisherBase::autoPublish}{autoPublish} is \c true, requests a
    publish at the end of the current event-loop iteration.
*/

@[  end for]@
@[end if]@
@[if sf and sf['prop_name']]@
/*!
    \qmlproperty @(sf['qml_doc_type']) @(qt_class_name)Publisher::@(sf['prop_name'])

    The @(sf['qml_doc_type']) value included in the next publish.
    Setting this property emits \l @(sf['signal_name']) and, when
    \l {PublisherBase::autoPublish}{autoPublish} is \c true, requests a
    publish at the end of the current event-loop iteration.
*/

@[end if]@
@(qt_class_name)Publisher::@(qt_class_name)Publisher(QObject* parent)
    : @(publisher_base)(parent)
{
}

@[if fps]@
void @(qt_class_name)Publisher::publishStoredState()
{
    if (!m_publisher) {
        return;
    }

    auto ros_msg = static_cast<@(ros_msg_type)>(m_message);
@[if message_has_header]@
    applyAutoStamp(ros_msg.header.stamp);
@[end if]@
    m_publisher->publish(ros_msg);
}

@[  for fp in fps]@
void @(qt_class_name)Publisher::@(fp['setter_name'])(@(fp['param_decl']))
{
    if (m_message.@(fp['prop_name'])() == @(fp['prop_name'])) {
        return;
    }
    m_message.@(fp['setter_name'])(@(fp['prop_name']));
    emit @(fp['signal_name'])(@(fp['getter_expr']));
    requestPublish();
}

@[  end for]@
@[end if]@
@[if sf and sf['prop_name']]@
void @(qt_class_name)Publisher::publishStoredState()
{
    if (!m_publisher) {
        return;
    }

    @(ros_msg_type) ros_msg;
    const auto& @(sf['field_name']) = @(sf['member_name']);
    @(sf['qt_to_ros'])
    m_publisher->publish(ros_msg);
}

void @(qt_class_name)Publisher::@(sf['setter_name'])(@(sf['param_decl']))
{
    if (@(sf['member_name']) == @(sf['field_name'])) {
        return;
    }
    @(sf['member_name']) = @(sf['field_name']);
    emit @(sf['signal_name'])(@(sf['member_name']));
    requestPublish();
}

@[end if]@
@[if sf]@
void @(qt_class_name)Publisher::publish(@(sf['param_decl']))
{
    if (!m_publisher) {
        return;
    }

    @(ros_msg_type) ros_msg;
    @(sf['qt_to_ros'])
    m_publisher->publish(ros_msg);
}
@[else]@
void @(qt_class_name)Publisher::publish(const @(qt_class_name_full)& msg)
{
    if (!m_publisher) {
        return;
    }

    auto ros_msg = static_cast<@(ros_msg_type)>(msg);
@[if message_has_header]@
    applyAutoStamp(ros_msg.header.stamp);
@[end if]@
    m_publisher->publish(ros_msg);
}
@[end if]@

void @(qt_class_name)Publisher::setupConnection()
{
    // Clear existing connection before creating a new one
    if (m_publisher) {
        m_publisher.reset();
    }

    if (!node() || !node()->rosNode()) {
        return;
    }

    if (topic().isEmpty()) {
        return;
    }

    m_publisher = node()->rosNode()->create_publisher<@(ros_msg_type)>(
        topic().toStdString(),
        qos()
    );
}

void @(qt_class_name)Publisher::clearConnection()
{
    m_publisher.reset();
}

void @(qt_class_name)Publisher::checkHealth()
{
    int count = 0;
    if (m_publisher) {
        try {
            count = m_publisher->get_subscription_count();
        } catch (const std::exception&) {
        }
    }
    if (count != subscriberCount()) {
                setSubscriberCount(count);
    }
}

} // namespace @(qt_namespace)
