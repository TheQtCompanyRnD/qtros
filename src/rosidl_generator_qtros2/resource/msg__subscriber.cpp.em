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
from rosidl_generator_qtros2.template_helpers import build_message_context

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
ros_msg_type = context['ros_msg_type']
ros_include = context['ros_include']
header_file = context['header_file']
}@
#include "@(header_file)_subscriber.hpp"
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // rclcpp::Subscription
#include <QDebug>
#include <QMetaObject>
#include <exception>

namespace @(qt_namespace) {

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
