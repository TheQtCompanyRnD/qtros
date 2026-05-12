// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt subscriber class implementation
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
#include "@(header_file)_subscriber.hpp"
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // rclcpp::Subscription
#include <QDebug>
#include <QMetaObject>
#include <exception>

namespace @(qt_namespace) {

/*!
    \qmltype @(qt_class_name)Subscriber
    \inqmlmodule @(qml_module_uri)
    \inherits SubscriberBase
@[if msg_brief]@
    \brief Subscribes to \c @(ros_msg_type) messages — @(msg_brief)
@[else]@
    \brief Subscribes to \c @(ros_msg_type) messages from a ROS 2 topic.
@[end if]@

@[for line in msg_details]@
    @(line)
@[end for]@
@[if msg_details]@

@[end if]@
    @(qt_class_name)Subscriber receives \l @(qml_value_type_name) values from a ROS 2 topic.
    Set the \c topic and \c node properties, then connect to the \c messageReceived() signal.

    \sa @(qt_class_name)Publisher, @(qml_value_type_name)
*/

/*!
    \qmlproperty @(qml_value_type_name) @(qt_class_name)Subscriber::message

    The last message received on \l topic. Updated whenever a new message arrives.
*/

/*!
    \qmlsignal @(qt_class_name)Subscriber::messageReceived(@(qml_value_type_name) msg)

    Emitted when a new message arrives on \l topic. \a msg contains the received message.
*/

@(qt_class_name)Subscriber::@(qt_class_name)Subscriber(QObject* parent)
    : QRos2SubscriberBase(parent)
{
}

void @(qt_class_name)Subscriber::setupConnection()
{
    // Clear existing connection before creating a new one
    if (m_subscription) {
        m_subscription.reset();
        setConnected(false);
    }

    if (!node() || !node()->rosNode()) {
        return;
    }

    if (topic().isEmpty()) {
        return;
    }

    m_subscription = node()->rosNode()->create_subscription<@(ros_msg_type)>(
        topic().toStdString(),
        qos(),
        [this](const @(ros_msg_type)::SharedPtr msg) {
            QMetaObject::invokeMethod(
                this,
                [this, msg]() {
                    handleMessage(msg);
                },
                Qt::QueuedConnection
            );
        }
    );
}

void @(qt_class_name)Subscriber::clearConnection()
{
    m_subscription.reset();
    setConnected(false);
}

void @(qt_class_name)Subscriber::checkHealth()
{
    bool is_connected = false;

    if (m_subscription) {
        try {
            is_connected = m_subscription->get_publisher_count() > 0;
        } catch (const std::exception&) {
            is_connected = false;
        }
    }

    if (is_connected != connected()) {
        setConnected(is_connected);
    }
}

void @(qt_class_name)Subscriber::handleMessage(const @(ros_msg_type)::SharedPtr msg)
{
    // Convert ROS message to Qt type (implicit conversion)
    m_message = *msg;

    // Emit signal for QML
    emit messageReceived(m_message);
}

} // namespace @(qt_namespace)
