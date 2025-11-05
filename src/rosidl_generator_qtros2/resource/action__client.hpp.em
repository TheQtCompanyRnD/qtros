// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt action client header
@{
from rosidl_generator_qtros2 import get_qt_class_name, get_qt_class_name_full, get_qt_namespace, get_single_field_include, to_snake_case
from rosidl_generator_qtros2.template_helpers import build_include_guard

qt_namespace = get_qt_namespace(package_name)
action_name = action.namespaced_type.name
base_name = to_snake_case(action_name)
qt_class_name = get_qt_class_name(package_name, action_name)

# Get goal/result/feedback messages
goal_msg = action.goal
result_msg = action.result
feedback_msg = action.feedback

# Check if wrappers needed
goal_needs_wrap = needs_wrapper_type(goal_msg)
result_needs_wrap = needs_wrapper_type(result_msg)
feedback_needs_wrap = needs_wrapper_type(feedback_msg)

# Compute types and includes for goal
if goal_needs_wrap:
    goal_class = get_qt_class_name(package_name, goal_msg.structure.namespaced_type.name)
    goal_class_full = get_qt_class_name_full(package_name, goal_msg.structure.namespaced_type.name)
    goal_include = f'"{to_snake_case(goal_msg.structure.namespaced_type.name)}.hpp"'
    goal_param = 'const ' + goal_class_full + '& goal'
else:
    goal_class = get_single_field_type(goal_msg, package_name)
    goal_class_full = goal_class
    goal_field_info = get_single_field_include(goal_msg, package_name)
    if goal_field_info:
        pkg, msg_name, is_cross = goal_field_info
        if is_cross:
            goal_include = f'<qtros2_{pkg}/msg/{to_snake_case(msg_name)}.hpp>'
        else:
            goal_include = f'"{to_snake_case(msg_name)}.hpp"'
    else:
        goal_include = None

    if goal_class != 'void':
        goal_param = goal_class + ' goal'
    else:
        goal_param = ''

# Compute types and includes for result
if result_needs_wrap:
    result_class = get_qt_class_name(package_name, result_msg.structure.namespaced_type.name)
    result_class_full = get_qt_class_name_full(package_name, result_msg.structure.namespaced_type.name)
    result_include = f'"{to_snake_case(result_msg.structure.namespaced_type.name)}.hpp"'
else:
    result_class = get_single_field_type(result_msg, package_name)
    result_class_full = result_class
    result_field_info = get_single_field_include(result_msg, package_name)
    if result_field_info:
        pkg, msg_name, is_cross = result_field_info
        if is_cross:
            result_include = f'<qtros2_{pkg}/msg/{to_snake_case(msg_name)}.hpp>'
        else:
            result_include = f'"{to_snake_case(msg_name)}.hpp"'
    else:
        result_include = None

# Compute types and includes for feedback
if feedback_needs_wrap:
    feedback_class = get_qt_class_name(package_name, feedback_msg.structure.namespaced_type.name)
    feedback_class_full = get_qt_class_name_full(package_name, feedback_msg.structure.namespaced_type.name)
    feedback_include = f'"{to_snake_case(feedback_msg.structure.namespaced_type.name)}.hpp"'
else:
    feedback_class = get_single_field_type(feedback_msg, package_name)
    feedback_class_full = feedback_class
    feedback_field_info = get_single_field_include(feedback_msg, package_name)
    if feedback_field_info:
        pkg, msg_name, is_cross = feedback_field_info
        if is_cross:
            feedback_include = f'<qtros2_{pkg}/msg/{to_snake_case(msg_name)}.hpp>'
        else:
            feedback_include = f'"{to_snake_case(msg_name)}.hpp"'
    else:
        feedback_include = None

# ROS action type
ns_list = action.namespaced_type.namespaces
name_list = ns_list + [action.namespaced_type.name]
ros_action_type = '::'.join(name_list)
ros_include = ros_action_include if 'ros_action_include' in locals() and ros_action_include else package_name + '/action/' + to_snake_case(action_name) + '.hpp'
header_guard = build_include_guard(package_name, 'action', base_name + '_action_client')
}@
#ifndef @(header_guard)
#define @(header_guard)

#include <qtros2_core/qros2_action_client_base.hpp>
@[if goal_include]@
#include @(goal_include)
@[end if]@
@[if result_include]@
#include @(result_include)
@[end if]@
@[if feedback_include]@
#include @(feedback_include)
@[end if]@
#include <@(ros_include)>
#include <rclcpp_action/rclcpp_action.hpp>
#include <QFuture>
#include <QTimer>
#include <QJSValue>
#include <memory>

namespace @(qt_namespace) {

class @(qt_class_name)ActionClient : public QRos2ActionClientBase
{
    Q_OBJECT
    QML_ELEMENT

@[if feedback_class != 'void']@
    Q_PROPERTY(@(feedback_class_full) feedback READ feedback NOTIFY feedbackChanged)
@[end if]@

public:
    explicit @(qt_class_name)ActionClient(QObject* parent = nullptr);

@[if feedback_class != 'void']@
    @(feedback_class_full) feedback() const { return m_feedback; }
@[end if]@

#ifdef QTROS2_EXPERIMENTAL_FUTURE
@[if result_class == 'void']@
    Q_INVOKABLE QFuture<void> sendGoal(@(goal_param));
@[else]@
    Q_INVOKABLE QFuture<@(result_class_full)> sendGoal(@(goal_param));
@[end if]@
#else
    Q_INVOKABLE QJSValue sendGoal(@(goal_param));
#endif

Q_SIGNALS:
@[if feedback_class != 'void']@
    void feedbackChanged(@(feedback_class_full) feedback);
@[else]@
    void feedbackChanged();
@[end if]@

protected:
    void setupConnection() override;
    void checkHealth() override;
    void clearConnection() override;

public slots:
    void cancelGoal() override;

private:
    rclcpp_action::Client<@(ros_action_type)>::SharedPtr m_client;
    rclcpp_action::ClientGoalHandle<@(ros_action_type)>::SharedPtr m_goalHandle;

@[if feedback_class != 'void']@
    @(feedback_class_full) m_feedback{};
@[end if]@

@[if result_class == 'void']@
@[  if goal_param]@
    QFuture<void> sendGoalFuture(@(goal_param), const std::shared_ptr<QString>& lastError = nullptr);
@[  else]@
    QFuture<void> sendGoalFuture(const std::shared_ptr<QString>& lastError = nullptr);
@[  end if]@
@[else]@
@[  if goal_param]@
    QFuture<@(result_class_full)> sendGoalFuture(@(goal_param), const std::shared_ptr<QString>& lastError = nullptr);
@[  else]@
    QFuture<@(result_class_full)> sendGoalFuture(const std::shared_ptr<QString>& lastError = nullptr);
@[  end if]@
@[end if]@
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
