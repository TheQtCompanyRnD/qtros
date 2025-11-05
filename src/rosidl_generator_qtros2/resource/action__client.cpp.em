// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt action client implementation
@{
from rosidl_generator_qtros2 import (
    get_qt_class_name,
    get_qt_class_name_full,
    get_qt_namespace,
    msg_type_to_qt,
    msg_type_to_cpp,
    to_snake_case,
)
from rosidl_parser.definition import (
    NamespacedType,
    AbstractNestedType,
    Array,
    BoundedSequence,
    UnboundedSequence,
    AbstractString,
    AbstractWString,
)

qt_namespace = get_qt_namespace(package_name)
action_name = action.namespaced_type.name
qt_class_name = get_qt_class_name(package_name, action_name)

# ROS action type
ns_list = action.namespaced_type.namespaces
name_list = ns_list + [action.namespaced_type.name]
ros_action_type = '::'.join(name_list)

# Get goal/result/feedback messages
goal_msg = action.goal
result_msg = action.result
feedback_msg = action.feedback

# Check if wrappers needed
goal_needs_wrap = needs_wrapper_type(goal_msg)
result_needs_wrap = needs_wrapper_type(result_msg)
feedback_needs_wrap = needs_wrapper_type(feedback_msg)

# Compute types
if goal_needs_wrap:
    goal_class = get_qt_class_name(package_name, goal_msg.structure.namespaced_type.name)
    goal_class_full = get_qt_class_name_full(package_name, goal_msg.structure.namespaced_type.name)
    goal_param = 'const ' + goal_class_full + '& goal'
else:
    goal_class = get_single_field_type(goal_msg, package_name)
    goal_class_full = goal_class
    if goal_class != 'void':
        goal_param = goal_class + ' goal'
    else:
        goal_param = ''

if result_needs_wrap:
    result_class = get_qt_class_name(package_name, result_msg.structure.namespaced_type.name)
    result_class_full = get_qt_class_name_full(package_name, result_msg.structure.namespaced_type.name)
else:
    result_class = get_single_field_type(result_msg, package_name)
    result_class_full = result_class

if feedback_needs_wrap:
    feedback_class = get_qt_class_name(package_name, feedback_msg.structure.namespaced_type.name)
    feedback_class_full = get_qt_class_name_full(package_name, feedback_msg.structure.namespaced_type.name)
else:
    feedback_class = get_single_field_type(feedback_msg, package_name)
    feedback_class_full = feedback_class

# Get members for conversion
goal_members = []
if hasattr(goal_msg, 'structure') and hasattr(goal_msg.structure, 'members'):
    goal_members = [m for m in goal_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

result_members = []
if hasattr(result_msg, 'structure') and hasattr(result_msg.structure, 'members'):
    result_members = [m for m in result_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

feedback_members = []
if hasattr(feedback_msg, 'structure') and hasattr(feedback_msg.structure, 'members'):
    feedback_members = [m for m in feedback_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

def _qtros2_member_traits(member):
    if member is None:
        return None
    traits = {}
    field_type = member.type
    traits['qt_type'] = msg_type_to_qt(field_type)
    traits['cpp_type'] = msg_type_to_cpp(field_type)
    base_type = field_type
    if isinstance(base_type, AbstractNestedType):
        base_type = base_type.value_type
    traits['is_nested'] = isinstance(base_type, NamespacedType)
    traits['nested_ros_type'] = '::'.join(base_type.namespaces + [base_type.name]) if traits['is_nested'] else None
    traits['is_string'] = isinstance(base_type, AbstractString)
    traits['is_wstring'] = isinstance(base_type, AbstractWString)
    traits['is_array'] = isinstance(field_type, Array)
    traits['is_bounded_sequence'] = isinstance(field_type, BoundedSequence)
    traits['is_unbounded_sequence'] = isinstance(field_type, UnboundedSequence)
    traits['is_sequence_like'] = traits['is_array'] or traits['is_bounded_sequence'] or traits['is_unbounded_sequence']
    seq_inner_type = field_type.value_type if traits['is_sequence_like'] else None
    if isinstance(seq_inner_type, AbstractNestedType):
        seq_inner_type = seq_inner_type.value_type
    traits['sequence_inner_type'] = seq_inner_type
    traits['sequence_inner_qt'] = msg_type_to_qt(seq_inner_type) if seq_inner_type else None
    traits['sequence_inner_cpp'] = msg_type_to_cpp(seq_inner_type) if seq_inner_type else None
    traits['sequence_inner_is_nested'] = isinstance(seq_inner_type, NamespacedType) if seq_inner_type else False
    traits['sequence_inner_is_string'] = isinstance(seq_inner_type, AbstractString) if seq_inner_type else False
    traits['sequence_inner_is_wstring'] = isinstance(seq_inner_type, AbstractWString) if seq_inner_type else False
    traits['is_qbytearray'] = traits['qt_type'] == 'QByteArray'
    traits['is_qstringlist'] = traits['qt_type'] == 'QStringList'
    traits['is_qlist'] = traits['qt_type'].startswith('QList<')
    return traits

goal_field = goal_members[0] if goal_members else None
goal_traits = _qtros2_member_traits(goal_field)
result_field = result_members[0] if result_members else None
result_traits = _qtros2_member_traits(result_field)
feedback_field = feedback_members[0] if feedback_members else None
feedback_traits = _qtros2_member_traits(feedback_field)

# ROS action type
ns_list = action.namespaced_type.namespaces
name_list = ns_list + [action.namespaced_type.name]
ros_action_type = '::'.join(name_list)
header_file = to_snake_case(action_name)
}@
#include "@(header_file)_action_client.hpp"
#include <qtros2_core/qros2_node.hpp>
#if !defined(QTROS2_EXPERIMENTAL_FUTURE)
#include <qtros2_core/js_future_wrapper.hpp>
#include <QQmlEngine>
#endif
#include <QCoreApplication>
#include <QByteArray>
#include <QDebug>
#include <QPointer>
#include <rcl_action/rcl_action.h>

namespace @(qt_namespace) {

@(qt_class_name)ActionClient::@(qt_class_name)ActionClient(QObject* parent)
    : QRos2ActionClientBase(parent)
{
}

void @(qt_class_name)ActionClient::setupConnection()
{
    // Clear existing connection before creating a new one
    if (m_client) {
        m_client.reset();
    }

    if (!node() || !node()->rosNode() || m_topic.isEmpty()) {
        return;
    }

    rcl_action_client_options_t options = rcl_action_client_get_default_options();
    const auto ros_qos = static_cast<rclcpp::QoS>(qos());
    const auto rmw_qos = ros_qos.get_rmw_qos_profile();
    options.goal_service_qos = rmw_qos;
    options.result_service_qos = rmw_qos;
    options.cancel_service_qos = rmw_qos;
    options.feedback_topic_qos = rmw_qos;
    options.status_topic_qos = rmw_qos;

    m_client = rclcpp_action::create_client<@(ros_action_type)>(
        node()->rosNode(),
        m_topic.toStdString(),
        nullptr,
        options);
}

void @(qt_class_name)ActionClient::checkHealth()
{
    if (!m_client) {
        setServerReady(false);
        return;
    }

    try {
        bool ready = m_client->action_server_is_ready();
        setServerReady(ready);
    } catch (const std::exception&) {
        setServerReady(false);
    }
}

void @(qt_class_name)ActionClient::clearConnection()
{
    m_client.reset();
}

@[if result_class == 'void']@
@[  if goal_param]@
QFuture<void> @(qt_class_name)ActionClient::sendGoalFuture(@(goal_param), const std::shared_ptr<QString>& lastError)
@[  else]@
QFuture<void> @(qt_class_name)ActionClient::sendGoalFuture(const std::shared_ptr<QString>& lastError)
@[  end if]@
@[else]@
@[  if goal_param]@
QFuture<@(result_class_full)> @(qt_class_name)ActionClient::sendGoalFuture(@(goal_param), const std::shared_ptr<QString>& lastError)
@[  else]@
QFuture<@(result_class_full)> @(qt_class_name)ActionClient::sendGoalFuture(const std::shared_ptr<QString>& lastError)
@[  end if]@
@[end if]@
{
    if (!m_client || !isServerReady()) {
@[if result_class == 'void']@
        return makeRejectedFuture<void>(QStringLiteral("Action server not available"));
@[else]@
        return makeRejectedFuture<@(result_class_full)>(QStringLiteral("Action server not available"));
@[end if]@
    }

@[if result_class == 'void']@
    auto promise = std::make_shared<QPromise<void>>();
@[else]@
    auto promise = std::make_shared<QPromise<@(result_class_full)>>();
@[end if]@
    auto future = promise->future();

    setState(ActionState::Requested);
@[if feedback_class != 'void']@
    m_feedback = @(feedback_class_full)();
    emit feedbackChanged(m_feedback);
@[end if]@

    auto goal_msg = @(ros_action_type)::Goal{};
@[if goal_needs_wrap]@
    goal_msg = static_cast<@(ros_action_type)::Goal>(goal);
@[elif goal_members]@
@{
field = goal_field
traits = goal_traits
}@
@[  if traits['is_qbytearray']]@
    goal_msg.@(field.name).assign(
        reinterpret_cast<const uint8_t*>(goal.constData()),
        reinterpret_cast<const uint8_t*>(goal.constData()) + goal.size()
    );
@[  elif traits['is_array']]@
    {
        const int goal_size = goal.size();
        const int ros_size = static_cast<int>(goal_msg.@(field.name).size());
        const int maxCount = (goal_size < ros_size) ? goal_size : ros_size;
        for (int idx = 0; idx < maxCount; ++idx) {
@[    if traits['sequence_inner_is_nested']]@
            goal_msg.@(field.name)[idx] = static_cast<@(traits['sequence_inner_cpp'])>(goal[idx]);
@[    elif traits['sequence_inner_is_string']]@
            goal_msg.@(field.name)[idx] = goal[idx].toStdString();
@[    elif traits['sequence_inner_is_wstring']]@
            goal_msg.@(field.name)[idx] = goal[idx].toStdWString();
@[    elif traits['sequence_inner_qt'] and traits['sequence_inner_qt'].startswith('Q') and not traits['sequence_inner_qt'].startswith('QList')]@
            goal_msg.@(field.name)[idx] = static_cast<@(traits['sequence_inner_cpp'])>(goal[idx]);
@[    else]@
            goal_msg.@(field.name)[idx] = goal[idx];
@[    end if]@
        }
        for (size_t idx = maxCount; idx < goal_msg.@(field.name).size(); ++idx) {
            goal_msg.@(field.name)[idx] = @(traits['sequence_inner_cpp'])();
        }
    }
@[  elif traits['is_sequence_like']]@
    goal_msg.@(field.name).clear();
    goal_msg.@(field.name).reserve(goal.size());
    for (const auto& value : goal) {
@[    if traits['sequence_inner_is_nested']]@
        goal_msg.@(field.name).push_back(static_cast<@(traits['sequence_inner_cpp'])>(value));
@[    elif traits['sequence_inner_is_string']]@
        goal_msg.@(field.name).push_back(value.toStdString());
@[    elif traits['sequence_inner_is_wstring']]@
        goal_msg.@(field.name).push_back(value.toStdWString());
@[    elif traits['sequence_inner_qt'] and traits['sequence_inner_qt'].startswith('Q') and not traits['sequence_inner_qt'].startswith('QList')]@
        goal_msg.@(field.name).push_back(static_cast<@(traits['sequence_inner_cpp'])>(value));
@[    else]@
        goal_msg.@(field.name).push_back(value);
@[    end if]@
    }
@[  elif traits['is_string']]@
    goal_msg.@(field.name) = goal.toStdString();
@[  elif traits['is_wstring']]@
    goal_msg.@(field.name) = goal.toStdWString();
@[  elif traits['is_nested']]@
    goal_msg.@(field.name) = static_cast<@(traits['nested_ros_type'])>(goal);
@[  elif traits['qt_type'].startswith('Q') and not traits['qt_type'].startswith('QList')]@
    goal_msg.@(field.name) = static_cast<@(traits['cpp_type'])>(goal);
@[  else]@
    goal_msg.@(field.name) = goal;
@[  end if]@
@[end if]@

    auto options = rclcpp_action::Client<@(ros_action_type)>::SendGoalOptions();

    auto weakThis = QPointer<@(qt_class_name)ActionClient>(this);
    options.goal_response_callback = [weakThis, promise, lastError](auto gh) {
        if (!promise) {
            return;
        }

        const auto failPromise = [weakThis, promise, lastError](const QString &message) {
            if (lastError) {
                *lastError = message;
            }
            promise->setException(QRos2ActionClientBase::makeException(message));
            promise->finish();
        };

        if (!weakThis) {
            failPromise(QStringLiteral("Action client destroyed"));
            return;
        }

        if (!gh) {
            QMetaObject::invokeMethod(qApp, [weakThis] {
                weakThis->setState(ActionState::Rejected);
            });
            failPromise(QStringLiteral("Goal rejected by server"));
        } else {
            weakThis->m_goalHandle = gh;
            QMetaObject::invokeMethod(qApp, [weakThis] {
                weakThis->setState(ActionState::Accepted);
            });
        }
    };

    options.feedback_callback = [weakThis](auto gh, const auto& fb) {
        if (!weakThis) {
            return;
        }
        // Check if this feedback is for the current goal
        if (weakThis->m_goalHandle != gh) {
            return;
        }
        QMetaObject::invokeMethod(qApp, [weakThis, gh, fb] {
            if (!weakThis) {
                return;
            }
            // Double-check after Qt event dispatch
            if (weakThis->m_goalHandle != gh) {
                return;
            }
@[if feedback_class != 'void']@
            if (!fb) {
                return;
            }
@[  if feedback_needs_wrap]@
            weakThis->m_feedback = @(feedback_class_full)(*fb);
@[  elif feedback_members]@
@{
field = feedback_field
traits = feedback_traits
}@
@[    if traits['is_qbytearray']]@
            weakThis->m_feedback = QByteArray(
                reinterpret_cast<const char*>(fb->@(field.name).data()),
                static_cast<int>(fb->@(field.name).size()));
@[    elif traits['is_sequence_like']]@
            @(feedback_class_full) converted;
            converted.reserve(fb->@(field.name).size());
            for (const auto& ros_item : fb->@(field.name)) {
@[      if traits['sequence_inner_is_nested']]@
                converted.append(@(traits['sequence_inner_qt'])(ros_item));
@[      elif traits['sequence_inner_is_string']]@
                converted.append(QString::fromStdString(ros_item));
@[      elif traits['sequence_inner_is_wstring']]@
                converted.append(QString::fromStdWString(ros_item));
@[      elif traits['sequence_inner_qt']]@
                converted.append(static_cast<@(traits['sequence_inner_qt'])>(ros_item));
@[      else]@
                converted.append(ros_item);
@[      end if]@
            }
            weakThis->m_feedback = converted;
@[    elif traits['is_string']]@
            weakThis->m_feedback = QString::fromStdString(fb->@(field.name));
@[    elif traits['is_wstring']]@
            weakThis->m_feedback = QString::fromStdWString(fb->@(field.name));
@[    else]@
            weakThis->m_feedback = fb->@(field.name);
@[    end if]@
@[  end if]@
            emit weakThis->feedbackChanged(weakThis->m_feedback);
@[end if]@
        }, Qt::QueuedConnection);
    };

    options.result_callback = [weakThis, promise, lastError](const auto &wrapped) {
        const auto rejectWithReason = [promise, lastError](const QString &reason) {
            if (lastError) {
                *lastError = reason;
            }
            promise->setException(QRos2ActionClientBase::makeException(reason));
            promise->finish();
        };

        if (!weakThis) {
            rejectWithReason(QStringLiteral("Action client destroyed"));
            return;
        }

        if (weakThis->m_goalHandle && weakThis->m_goalHandle->get_goal_id() != wrapped.goal_id) {
            rejectWithReason(QStringLiteral("Goal superseded by new goal"));
            return;
        }

        if (wrapped.code == rclcpp_action::ResultCode::SUCCEEDED) {

@[if result_class != 'void']@
@[  if result_needs_wrap]@
            @(result_class_full) result = wrapped.result ? @(result_class_full)(*wrapped.result) : @(result_class_full)();
            promise->addResult(result);
@[  elif result_members]@
@{
field = result_field
traits = result_traits
}@
            @(result_class_full) result = @(result_class_full)();
            if (wrapped.result) {
@[    if traits['is_qbytearray']]@
                result = QByteArray(
                    reinterpret_cast<const char*>(wrapped.result->@(field.name).data()),
                    static_cast<int>(wrapped.result->@(field.name).size()));
@[    elif traits['is_sequence_like']]@
                result.clear();
                result.reserve(wrapped.result->@(field.name).size());
                for (const auto& ros_item : wrapped.result->@(field.name)) {
@[      if traits['sequence_inner_is_nested']]@
                    result.append(@(traits['sequence_inner_qt'])(ros_item));
@[      elif traits['sequence_inner_is_string']]@
                    result.append(QString::fromStdString(ros_item));
@[      elif traits['sequence_inner_is_wstring']]@
                    result.append(QString::fromStdWString(ros_item));
@[      elif traits['sequence_inner_qt']]@
                    result.append(static_cast<@(traits['sequence_inner_qt'])>(ros_item));
@[      else]@
                    result.append(ros_item);
@[      end if]@
                }
@[    elif traits['is_string']]@
                result = QString::fromStdString(wrapped.result->@(field.name));
@[    elif traits['is_wstring']]@
                result = QString::fromStdWString(wrapped.result->@(field.name));
@[    else]@
                result = wrapped.result->@(field.name);
@[    end if]@
            }
            promise->addResult(result);
@[  end if]@
@[end if]@
            promise->finish();

            QMetaObject::invokeMethod(
                qApp,
                [weakThis, resultGoalId = wrapped.goal_id] {
                    if (!weakThis)
                        return;
                    // Double-check after Qt event dispatch
                    if (!weakThis->m_goalHandle || weakThis->m_goalHandle->get_goal_id() != resultGoalId)
                        return;
@[if feedback_class != 'void']@
                    weakThis->m_feedback = @(feedback_class_full)();
                    emit weakThis->feedbackChanged(weakThis->m_feedback);
@[end if]@
                    weakThis->setState(ActionState::Succeeded);
                    weakThis->m_goalHandle.reset();
                },
                Qt::QueuedConnection);
        } else {
            QString reason;
            ActionState newState = ActionState::Aborted;
            if (wrapped.code == rclcpp_action::ResultCode::CANCELED) {
                reason = QStringLiteral("Canceled");
                newState = ActionState::Canceled;
            } else if (wrapped.code == rclcpp_action::ResultCode::ABORTED) {
                reason = QStringLiteral("Aborted");
                newState = ActionState::Aborted;
            } else {
                reason = QStringLiteral("Unknown error");
            }

            QMetaObject::invokeMethod(
                qApp,
                [weakThis, resultGoalId = wrapped.goal_id, newState] {
                    if (!weakThis)
                        return;
                    // Double-check after Qt event dispatch
                    if (!weakThis->m_goalHandle || weakThis->m_goalHandle->get_goal_id() != resultGoalId)
                        return;
                    weakThis->setState(newState);
                    weakThis->m_goalHandle.reset();
                },
                Qt::QueuedConnection);

            rejectWithReason(reason);
        }

 
    };

    m_client->async_send_goal(goal_msg, options);
    return future;
}

#ifdef QTROS2_EXPERIMENTAL_FUTURE
@[if result_class == 'void']@
@[  if goal_param]@
QFuture<void> @(qt_class_name)ActionClient::sendGoal(@(goal_param))
@[  else]@
QFuture<void> @(qt_class_name)ActionClient::sendGoal()
@[  end if]@
@[else]@
@[  if goal_param]@
QFuture<@(result_class_full)> @(qt_class_name)ActionClient::sendGoal(@(goal_param))
@[  else]@
QFuture<@(result_class_full)> @(qt_class_name)ActionClient::sendGoal()
@[  end if]@
@[end if]@
{
@[if goal_param]@
    return sendGoalFuture(goal);
@[else]@
    return sendGoalFuture();
@[end if]@
}
#else
@[if goal_param]@
QJSValue @(qt_class_name)ActionClient::sendGoal(@(goal_param))
@[else]@
QJSValue @(qt_class_name)ActionClient::sendGoal()
@[end if]@
{
    QQmlEngine* engine = qmlEngine(this);
    if (!engine) {
        return QJSValue();
    }
    auto errorMsg = std::make_shared<QString>();
@[if result_class == 'void']@
@[  if goal_param]@
    return JsFutureWrapper::fromFuture<void>(engine, sendGoalFuture(goal, errorMsg), this, errorMsg);
@[  else]@
    return JsFutureWrapper::fromFuture<void>(engine, sendGoalFuture(errorMsg), this, errorMsg);
@[  end if]@
@[else]@
@[  if goal_param]@
    return JsFutureWrapper::fromFuture<@(result_class_full)>(engine, sendGoalFuture(goal, errorMsg), this, errorMsg);
@[  else]@
    return JsFutureWrapper::fromFuture<@(result_class_full)>(engine, sendGoalFuture(errorMsg), this, errorMsg);
@[  end if]@
@[end if]@
}
#endif

void @(qt_class_name)ActionClient::cancelGoal()
{
    if (m_goalHandle) {
        m_client->async_cancel_goal(m_goalHandle);
    }
}

} // namespace @(qt_namespace)
