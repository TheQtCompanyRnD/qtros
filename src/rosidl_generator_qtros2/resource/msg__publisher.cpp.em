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
    build_message_context,
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
doc_info = extract_doc_info(message)
msg_brief = doc_info['brief']
msg_details = doc_info['details']
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
@[else]@
    \brief Publishes \c @(ros_msg_type) messages to a ROS 2 topic.
@[end if]@

@[for line in msg_details]@
    @(line)
@[end for]@
@[if msg_details]@

@[end if]@
    @(qt_class_name)Publisher publishes \l @(qml_value_type_name) values to a ROS 2 topic.
    Set the \c topic and \c node properties, then call \c publish() to send messages.

    \sa @(qt_class_name)Subscriber, @(qml_value_type_name)
*/

/*!
    \qmlmethod void @(qt_class_name)Publisher::publish(@(qml_value_type_name) msg)

    Publishes \l @(qml_value_type_name) \a msg to the ROS 2 topic set by the \l topic property.
    Does nothing if the publisher is not connected.
*/

@(qt_class_name)Publisher::@(qt_class_name)Publisher(QObject* parent)
    : QRos2PublisherBase(parent)
{
}

void @(qt_class_name)Publisher::publish(const @(qt_class_name_full)& msg)
{
    if (!m_publisher) {
        return;
    }

    auto ros_msg = static_cast<@(ros_msg_type)>(msg);
    m_publisher->publish(ros_msg);
}

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
