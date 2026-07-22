// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt action server implementation
@{
from rosidl_generator_qtros2 import (
    get_qml_value_type_name,
    get_qt_class_name,
    get_qt_class_name_full,
    get_qt_namespace,
    msg_type_to_qt,
    msg_type_to_cpp,
    to_snake_case,
)
from rosidl_generator_qtros2.template_helpers import get_qml_module_uri
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

ns_list = action.namespaced_type.namespaces
name_list = ns_list + [action.namespaced_type.name]
ros_action_type = '::'.join(name_list)
header_file = to_snake_case(action_name)
qml_module_uri = get_qml_module_uri(package_name)

goal_msg = action.goal
result_msg = action.result
feedback_msg = action.feedback

goal_needs_wrap = needs_wrapper_type(goal_msg)
result_needs_wrap = needs_wrapper_type(result_msg)
feedback_needs_wrap = needs_wrapper_type(feedback_msg)

def _member_traits(member):
    if member is None:
        return None
    t = {}
    ft = member.type
    t['qt_type'] = msg_type_to_qt(ft)
    t['cpp_type'] = msg_type_to_cpp(ft)
    base = ft
    if isinstance(base, AbstractNestedType):
        base = base.value_type
    t['is_nested'] = isinstance(base, NamespacedType)
    t['nested_ros_type'] = '::'.join(base.namespaces + [base.name]) if t['is_nested'] else None
    t['is_string'] = isinstance(base, AbstractString)
    t['is_wstring'] = isinstance(base, AbstractWString)
    t['is_array'] = isinstance(ft, Array)
    t['is_sequence_like'] = t['is_array'] or isinstance(ft, (BoundedSequence, UnboundedSequence))
    inner = ft.value_type if t['is_sequence_like'] else None
    if isinstance(inner, AbstractNestedType):
        inner = inner.value_type
    t['seq_inner_qt'] = msg_type_to_qt(inner) if inner else None
    t['seq_inner_cpp'] = msg_type_to_cpp(inner) if inner else None
    t['seq_inner_is_nested'] = isinstance(inner, NamespacedType) if inner else False
    t['seq_inner_is_string'] = isinstance(inner, AbstractString) if inner else False
    t['seq_inner_is_wstring'] = isinstance(inner, AbstractWString) if inner else False
    t['is_qbytearray'] = t['qt_type'] == 'QByteArray'
    t['is_qlist'] = t['qt_type'].startswith('QList<') or t['qt_type'] == 'QStringList'
    return t

def _type_info(msg, needs_wrap):
    info = {'needs_wrap': needs_wrap}
    if needs_wrap:
        info['cls'] = get_qt_class_name(package_name, msg.structure.namespaced_type.name)
        info['full'] = get_qt_class_name_full(package_name, msg.structure.namespaced_type.name)
        info['qml'] = get_qml_value_type_name(package_name, msg.structure.namespaced_type.name)
    else:
        info['cls'] = get_single_field_type(msg, package_name)
        info['full'] = info['cls']
        info['qml'] = info['cls']
    members = []
    if hasattr(msg, 'structure') and hasattr(msg.structure, 'members'):
        members = [m for m in msg.structure.members if m.name != 'structure_needs_at_least_one_member']
    info['field'] = members[0] if (not needs_wrap and members) else None
    info['traits'] = _member_traits(info['field'])
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

# --- C++ snippet generators -------------------------------------------------

def ros_to_qt_local(info, local_name, ros_ptr):
    """Produce C++ declaring `const <full> local_name` from a `const *Goal` pointer."""
    if info['cls'] == 'void':
        return ''
    if info['needs_wrap']:
        return f"const {info['full']} {local_name}(*{ros_ptr});"
    f = info['field']
    t = info['traits']
    name = f.name
    if t['is_qbytearray']:
        return (f"const QByteArray {local_name}(reinterpret_cast<const char*>({ros_ptr}->{name}.data()), "
                f"static_cast<int>({ros_ptr}->{name}.size()));")
    if t['is_qlist'] or t['is_sequence_like']:
        out = [f"{info['full']} {local_name};",
               f"    {local_name}.reserve({ros_ptr}->{name}.size());",
               f"    for (const auto& _v : {ros_ptr}->{name}) {{"]
        if t['seq_inner_is_nested']:
            out.append(f"        {local_name}.append({t['seq_inner_qt']}(_v));")
        elif t['seq_inner_is_string']:
            out.append(f"        {local_name}.append(QString::fromStdString(_v));")
        elif t['seq_inner_is_wstring']:
            out.append(f"        {local_name}.append(QString::fromStdWString(_v));")
        elif t['seq_inner_qt']:
            out.append(f"        {local_name}.append(static_cast<{t['seq_inner_qt']}>(_v));")
        else:
            out.append(f"        {local_name}.append(_v);")
        out.append("    }")
        return "\n    ".join(out)
    if t['is_string']:
        return f"const QString {local_name} = QString::fromStdString({ros_ptr}->{name});"
    if t['is_wstring']:
        return f"const QString {local_name} = QString::fromStdWString({ros_ptr}->{name});"
    if t['is_nested']:
        return f"const {info['full']} {local_name}({ros_ptr}->{name});"
    if t['qt_type'].startswith('Q'):
        return f"const {t['qt_type']} {local_name} = static_cast<{t['qt_type']}>({ros_ptr}->{name});"
    return f"const {t['qt_type']} {local_name} = {ros_ptr}->{name};"

def qt_to_ros(info, qt_expr, ros_lhs):
    """Produce C++ assigning Qt value `qt_expr` into `ros_lhs` (an lvalue of the ROS msg)."""
    if info['cls'] == 'void':
        return ''
    if info['needs_wrap']:
        # ros_lhs is e.g. (*ros_result); assign the whole struct.
        ros_struct = ros_lhs
        return f"{ros_struct} = static_cast<{ros_lhs_type[info['role']]}>({qt_expr});"
    f = info['field']
    t = info['traits']
    name = f.name
    tgt = f"{ros_lhs}.{name}"
    if t['is_qbytearray']:
        return (f"{tgt}.assign(reinterpret_cast<const uint8_t*>({qt_expr}.constData()), "
                f"reinterpret_cast<const uint8_t*>({qt_expr}.constData()) + {qt_expr}.size());")
    if t['is_qlist'] or t['is_sequence_like']:
        out = [f"{tgt}.clear();",
               f"    {tgt}.reserve({qt_expr}.size());",
               f"    for (const auto& _v : {qt_expr}) {{"]
        if t['seq_inner_is_nested']:
            out.append(f"        {tgt}.push_back(static_cast<{t['seq_inner_cpp']}>(_v));")
        elif t['seq_inner_is_string']:
            out.append(f"        {tgt}.push_back(_v.toStdString());")
        elif t['seq_inner_is_wstring']:
            out.append(f"        {tgt}.push_back(_v.toStdWString());")
        elif t['seq_inner_qt'] and t['seq_inner_qt'].startswith('Q'):
            out.append(f"        {tgt}.push_back(static_cast<{t['seq_inner_cpp']}>(_v));")
        else:
            out.append(f"        {tgt}.push_back(_v);")
        out.append("    }")
        return "\n    ".join(out)
    if t['is_string']:
        return f"{tgt} = {qt_expr}.toStdString();"
    if t['is_wstring']:
        return f"{tgt} = {qt_expr}.toStdWString();"
    if t['is_nested']:
        return f"{tgt} = static_cast<{t['nested_ros_type']}>({qt_expr});"
    if t['qt_type'].startswith('Q'):
        return f"{tgt} = static_cast<{t['cpp_type']}>({qt_expr});"
    return f"{tgt} = {qt_expr};"

ros_lhs_type = {
    'result': f'{ros_action_type}::Result',
    'feedback': f'{ros_action_type}::Feedback',
}
result_info['role'] = 'result'
feedback_info['role'] = 'feedback'
}@
#include "@(header_file)_action_server.hpp"
#include <QtRos2Core/private/qros2node_p.h>
#include <QCoreApplication>
#include <QByteArray>
#include <QDebug>
#include <QPointer>
#include <memory>

namespace @(qt_namespace) {

namespace {
inline QByteArray uuidKey(const rclcpp_action::GoalUUID& id)
{
    return QByteArray(reinterpret_cast<const char*>(id.data()), static_cast<int>(id.size()));
}
} // namespace

/*!
    \qmltype @(qt_class_name)ActionServer
    \inqmlmodule @(qml_module_uri)
    \inherits ActionServerBase
    \brief Serves the \c @(ros_action_type) ROS 2 action.

    Set the \c topic and \c node properties and handle the
    \c goalReceived signal. Each accepted goal is delivered with a
    per-goal \c handle; call \c {handle.publishFeedback(...)},
    \c {handle.succeed(...)}, \c {handle.abort(...)} or
    \c {handle.canceled(...)}, and react to \c {handle.cancelRequested}.
*/

@(qt_class_name)ActionServer::@(qt_class_name)ActionServer(QObject* parent)
    : QRos2ActionServerBase(parent)
{
}

@(qt_class_name)ActionServer::~@(qt_class_name)ActionServer() = default;

// ---- Goal handle ----------------------------------------------------------

@(qt_class_name)GoalHandle::@(qt_class_name)GoalHandle(
    @(qt_class_name)ActionServer* server,
    std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle,
@[if goal_info['cls'] != 'void']@
    const @(goal_info['full'])& goal,
@[end if]@
    QObject* parent)
    : QObject(parent)
    , m_server(server)
    , m_handle(std::move(handle))
@[if goal_info['cls'] != 'void']@
    , m_goal(goal)
@[end if]@
{
}

@[if feedback_info['cls'] != 'void']@
void @(qt_class_name)GoalHandle::publishFeedback(@(feedback_param_prefix)feedback)
{
    if (m_finished || !m_handle) {
        return;
    }
    auto ros_feedback = std::make_shared<@(ros_action_type)::Feedback>();
    @(qt_to_ros(feedback_info, 'feedback', '(*ros_feedback)'))
    m_handle->publish_feedback(ros_feedback);
}

@[end if]@
void @(qt_class_name)GoalHandle::succeed(@(result_param_prefix)result)
{
    if (m_finished || !m_handle) {
        return;
    }
    auto ros_result = std::make_shared<@(ros_action_type)::Result>();
@[if result_info['cls'] != 'void']@
    @(qt_to_ros(result_info, 'result', '(*ros_result)'))
@[else]@
    Q_UNUSED(result);
@[end if]@
    m_handle->succeed(ros_result);
    finish();
}

void @(qt_class_name)GoalHandle::abort(@(result_param_prefix)result)
{
    if (m_finished || !m_handle) {
        return;
    }
    auto ros_result = std::make_shared<@(ros_action_type)::Result>();
@[if result_info['cls'] != 'void']@
    @(qt_to_ros(result_info, 'result', '(*ros_result)'))
@[else]@
    Q_UNUSED(result);
@[end if]@
    m_handle->abort(ros_result);
    finish();
}

void @(qt_class_name)GoalHandle::canceled(@(result_param_prefix)result)
{
    if (m_finished || !m_handle) {
        return;
    }
    auto ros_result = std::make_shared<@(ros_action_type)::Result>();
@[if result_info['cls'] != 'void']@
    @(qt_to_ros(result_info, 'result', '(*ros_result)'))
@[else]@
    Q_UNUSED(result);
@[end if]@
    m_handle->canceled(ros_result);
    finish();
}

void @(qt_class_name)GoalHandle::notifyCancelRequested()
{
    if (m_cancelRequested) {
        return;
    }
    m_cancelRequested = true;
    emit cancelRequestedChanged();
    emit cancelRequested();
}

void @(qt_class_name)GoalHandle::finish()
{
    m_finished = true;
    if (m_server) {
        m_server->removeHandle(this);
    }
    deleteLater();
}

// ---- Action server --------------------------------------------------------

void @(qt_class_name)ActionServer::setupConnection()
{
    if (m_server) {
        m_server.reset();
    }

    if (!node() || !node()->rosNode() || m_topic.isEmpty()) {
        setActive(false);
        return;
    }

    auto weakThis = QPointer<@(qt_class_name)ActionServer>(this);

    auto handleGoal = [](const rclcpp_action::GoalUUID&,
                         std::shared_ptr<const @(ros_action_type)::Goal>) {
        return rclcpp_action::GoalResponse::ACCEPT_AND_EXECUTE;
    };

    auto handleCancel = [weakThis](
            const std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle) {
        const QByteArray key = uuidKey(handle->get_goal_id());
        QMetaObject::invokeMethod(qApp, [weakThis, key] {
            if (weakThis)
                weakThis->routeCancel(key);
        }, Qt::QueuedConnection);
        return rclcpp_action::CancelResponse::ACCEPT;
    };

    auto handleAccepted = [weakThis](
            std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle) {
        QMetaObject::invokeMethod(qApp, [weakThis, handle] {
            if (weakThis)
                weakThis->dispatchAccepted(handle);
        }, Qt::QueuedConnection);
    };

    m_server = rclcpp_action::create_server<@(ros_action_type)>(
        node()->rosNode(),
        m_topic.toStdString(),
        handleGoal,
        handleCancel,
        handleAccepted);
    setActive(true);
}

void @(qt_class_name)ActionServer::clearConnection()
{
    m_server.reset();
    m_handles.clear();
    setActive(false);
}

void @(qt_class_name)ActionServer::checkHealth()
{
    setActive(m_server != nullptr);
}

void @(qt_class_name)ActionServer::dispatchAccepted(
    std::shared_ptr<rclcpp_action::ServerGoalHandle<@(ros_action_type)>> handle)
{
    if (!m_server || !handle) {
        return;
    }

    const QByteArray key = uuidKey(handle->get_goal_id());
@[if goal_info['cls'] != 'void']@
    const auto goalPtr = handle->get_goal();
    @(ros_to_qt_local(goal_info, 'goalValue', 'goalPtr'))
    auto* goalHandle = new @(qt_class_name)GoalHandle(this, handle, goalValue, this);
@[else]@
    auto* goalHandle = new @(qt_class_name)GoalHandle(this, handle, this);
@[end if]@
    m_handles.insert(key, goalHandle);

@[if goal_info['cls'] != 'void']@
    emit goalReceived(goalValue, goalHandle);
@[else]@
    emit goalReceived(goalHandle);
@[end if]@
}

void @(qt_class_name)ActionServer::routeCancel(const QByteArray& goalId)
{
    auto it = m_handles.constFind(goalId);
    if (it != m_handles.constEnd() && it.value()) {
        it.value()->notifyCancelRequested();
    }
}

void @(qt_class_name)ActionServer::removeHandle(@(qt_class_name)GoalHandle* handle)
{
    for (auto it = m_handles.begin(); it != m_handles.end(); ++it) {
        if (it.value() == handle) {
            m_handles.erase(it);
            return;
        }
    }
}

} // namespace @(qt_namespace)
