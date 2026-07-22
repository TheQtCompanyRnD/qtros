// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt action server header
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

def _type_info(msg, needs_wrap):
    info = {}
    if needs_wrap:
        info['cls'] = get_qt_class_name(package_name, msg.structure.namespaced_type.name)
        info['full'] = get_qt_class_name_full(package_name, msg.structure.namespaced_type.name)
        info['include'] = f'"{to_snake_case(msg.structure.namespaced_type.name)}.hpp"'
    else:
        info['cls'] = get_single_field_type(msg, package_name)
        info['full'] = info['cls']
        field_info = get_single_field_include(msg, package_name)
        if field_info:
            pkg, msg_name, is_cross = field_info
            if is_cross:
                info['include'] = f'<{qt_package_mapping.get(pkg, f"qtros2_{pkg}")}/msg/{to_snake_case(msg_name)}.hpp>'
            else:
                info['include'] = f'"{to_snake_case(msg_name)}.hpp"'
        else:
            info['include'] = None
    return info

goal_info = _type_info(goal_msg, goal_needs_wrap)
result_info = _type_info(result_msg, result_needs_wrap)
feedback_info = _type_info(feedback_msg, feedback_needs_wrap)

def _param(info):
    if info['cls'] == 'void':
        return ''
    if info['full'].startswith('Q') or '::' in info['full']:
        return 'const ' + info['full'] + '& '
    return info['full'] + ' '

goal_param_prefix = _param(goal_info)
result_param_prefix = _param(result_info)
feedback_param_prefix = _param(feedback_info)

# ROS action type
ns_list = action.namespaced_type.namespaces
name_list = ns_list + [action.namespaced_type.name]
ros_action_type = '::'.join(name_list)
ros_include = ros_action_include if 'ros_action_include' in locals() and ros_action_include else package_name + '/action/' + to_snake_case(action_name) + '.hpp'
header_guard = build_include_guard(package_name, 'action', base_name + '_action_server')
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

#include <QtRos2Core/private/qros2actionserverbase_p.h>
@[if goal_info['include']]@
#include @(goal_info['include'])
@[end if]@
@[if result_info['include'] and result_info['include'] != goal_info['include']]@
#include @(result_info['include'])
@[end if]@
@[if feedback_info['include'] and feedback_info['include'] not in (goal_info['include'], result_info['include'])]@
#include @(feedback_info['include'])
@[end if]@
#ifndef Q_QDOC
#include <@(ros_include)>
#include <rclcpp_action/rclcpp_action.hpp>
#endif
#include <QHash>
#include <QByteArray>
#include <QPointer>
#include <memory>

namespace @(qt_namespace) {

class @(qt_class_name)ActionServer;

/*!
 * @@brief Per-goal handle for one accepted @(ros_action_type) goal.
 *
 * Emitted with the goalReceived signal. QML uses it to publish feedback,
 * complete the goal, and observe cancellation requests.
 */
class @(qt_export_macro) @(qt_class_name)GoalHandle : public QObject
{
    Q_OBJECT
    QML_ANONYMOUS

@[if goal_info['cls'] != 'void']@
    Q_PROPERTY(@(goal_info['full']) goal READ goal CONSTANT)
@[end if]@
    Q_PROPERTY(bool cancelRequested READ isCancelRequested NOTIFY cancelRequestedChanged)

public:
#ifndef Q_QDOC
    explicit @(qt_class_name)GoalHandle(
        @(qt_class_name)ActionServer* server,
        std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle,
@[if goal_info['cls'] != 'void']@
        const @(goal_info['full'])& goal,
@[end if]@
        QObject* parent = nullptr);
#endif

@[if goal_info['cls'] != 'void']@
    @(goal_info['full']) goal() const { return m_goal; }
@[end if]@
    bool isCancelRequested() const { return m_cancelRequested; }

@[if feedback_info['cls'] != 'void']@
    Q_INVOKABLE void publishFeedback(@(feedback_param_prefix)feedback);
@[end if]@
    Q_INVOKABLE void succeed(@(result_param_prefix)result);
    Q_INVOKABLE void abort(@(result_param_prefix)result);
    Q_INVOKABLE void canceled(@(result_param_prefix)result);

Q_SIGNALS:
    // Cancellation is exposed only as the cancelRequested bool property (it
    // latches false->true once), so cancelRequestedChanged() fires exactly at
    // the cancel request -- observe that. A same-named cancelRequested() signal
    // would shadow the property in QML (property wins), making it unconnectable.
    void cancelRequestedChanged();

private:
    friend class @(qt_class_name)ActionServer;
    void notifyCancelRequested();
    void finish();

    QPointer<@(qt_class_name)ActionServer> m_server;
#ifndef Q_QDOC
    std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> m_handle;
#endif
@[if goal_info['cls'] != 'void']@
    @(goal_info['full']) m_goal{};
@[end if]@
    bool m_cancelRequested = false;
    bool m_finished = false;
};

/*!
 * @@brief Qt action server for @(ros_action_type)
 *
 * Advertises the @(action_name) action. For each incoming goal it emits
 * goalReceived with the goal payload and a per-goal handle. Can be used
 * directly in QML.
 */
class @(qt_export_macro) @(qt_class_name)ActionServer : public QRos2ActionServerBase
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit @(qt_class_name)ActionServer(QObject* parent = nullptr);
    ~@(qt_class_name)ActionServer() override;

Q_SIGNALS:
@[if goal_info['cls'] != 'void']@
    void goalReceived(@(goal_param_prefix)goal, @(qt_namespace)::@(qt_class_name)GoalHandle* handle);
@[else]@
    void goalReceived(@(qt_namespace)::@(qt_class_name)GoalHandle* handle);
@[end if]@

protected:
    void setupConnection() override;
    void clearConnection() override;
    void checkHealth() override;

private:
    friend class @(qt_class_name)GoalHandle;
#ifndef Q_QDOC
    // Runs on the GUI thread (queued from the executor thread).
    void dispatchAccepted(
        std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle);
    void routeCancel(const QByteArray& goalId);
    void removeHandle(@(qt_class_name)GoalHandle* handle);
    rclcpp_action::Server<@(ros_action_type)>::SharedPtr m_server;
#endif
    QHash<QByteArray, QPointer<@(qt_class_name)GoalHandle>> m_handles;
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
