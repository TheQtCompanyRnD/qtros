// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt service client implementation
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

# Determine template type for QFuture/QPromise
if resp_class == 'void':
    future_type = 'void'
    future_type_full = 'void'
    has_result = False
else:
    future_type = resp_class
    future_type_full = resp_class_full
    has_result = True

# Get request and response members for conversion
req_members = []
if hasattr(request_msg, 'structure') and hasattr(request_msg.structure, 'members'):
    req_members = [m for m in request_msg.structure.members if m.name != 'structure_needs_at_least_one_member']

resp_members = []
if hasattr(response_msg, 'structure') and hasattr(response_msg.structure, 'members'):
    resp_members = [m for m in response_msg.structure.members if m.name != 'structure_needs_at_least_one_member']
qml_module_uri = get_qml_module_uri(package_name)
req_param_qml = ('const ' + req_class_qml + '& request') if req_param else ''
resp_param_doc = resp_class_qml + ' response' if resp_class != 'void' else ''
req_l_type = ('\\l ' + req_class_qml) if req_needs_wrap else req_class_qml
resp_l_type = ('\\l ' + resp_class_qml) if resp_needs_wrap else resp_class_qml
with_request_phrase = (' with ' + req_l_type + ' \\a request') if req_param_qml else ''
resp_resolves_phrase = ('resolves with a ' + resp_l_type + ' response') if resp_class != 'void' else 'resolves'
}@
#include "@(service_header)_service_client.hpp"
#include <QtRos2Core/private/qros2node_p.h>
#if !defined(QTROS2_EXPERIMENTAL_FUTURE)
#include <QtRos2Core/private/jsfuturewrapper_p.h>
#include <QQmlEngine>
#endif
#include <QCoreApplication>
#include <QByteArray>
#include <QDebug>
#include <QPointer>
#include <memory>

namespace @(qt_namespace) {

/*!
    \qmltype @(qt_class_name)ServiceClient
    \inqmlmodule @(qml_module_uri)
    \inherits ServiceClientBase
    \brief Qt service client for the @(service_name) ROS 2 service.

    @(qt_class_name)ServiceClient calls a ROS 2 service.
    Set the \c topic and \c node properties, then call \c callService() to invoke the service.
*/

/*!
    \qmlmethod QJSValue @(qt_class_name)ServiceClient::callService(@(req_param_qml))

    Calls the \c @(service_name) ROS 2 service@(with_request_phrase).
    Returns a JS promise that @(resp_resolves_phrase) or rejects with an error string.
    \l isServiceReady must be \c true before calling.
*/

@[if resp_param_doc]@
/*!
    \qmlsignal @(qt_class_name)ServiceClient::responseReceived(@(resp_param_doc))

    Emitted when the service call completes successfully.
    \a response is a @(resp_l_type) value.
*/
@[else]@
/*!
    \qmlsignal @(qt_class_name)ServiceClient::responseReceived()

    Emitted when the service call completes successfully.
*/
@[end if]@

/*!
    \qmlsignal @(qt_class_name)ServiceClient::callFailed(string error)

    Emitted when the service call fails. \a error contains the error message.
*/

@(qt_class_name)ServiceClient::@(qt_class_name)ServiceClient(QObject* parent)
    : QRos2ServiceClientBase(parent)
{
}

@(qt_class_name)ServiceClient::~@(qt_class_name)ServiceClient()
{
}

void @(qt_class_name)ServiceClient::setupConnection()
{
    // Clear existing connection before creating a new one
    if (m_client) {
        m_client.reset();
    }

    if (!node() || !node()->rosNode() || m_topic.isEmpty()) {
        return;
    }

    m_client = node()->rosNode()->create_client<@(ros_srv_type)>(m_topic.toStdString(), qos());
}

void @(qt_class_name)ServiceClient::checkHealth()
{
    if (!m_client) {
        setServiceReady(false);
        return;
    }

    try {
        bool ready = m_client->service_is_ready();
        setServiceReady(ready);
    } catch (const std::exception&) {
        setServiceReady(false);
    }
}

void @(qt_class_name)ServiceClient::clearConnection()
{
    m_client.reset();
}

@[if future_type == 'void']@
@[  if req_param]@
QFuture<void> @(qt_class_name)ServiceClient::callServiceFuture(@(req_param), const std::shared_ptr<QString>& lastError)
@[  else]@
QFuture<void> @(qt_class_name)ServiceClient::callServiceFuture(const std::shared_ptr<QString>& lastError)
@[  end if]@
@[else]@
@[  if req_param]@
QFuture<@(future_type_full)> @(qt_class_name)ServiceClient::callServiceFuture(@(req_param), const std::shared_ptr<QString>& lastError)
@[  else]@
QFuture<@(future_type_full)> @(qt_class_name)ServiceClient::callServiceFuture(const std::shared_ptr<QString>& lastError)
@[  end if]@
@[end if]@
{
    if (!m_client) {
@[if future_type == 'void']@
        return makeRejectedFuture<void>(QStringLiteral("@(qt_class_name)ServiceClient not initialized"));
@[else]@
        return makeRejectedFuture<@(future_type_full)>(QStringLiteral("@(qt_class_name)ServiceClient not initialized"));
@[end if]@
    }

    if (!isServiceReady()) {
@[if future_type == 'void']@
        return makeRejectedFuture<void>(QStringLiteral("Service not available yet"));
@[else]@
        return makeRejectedFuture<@(future_type_full)>(QStringLiteral("Service not available yet"));
@[end if]@
    }

@[if future_type == 'void']@
    auto promise = std::make_shared<QPromise<void>>();
@[else]@
    auto promise = std::make_shared<QPromise<@(future_type_full)>>();
@[end if]@
    auto future = promise->future();

    auto ros_req = std::make_shared<@(ros_srv_type)::Request>();
@[if req_needs_wrap]@
@# Wrapper type - use conversion operator
    *ros_req = static_cast<@(ros_srv_type)::Request>(request);
@[elif req_members]@
@# Single field - direct conversion
@{
field = req_members[0]
qt_type = msg_type_to_qt(field.type)
cpp_type = msg_type_to_cpp(field.type)
from rosidl_parser.definition import (
    NamespacedType,
    AbstractNestedType,
    Array,
    BoundedSequence,
    UnboundedSequence,
    AbstractString,
    AbstractWString,
)
field_type = field.type
base_field_type = field_type
if isinstance(base_field_type, AbstractNestedType):
    base_field_type = base_field_type.value_type
is_nested = isinstance(base_field_type, NamespacedType)
if is_nested:
    nested_ros_type = '::'.join(base_field_type.namespaces + [base_field_type.name])
is_array = isinstance(field_type, Array)
is_bounded_sequence = isinstance(field_type, BoundedSequence)
is_unbounded_sequence = isinstance(field_type, UnboundedSequence)
is_sequence_like = is_array or is_bounded_sequence or is_unbounded_sequence
sequence_inner_type = field_type.value_type if is_sequence_like else None
if isinstance(sequence_inner_type, AbstractNestedType):
    sequence_inner_type = sequence_inner_type.value_type
sequence_inner_qt = msg_type_to_qt(sequence_inner_type) if sequence_inner_type else None
sequence_inner_cpp = msg_type_to_cpp(sequence_inner_type) if sequence_inner_type else None
sequence_inner_is_nested = isinstance(sequence_inner_type, NamespacedType) if sequence_inner_type else False
sequence_inner_is_string = isinstance(sequence_inner_type, AbstractString) if sequence_inner_type else False
sequence_inner_is_wstring = isinstance(sequence_inner_type, AbstractWString) if sequence_inner_type else False
request_is_qbytearray = (qt_type == 'QByteArray')
request_is_qstringlist = (qt_type == 'QStringList')
request_is_qlist = qt_type.startswith('QList<')
}@
@[  if request_is_qbytearray]@
    ros_req->@(field.name).assign(
        reinterpret_cast<const uint8_t*>(request.constData()),
        reinterpret_cast<const uint8_t*>(request.constData()) + request.size()
    );
@[  elif request_is_qstringlist]@
    ros_req->@(field.name).clear();
    ros_req->@(field.name).reserve(request.size());
    for (const auto& value : request) {
@[    if sequence_inner_is_wstring]@
        ros_req->@(field.name).push_back(value.toStdWString());
@[    else]@
        ros_req->@(field.name).push_back(value.toStdString());
@[    end if]@
    }
@[  elif is_array]@
    {
        const int req_size = request.size();
        const int ros_size = static_cast<int>(ros_req->@(field.name).size());
        const int maxCount = (req_size < ros_size) ? req_size : ros_size;
        for (int idx = 0; idx < maxCount; ++idx) {
@[    if sequence_inner_is_nested]@
            ros_req->@(field.name)[idx] = static_cast<@(sequence_inner_cpp)>(request[idx]);
@[    elif sequence_inner_is_string]@
            ros_req->@(field.name)[idx] = request[idx].toStdString();
@[    elif sequence_inner_is_wstring]@
            ros_req->@(field.name)[idx] = request[idx].toStdWString();
@[    elif sequence_inner_qt and sequence_inner_qt.startswith('Q') and not sequence_inner_qt.startswith('QList')]@
            ros_req->@(field.name)[idx] = static_cast<@(sequence_inner_cpp)>(request[idx]);
@[    else]@
            ros_req->@(field.name)[idx] = request[idx];
@[    end if]@
        }
        for (size_t idx = maxCount; idx < ros_req->@(field.name).size(); ++idx) {
            ros_req->@(field.name)[idx] = @(sequence_inner_cpp)();
        }
    }
@[  elif is_sequence_like]@
    ros_req->@(field.name).clear();
    ros_req->@(field.name).reserve(request.size());
    for (const auto& value : request) {
@[    if sequence_inner_is_nested]@
        ros_req->@(field.name).push_back(static_cast<@(sequence_inner_cpp)>(value));
@[    elif sequence_inner_is_string]@
        ros_req->@(field.name).push_back(value.toStdString());
@[    elif sequence_inner_is_wstring]@
        ros_req->@(field.name).push_back(value.toStdWString());
@[    elif sequence_inner_qt and sequence_inner_qt.startswith('Q') and not sequence_inner_qt.startswith('QList')]@
        ros_req->@(field.name).push_back(static_cast<@(sequence_inner_cpp)>(value));
@[    else]@
        ros_req->@(field.name).push_back(value);
@[    end if]@
    }
@[  elif qt_type == 'QString']@
    ros_req->@(field.name) = request.toStdString();
@[  elif is_nested]@
    ros_req->@(field.name) = static_cast<@(nested_ros_type)>(request);
@[  elif qt_type.startswith('Q') and not qt_type.startswith('QList')]@
    ros_req->@(field.name) = static_cast<@(cpp_type)>(request);
@[  else]@
    ros_req->@(field.name) = request;
@[  end if]@
@[end if]@

    setCallPending(true);

    auto weakThis = QPointer<@(qt_class_name)ServiceClient>(this);
    const auto reportError = [weakThis, promise, lastError](const QString& msg) {
        if (lastError) {
            *lastError = msg;
        }
        if (weakThis) {
            QMetaObject::invokeMethod(
                qApp,
                [weakThis] {
                    if (!weakThis)
                        return;
                    weakThis->setCallPending(false);
                },
                Qt::QueuedConnection);
        }
        promise->setException(QRos2ServiceClientBase::makeException(msg));
        promise->finish();
    };

    m_client->async_send_request(
        ros_req,
        [weakThis, promise, reportError](rclcpp::Client<@(ros_srv_type)>::SharedFuture rosFuture) {
            if (!weakThis) {
                reportError(QStringLiteral("@(qt_class_name)ServiceClient destroyed"));
                return;
            }

            try {
@[if resp_members]@
@# Response has data - need to extract it
                auto resp = rosFuture.get();
@{
field = resp_members[0]
qt_type = msg_type_to_qt(field.type)
cpp_type = msg_type_to_cpp(field.type)
field_type = field.type
is_sequence = isinstance(field_type, (BoundedSequence, UnboundedSequence))
is_array = isinstance(field_type, Array)
sequence_like = is_sequence or is_array
sequence_value_type = field_type.value_type if sequence_like else None
sequence_inner_qt = msg_type_to_qt(sequence_value_type) if sequence_value_type else None
sequence_inner_is_nested = isinstance(sequence_value_type, NamespacedType) if sequence_value_type else False
sequence_inner_is_string = isinstance(sequence_value_type, AbstractString)
sequence_inner_is_wstring = isinstance(sequence_value_type, AbstractWString)
resp_is_qbytearray = (resp_class_full == 'QByteArray')
resp_is_qstringlist = (resp_class_full == 'QStringList')
resp_is_qlist = resp_class_full.startswith('QList<')
resp_result_is_list = resp_is_qlist or resp_is_qstringlist
}@
@[  if resp_needs_wrap]@
@# Multi-field response - need wrapper conversion (TODO: implement wrapper response types)
                const @(resp_class) result = static_cast<@(resp_class)>(*resp);
@[  elif resp_is_qbytearray]@
@# Convert binary data to QByteArray
                @(future_type_full) result(reinterpret_cast<const char*>(resp->@(field.name).data()),
                                   static_cast<int>(resp->@(field.name).size()));
@[  elif resp_result_is_list]@
                @(future_type_full) result;
                result.reserve(resp->@(field.name).size());
                for (const auto& ros_item : resp->@(field.name)) {
@[    if sequence_inner_is_nested]@
                    result.append(@(sequence_inner_qt)(ros_item));
@[    elif sequence_inner_is_string]@
                    result.append(QString::fromStdString(ros_item));
@[    elif sequence_inner_is_wstring]@
                    result.append(QString::fromStdWString(ros_item));
@[    elif sequence_inner_qt]@
                    result.append(static_cast<@(sequence_inner_qt)>(ros_item));
@[    else]@
                    result.append(ros_item);
@[    end if]@
                }
@[  elif qt_type == 'QString']@
                const QString result = QString::fromStdString(resp->@(field.name));
@[  elif qt_type.startswith('Q') and not qt_type.startswith('QList')]@
                const @(qt_type) result = static_cast<@(qt_type)>(resp->@(field.name));
@[  else]@
                const @(qt_type) result = resp->@(field.name);
@[  end if]@
                promise->addResult(result);
                promise->finish();

                QMetaObject::invokeMethod(
                    qApp,
                    [weakThis, result] {
                        if (!weakThis)
                            return;
                        weakThis->setCallPending(false);
                        emit weakThis->responseReceived(result);
                    },
                    Qt::QueuedConnection);
@[else]@
@# Void response
                rosFuture.get();
@[end if]@
            } catch (const std::exception& e) {
                QString msg = QString::fromUtf8(e.what());
                if (msg.isEmpty())
                    msg = QStringLiteral("@(service_name) service call failed");
                reportError(msg);
                return;
            }
@[if not resp_members]@

            promise->finish();

            QMetaObject::invokeMethod(
                qApp,
                [weakThis] {
                    if (!weakThis)
                        return;
                    weakThis->setCallPending(false);
                    emit weakThis->responseReceived();
                },
                Qt::QueuedConnection);
@[end if]@
        });

    return future;
}

#ifdef QTROS2_EXPERIMENTAL_FUTURE
@[if future_type == 'void']@
QFuture<void> @(qt_class_name)ServiceClient::callService(@(req_param))
@[else]@
QFuture<@(future_type_full)> @(qt_class_name)ServiceClient::callService(@(req_param))
@[end if]@
{
@[if req_param]@
    return callServiceFuture(request);
@[else]@
    return callServiceFuture();
@[end if]@
}
#else
QJSValue @(qt_class_name)ServiceClient::callService(@(req_param))
{
    QQmlEngine* engine = qmlEngine(this);
    if (!engine) {
        return QJSValue();
    }
    auto errorMsg = std::make_shared<QString>();
@[if future_type == 'void']@
@[  if req_param]@
    return JsFutureWrapper::fromFuture<void>(engine, callServiceFuture(request, errorMsg), this, errorMsg);
@[  else]@
    return JsFutureWrapper::fromFuture<void>(engine, callServiceFuture(errorMsg), this, errorMsg);
@[  end if]@
@[else]@
@[  if req_param]@
    return JsFutureWrapper::fromFuture<@(future_type_full)>(engine, callServiceFuture(request, errorMsg), this, errorMsg);
@[  else]@
    return JsFutureWrapper::fromFuture<@(future_type_full)>(engine, callServiceFuture(errorMsg), this, errorMsg);
@[  end if]@
@[end if]@
}
#endif

} // namespace @(qt_namespace)
