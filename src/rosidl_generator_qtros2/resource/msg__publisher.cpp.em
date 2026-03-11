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
from rosidl_generator_qtros2.template_helpers import build_message_context

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
qt_class_name_full = context['qt_class_name_full']
ros_msg_type = context['ros_msg_type']
ros_include = context['ros_include']
header_file = context['header_file']
}@
#include "@(header_file)_publisher.hpp"
#include <@(ros_include)>  // ROS message type
#include <rclcpp/rclcpp.hpp>  // rclcpp::Publisher
#include <QDebug>

namespace @(qt_namespace) {

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
