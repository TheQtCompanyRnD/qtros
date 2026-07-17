// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt service server implementation
@{
from rosidl_generator_qtros2 import get_qml_value_type_name, get_qt_class_name, get_qt_class_name_full, msg_type_to_qt, msg_type_to_cpp, to_snake_case
from rosidl_generator_qtros2 import get_qt_namespace
from rosidl_generator_qtros2.template_helpers import get_qml_module_uri
from rosidl_parser.definition import (
    NamespacedType,
    AbstractNestedType,
    BoundedSequence,
    UnboundedSequence,
    Array,
    AbstractString,
    AbstractWString,
)
qt_namespace = get_qt_namespace(package_name)

service_name = service.namespaced_type.name
qt_class_name = get_qt_class_name(package_name, service_name)
service_header = to_snake_case(service_name)

# ROS service type
ns_list = service.namespaced_type.namespaces
name_list = ns_list + [service.namespaced_type.name]
ros_srv_type = '::'.join(name_list)

# Get request and response
request_msg = service.request_message
response_msg = service.response_message

# Check if wrappers needed
req_needs_wrap = needs_wrapper_type(request_msg)
resp_needs_wrap = needs_wrapper_type(response_msg)

# Compute types
if req_needs_wrap:
    req_class = get_qt_class_name(package_name, request_msg.structure.namespaced_type.name)
    req_class_full = get_qt_class_name_full(package_name, request_msg.structure.namespaced_type.name)
    req_class_qml = get_qml_value_type_name(package_name, request_msg.structure.namespaced_type.name)
    req_param = 'const ' + req_class_full + '& request'
else:
    req_class = get_single_field_type(request_msg, package_name)
    req_class_full = req_class
    req_class_qml = req_class
    if req_class != 'void':
        req_param = 'const ' + req_class_full + '& request'
    else:
        req_param = ''

if resp_needs_wrap:
    resp_class = get_qt_class_name(package_name, response_msg.structure.namespaced_type.name)
    resp_class_full = get_qt_class_name_full(package_name, response_msg.structure.namespaced_type.name)
    resp_class_qml = get_qml_value_type_name(package_name, response_msg.structure.namespaced_type.name)
else:
    resp_class = get_single_field_type(response_msg, package_name)
    resp_class_full = resp_class
    resp_class_qml = resp_class

if resp_class != 'void':
    resp_param = 'const ' + resp_class_full + '& response'
else:
    resp_param = ''

# Request and response members
req_members = []
if hasattr(request_msg, 'structure') and hasattr(request_msg.structure, 'members'):
    req_members = [m for m in request_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

resp_members = []
if hasattr(response_msg, 'structure') and hasattr(response_msg.structure, 'members'):
    resp_members = [m for m in response_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

# Single-field request extraction info (ROS request -> Qt value)
req_field = req_members[0] if (not req_needs_wrap and req_members) else None
if req_field:
    rq_qt_type = msg_type_to_qt(req_field.type)
    rq_field_type = req_field.type
    rq_is_array = isinstance(rq_field_type, Array)
    rq_is_sequence = isinstance(rq_field_type, (BoundedSequence, UnboundedSequence))
    rq_sequence_like = rq_is_array or rq_is_sequence
    rq_seq_value_type = rq_field_type.value_type if rq_sequence_like else None
    if isinstance(rq_seq_value_type, AbstractNestedType):
        rq_seq_value_type = rq_seq_value_type.value_type
    rq_seq_inner_qt = msg_type_to_qt(rq_seq_value_type) if rq_seq_value_type else None
    rq_seq_inner_is_nested = isinstance(rq_seq_value_type, NamespacedType) if rq_seq_value_type else False
    rq_seq_inner_is_string = isinstance(rq_seq_value_type, AbstractString)
    rq_seq_inner_is_wstring = isinstance(rq_seq_value_type, AbstractWString)
    rq_is_qbytearray = (req_class_full == 'QByteArray')
    rq_is_list = req_class_full.startswith('QList<') or req_class_full == 'QStringList'

# Single-field response marshalling info (Qt value -> ROS response)
resp_field = resp_members[0] if (not resp_needs_wrap and resp_members) else None
if resp_field:
    rs_qt_type = msg_type_to_qt(resp_field.type)
    rs_cpp_type = msg_type_to_cpp(resp_field.type)
    rs_field_type = resp_field.type
    rs_base_type = rs_field_type
    if isinstance(rs_base_type, AbstractNestedType):
        rs_base_type = rs_base_type.value_type
    rs_is_nested = isinstance(rs_base_type, NamespacedType)
    rs_nested_ros_type = '::'.join(rs_base_type.namespaces + [rs_base_type.name]) if rs_is_nested else None
    rs_is_array = isinstance(rs_field_type, Array)
    rs_is_sequence = isinstance(rs_field_type, (BoundedSequence, UnboundedSequence))
    rs_sequence_like = rs_is_array or rs_is_sequence
    rs_seq_value_type = rs_field_type.value_type if rs_sequence_like else None
    if isinstance(rs_seq_value_type, AbstractNestedType):
        rs_seq_value_type = rs_seq_value_type.value_type
    rs_seq_inner_qt = msg_type_to_qt(rs_seq_value_type) if rs_seq_value_type else None
    rs_seq_inner_cpp = msg_type_to_cpp(rs_seq_value_type) if rs_seq_value_type else None
    rs_seq_inner_is_nested = isinstance(rs_seq_value_type, NamespacedType) if rs_seq_value_type else False
    rs_seq_inner_is_string = isinstance(rs_seq_value_type, AbstractString)
    rs_seq_inner_is_wstring = isinstance(rs_seq_value_type, AbstractWString)
    rs_is_qbytearray = (rs_qt_type == 'QByteArray')
    rs_is_qstringlist = (rs_qt_type == 'QStringList')

# Documentation helpers
qml_module_uri = get_qml_module_uri(package_name)
req_l_type = ('\\l ' + req_class_qml) if req_needs_wrap else req_class_qml
resp_l_type = ('\\l ' + resp_class_qml) if resp_needs_wrap else resp_class_qml
req_doc_param = (req_class_qml + ' request') if req_param else ''
}@
#include "@(service_header)_service_server.hpp"
#include <QtRos2Core/private/qros2node_p.h>
#include <QCoreApplication>
#include <QQmlEngine>
#include <QJSValueList>
#include <QDebug>
#include <memory>

namespace @(qt_namespace) {

/*!
    \qmltype @(qt_class_name)ServiceServer
    \inqmlmodule @(qml_module_uri)
    \inherits ServiceServerBase
    \brief Answers \c @(ros_srv_type) ROS 2 service requests.

    Set the \c topic and \c node properties and provide a
    \l {ServiceServerBase::handler}{handler} function to answer requests.
    The handler is invoked as \c {(request, reply) => response}; it may
    return the response value directly, or return \c undefined and call
    \c {reply.send(response)} later for work that takes time.
@[if resp_class != 'void']@

    The response is a @(resp_l_type) value@[if resp_needs_wrap]; a plain
    JavaScript object with the response fields is converted
    automatically@[end if].
@[end if]@
*/

/*!
@[if req_doc_param]@
    \qmlsignal @(qt_class_name)ServiceServer::requestReceived(@(req_doc_param))

    Emitted when a request arrives, before the handler is invoked.
    \a request is a @(req_l_type) value.
@[else]@
    \qmlsignal @(qt_class_name)ServiceServer::requestReceived()

    Emitted when a request arrives, before the handler is invoked.
@[end if]@
*/

@(qt_class_name)ServiceServer::@(qt_class_name)ServiceServer(QObject* parent)
    : QRos2ServiceServerBase(parent)
{
}

@(qt_class_name)ServiceServer::~@(qt_class_name)ServiceServer()
{
}

@(qt_class_name)ServiceReply::@(qt_class_name)ServiceReply(@(qt_class_name)ServiceServer* server,
                                                           const rmw_request_id_t& requestId,
                                                           QObject* parent)
    : QObject(parent)
    , m_server(server)
    , m_requestId(requestId)
{
}

@[if resp_param]@
void @(qt_class_name)ServiceReply::send(@(resp_param))
@[else]@
void @(qt_class_name)ServiceReply::send()
@[end if]@
{
    if (m_sent) {
        qWarning() << "@(qt_class_name)ServiceReply: response already sent";
        return;
    }
    m_sent = true;
    if (m_server) {
@[if resp_param]@
        m_server->sendResponse(m_requestId, response);
@[else]@
        m_server->sendDefaultResponse(m_requestId);
@[end if]@
    }
    deleteLater();
}

void @(qt_class_name)ServiceServer::setupConnection()
{
    // Clear existing connection before creating a new one
    if (m_service) {
        m_service.reset();
    }

    if (!node() || !node()->rosNode() || m_topic.isEmpty()) {
        setActive(false);
        return;
    }

    auto weakThis = QPointer<@(qt_class_name)ServiceServer>(this);
    m_service = node()->rosNode()->create_service<@(ros_srv_type)>(
        m_topic.toStdString(),
        [weakThis](std::shared_ptr<rmw_request_id_t> requestId,
                   std::shared_ptr<@(ros_srv_type)::Request> request) {
            // Executor thread: marshal to the GUI thread. Taking the
            // deferred-response callback signature means rclcpp does not
            // send a response when this callback returns; the response
            // goes out later via send_response(), so the executor is
            // never blocked while the handler runs.
            QMetaObject::invokeMethod(
                qApp,
                [weakThis, requestId, request] {
                    if (weakThis)
                        weakThis->dispatchRequest(requestId, request);
                },
                Qt::QueuedConnection);
        },
        qos());
    setActive(true);
}

void @(qt_class_name)ServiceServer::clearConnection()
{
    m_service.reset();
    setActive(false);
}

void @(qt_class_name)ServiceServer::checkHealth()
{
    setActive(m_service != nullptr);
}

void @(qt_class_name)ServiceServer::dispatchRequest(const std::shared_ptr<rmw_request_id_t>& requestId,
                                                    const std::shared_ptr<@(ros_srv_type)::Request>& request)
{
    if (!m_service) {
        return; // disconnected while the request was in flight
    }

@[if req_needs_wrap]@
    const @(req_class_full) requestValue(*request);
@[elif req_field]@
@[  if rq_is_qbytearray]@
    const QByteArray requestValue(reinterpret_cast<const char*>(request->@(req_field.name).data()),
                                  static_cast<int>(request->@(req_field.name).size()));
@[  elif rq_is_list]@
    @(req_class_full) requestValue;
    requestValue.reserve(request->@(req_field.name).size());
    for (const auto& ros_item : request->@(req_field.name)) {
@[    if rq_seq_inner_is_nested]@
        requestValue.append(@(rq_seq_inner_qt)(ros_item));
@[    elif rq_seq_inner_is_string]@
        requestValue.append(QString::fromStdString(ros_item));
@[    elif rq_seq_inner_is_wstring]@
        requestValue.append(QString::fromStdWString(ros_item));
@[    elif rq_seq_inner_qt]@
        requestValue.append(static_cast<@(rq_seq_inner_qt)>(ros_item));
@[    else]@
        requestValue.append(ros_item);
@[    end if]@
    }
@[  elif rq_qt_type == 'QString']@
    const QString requestValue = QString::fromStdString(request->@(req_field.name));
@[  elif rq_qt_type.startswith('Q') and not rq_qt_type.startswith('QList')]@
    const @(rq_qt_type) requestValue = static_cast<@(rq_qt_type)>(request->@(req_field.name));
@[  else]@
    const @(rq_qt_type) requestValue = request->@(req_field.name);
@[  end if]@
@[else]@
    Q_UNUSED(request);
@[end if]@

@[if req_param]@
    emit requestReceived(requestValue);
@[else]@
    emit requestReceived();
@[end if]@

    QJSValue h = handler();
    QQmlEngine* engine = qmlEngine(this);
    if (!engine || !h.isCallable()) {
        qWarning() << "@(qt_class_name)ServiceServer: no callable handler for" << topic()
                   << "- sending default response";
        sendDefaultResponse(*requestId);
        return;
    }

    auto* reply = new @(qt_class_name)ServiceReply(this, *requestId, this);
    QJSValueList args;
@[if req_param]@
    args << engine->toScriptValue(requestValue);
@[else]@
    args << QJSValue(QJSValue::UndefinedValue);
@[end if]@
    args << engine->newQObject(reply);

    const QJSValue result = h.call(args);
    if (result.isError()) {
        qWarning() << "@(qt_class_name)ServiceServer: handler threw:" << result.toString();
        if (!reply->isSent()) {
            reply->m_sent = true;
            sendDefaultResponse(*requestId);
            reply->deleteLater();
        }
        return;
    }

    if (!result.isUndefined() && !reply->isSent()) {
        // Synchronous style: the handler returned the response value.
@[if resp_param]@
        reply->send(engine->coerceValue<QJSValue, @(resp_class_full)>(result));
@[else]@
        reply->send();
@[end if]@
    }
    // Otherwise the handler deferred: it keeps `reply` and calls
    // reply.send(...) when the work completes.
}

@[if resp_param]@
void @(qt_class_name)ServiceServer::sendResponse(const rmw_request_id_t& requestId, @(resp_param))
{
    if (!m_service) {
        return;
    }

    @(ros_srv_type)::Response ros_resp;
@[  if resp_needs_wrap]@
    ros_resp = static_cast<@(ros_srv_type)::Response>(response);
@[  elif rs_is_qbytearray]@
    ros_resp.@(resp_field.name).assign(
        reinterpret_cast<const uint8_t*>(response.constData()),
        reinterpret_cast<const uint8_t*>(response.constData()) + response.size()
    );
@[  elif rs_is_qstringlist]@
    ros_resp.@(resp_field.name).clear();
    ros_resp.@(resp_field.name).reserve(response.size());
    for (const auto& value : response) {
@[    if rs_seq_inner_is_wstring]@
        ros_resp.@(resp_field.name).push_back(value.toStdWString());
@[    else]@
        ros_resp.@(resp_field.name).push_back(value.toStdString());
@[    end if]@
    }
@[  elif rs_is_array]@
    {
        const int resp_size = response.size();
        const int ros_size = static_cast<int>(ros_resp.@(resp_field.name).size());
        const int maxCount = (resp_size < ros_size) ? resp_size : ros_size;
        for (int idx = 0; idx < maxCount; ++idx) {
@[    if rs_seq_inner_is_nested]@
            ros_resp.@(resp_field.name)[idx] = static_cast<@(rs_seq_inner_cpp)>(response[idx]);
@[    elif rs_seq_inner_is_string]@
            ros_resp.@(resp_field.name)[idx] = response[idx].toStdString();
@[    elif rs_seq_inner_is_wstring]@
            ros_resp.@(resp_field.name)[idx] = response[idx].toStdWString();
@[    elif rs_seq_inner_qt and rs_seq_inner_qt.startswith('Q') and not rs_seq_inner_qt.startswith('QList')]@
            ros_resp.@(resp_field.name)[idx] = static_cast<@(rs_seq_inner_cpp)>(response[idx]);
@[    else]@
            ros_resp.@(resp_field.name)[idx] = response[idx];
@[    end if]@
        }
        for (size_t idx = maxCount; idx < ros_resp.@(resp_field.name).size(); ++idx) {
            ros_resp.@(resp_field.name)[idx] = @(rs_seq_inner_cpp)();
        }
    }
@[  elif rs_sequence_like]@
    ros_resp.@(resp_field.name).clear();
    ros_resp.@(resp_field.name).reserve(response.size());
    for (const auto& value : response) {
@[    if rs_seq_inner_is_nested]@
        ros_resp.@(resp_field.name).push_back(static_cast<@(rs_seq_inner_cpp)>(value));
@[    elif rs_seq_inner_is_string]@
        ros_resp.@(resp_field.name).push_back(value.toStdString());
@[    elif rs_seq_inner_is_wstring]@
        ros_resp.@(resp_field.name).push_back(value.toStdWString());
@[    elif rs_seq_inner_qt and rs_seq_inner_qt.startswith('Q') and not rs_seq_inner_qt.startswith('QList')]@
        ros_resp.@(resp_field.name).push_back(static_cast<@(rs_seq_inner_cpp)>(value));
@[    else]@
        ros_resp.@(resp_field.name).push_back(value);
@[    end if]@
    }
@[  elif rs_qt_type == 'QString']@
    ros_resp.@(resp_field.name) = response.toStdString();
@[  elif rs_is_nested]@
    ros_resp.@(resp_field.name) = static_cast<@(rs_nested_ros_type)>(response);
@[  elif rs_qt_type.startswith('Q') and not rs_qt_type.startswith('QList')]@
    ros_resp.@(resp_field.name) = static_cast<@(rs_cpp_type)>(response);
@[  else]@
    ros_resp.@(resp_field.name) = response;
@[  end if]@

    try {
        rmw_request_id_t id = requestId;
        m_service->send_response(id, ros_resp);
    } catch (const std::exception& e) {
        qWarning() << "@(qt_class_name)ServiceServer: failed to send response:" << e.what();
    }
}

@[end if]@
void @(qt_class_name)ServiceServer::sendDefaultResponse(const rmw_request_id_t& requestId)
{
    if (!m_service) {
        return;
    }

    @(ros_srv_type)::Response ros_resp{};
    try {
        rmw_request_id_t id = requestId;
        m_service->send_response(id, ros_resp);
    } catch (const std::exception& e) {
        qWarning() << "@(qt_class_name)ServiceServer: failed to send response:" << e.what();
    }
}

} // namespace @(qt_namespace)
