// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt service server header
@{
from rosidl_generator_qtros2 import get_qt_class_name, get_qt_class_name_full, get_qt_namespace, get_single_field_include, to_snake_case
from rosidl_generator_qtros2.template_helpers import build_include_guard

qt_namespace = get_qt_namespace(package_name)
service_name = service.namespaced_type.name
base_name = to_snake_case(service_name)
qt_class_name = get_qt_class_name(package_name, service_name)

# Get request and response
request_msg = service.request_message
response_msg = service.response_message

# Check if wrappers needed
req_needs_wrap = needs_wrapper_type(request_msg)
resp_needs_wrap = needs_wrapper_type(response_msg)

# Compute types and includes
if req_needs_wrap:
    req_class = get_qt_class_name(package_name, request_msg.structure.namespaced_type.name)
    req_class_full = get_qt_class_name_full(package_name, request_msg.structure.namespaced_type.name)
    req_include = f'<{qt_module_name}/srv/{to_snake_case(request_msg.structure.namespaced_type.name)}.hpp>'
    req_param = 'const ' + req_class_full + '& request'
else:
    req_class = get_single_field_type(request_msg, package_name)
    req_class_full = req_class
    # Check if single-field type needs an include
    req_field_info = get_single_field_include(request_msg, package_name)
    if req_field_info:
        pkg, msg_name, is_cross = req_field_info
        include_target = qt_package_mapping.get(pkg, f'qtros2_{pkg}') if is_cross else qt_module_name
        req_include = f'<{include_target}/msg/{to_snake_case(msg_name)}.hpp>'
    else:
        req_include = None

    if req_class != 'void':
        req_param = 'const ' + req_class + '& request'
    else:
        req_param = ''

if resp_needs_wrap:
    resp_class = get_qt_class_name(package_name, response_msg.structure.namespaced_type.name)
    resp_class_full = get_qt_class_name_full(package_name, response_msg.structure.namespaced_type.name)
    resp_include = f'<{qt_module_name}/srv/{to_snake_case(response_msg.structure.namespaced_type.name)}.hpp>'
else:
    resp_class = get_single_field_type(response_msg, package_name)
    resp_class_full = resp_class
    # Check if single-field type needs an include
    resp_field_info = get_single_field_include(response_msg, package_name)
    if resp_field_info:
        pkg, msg_name, is_cross = resp_field_info
        include_target = qt_package_mapping.get(pkg, f'qtros2_{pkg}') if is_cross else qt_module_name
        resp_include = f'<{include_target}/msg/{to_snake_case(msg_name)}.hpp>'
    else:
        resp_include = None

if resp_class != 'void':
    resp_param = 'const ' + resp_class_full + '& response'
else:
    resp_param = ''

# ROS types
ns_list = service.namespaced_type.namespaces
name_list = ns_list + [service.namespaced_type.name]
ros_srv_type = '::'.join(name_list)
ros_package = ns_list[0] if ns_list else package_name
ros_include = ros_package + '/srv/' + to_snake_case(service_name) + '.hpp'
header_guard = build_include_guard(package_name, 'srv', base_name + '_service_server')
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

#include <QtRos2Core/private/qros2serviceserverbase_p.h>
@[if req_include]@
#include @(req_include)
@[end if]@
@[if resp_include and resp_include != req_include]@
#include @(resp_include)
@[end if]@
#ifndef Q_QDOC
#include <@(ros_include)>
#include <rclcpp/rclcpp.hpp>
#endif
#include <QPointer>
#include <memory>

namespace @(qt_namespace) {

class @(qt_class_name)ServiceServer;

/*!
 * @@brief Reply handle for one pending @(ros_srv_type) request.
 *
 * Passed to the server's handler; call send() to answer the request.
 */
class @(qt_export_macro) @(qt_class_name)ServiceReply : public QObject
{
    Q_OBJECT
    QML_ANONYMOUS

public:
#ifndef Q_QDOC
    explicit @(qt_class_name)ServiceReply(@(qt_class_name)ServiceServer* server,
                                          const rmw_request_id_t& requestId,
                                          QObject* parent = nullptr);
#endif

@[if resp_param]@
    Q_INVOKABLE void send(@(resp_param));
@[else]@
    Q_INVOKABLE void send();
@[end if]@
    bool isSent() const { return m_sent; }

private:
    friend class @(qt_class_name)ServiceServer;
    QPointer<@(qt_class_name)ServiceServer> m_server;
#ifndef Q_QDOC
    rmw_request_id_t m_requestId;
#endif
    bool m_sent = false;
};

/*!
 * @@brief Qt service server for @(ros_srv_type)
 *
 * Answers @(service_name) requests from QML via the inherited
 * handler property. Can be used directly in QML.
 */
class @(qt_export_macro) @(qt_class_name)ServiceServer : public QRos2ServiceServerBase
{
    Q_OBJECT
    QML_ELEMENT

public:
    explicit @(qt_class_name)ServiceServer(QObject* parent = nullptr);
    ~@(qt_class_name)ServiceServer() override;

Q_SIGNALS:
@[if req_param]@
    void requestReceived(@(req_param));
@[else]@
    void requestReceived();
@[end if]@

protected:
    void setupConnection() override;
    void clearConnection() override;
    void checkHealth() override;

private:
    friend class @(qt_class_name)ServiceReply;
#ifndef Q_QDOC
    // Runs on the GUI thread (queued from the executor thread).
    void dispatchRequest(const std::shared_ptr<rmw_request_id_t>& requestId,
                         const std::shared_ptr<@(ros_srv_type)::Request>& request);
@[  if resp_param]@
    void sendResponse(const rmw_request_id_t& requestId, @(resp_param));
@[  end if]@
    void sendDefaultResponse(const rmw_request_id_t& requestId);
    rclcpp::Service<@(ros_srv_type)>::SharedPtr m_service;
#endif
};

} // namespace @(qt_namespace)

#endif // @(header_guard)
