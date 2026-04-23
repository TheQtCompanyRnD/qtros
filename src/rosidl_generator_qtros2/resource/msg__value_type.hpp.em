// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt value type (Q_GADGET) header
@# ===================================================
@#
@# Template arguments:
@# - package_name
@# - interface_path
@# - message
@# - spec
@{
from rosidl_generator_qtros2 import (
    get_qml_value_type_name,
    get_single_field_type,
    msg_type_to_qt_full,
    snake_to_camel,
    to_snake_case,
)
from rosidl_parser.definition import BasicType
from rosidl_generator_qtros2.template_helpers import (
    build_include_guard,
    build_message_context,
    build_value_type_descriptors,
)

ros_override = ros_include_override if 'ros_include_override' in locals() else None
context = build_message_context(package_name, message, ros_include_override=ros_override)
value_helpers = build_value_type_descriptors(package_name, message)

qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
ros_msg_type = context['ros_msg_type']
ros_include = context['ros_include']
nested_includes = value_helpers['nested_includes']
field_infos = value_helpers['field_infos']
post_init_lines = value_helpers['post_init_lines']
qml_value_type_name = get_qml_value_type_name(package_name, message.structure.namespaced_type.name)
emit_wrapper_flag = emit_wrapper if 'emit_wrapper' in locals() else True
single_field_qt_type = get_single_field_type(message, package_name)
header_guard = build_include_guard(package_name, 'msg', context['header_file'])
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

#include <QObject>
#include <QQmlEngine>
#include <QString>
#include <QList>
#include <QByteArray>
#include <@(ros_include)>
@[for pkg, msg_name, is_cross in nested_includes]@
@[  if is_cross]@
#include <@(qt_package_mapping.get(pkg, f'qtros2_{pkg}'))/msg/@(to_snake_case(msg_name)).hpp>
@[  else]@
#include "@(to_snake_case(msg_name)).hpp"
@[  end if]@
@[end for]@
@[for info in field_infos]@
@[  if info.get('extra_includes')]@
@[    for inc in info['extra_includes']]@
#include @(inc)
@[    end for]@
@[  end if]@
@[end for]@

namespace @(qt_namespace) {

@[if emit_wrapper_flag]@
/**
 * @@brief Qt wrapper for @(ros_msg_type)
 *
 * This is a Q_GADGET value type that can be used in QML.
 * It provides bidirectional conversion with the ROS message type.
 */
class @(qt_export_macro) @(qt_class_name)
{
    Q_GADGET
    QML_VALUE_TYPE(@(qml_value_type_name))
    QML_STRUCTURED_VALUE

@[for info in field_infos]@
@[  if info.get('is_computed')]@
    @(info['property_spec'])
@[  else]@
    Q_PROPERTY(@(info['qt_type']) @(info['qt_prop_name']) MEMBER m_@(info['name']))
@[  end if]@
@[end for]@

public:
    @(qt_class_name)() = default;

    /**
     * @@brief Implicit conversion FROM ROS message
     *
     * Allows automatic conversion from ROS messages to Qt types.
     */
    @(qt_class_name)(const @(ros_msg_type)& ros);

    /**
     * @@brief Explicit conversion TO ROS message
     *
     * Converts this Qt type back to a ROS message.
     */
    explicit operator @(ros_msg_type)() const;

    // Equality operators
@{
eq_terms = [f'm_{field.name} == other.m_{field.name}' for field in message.structure.members]
eq_expr = ' && '.join(eq_terms) if eq_terms else 'true'
}@
    bool operator==(const @(qt_class_name)& other) const
    {
        return @(eq_expr);
    }

    bool operator!=(const @(qt_class_name)& other) const
    {
        return !(*this == other);
    }

    // Getters
@[for field in message.structure.members]@
@{
qt_type = msg_type_to_qt_full(field.type)
qt_prop_name = snake_to_camel(field.name)
}@
    @(qt_type) @(qt_prop_name)() const { return m_@(field.name); }
@[end for]@

    // Setters
@[for field in message.structure.members]@
@{
qt_type = msg_type_to_qt_full(field.type)
qt_prop_name = snake_to_camel(field.name)
setter_name = 'set' + qt_prop_name[0].upper() + qt_prop_name[1:]
}@
    void @(setter_name)(const @(qt_type)& @(field.name)) { m_@(field.name) = @(field.name); }
@[end for]@
@{_computed = [i for i in field_infos if i.get('is_computed')]}@
@[if _computed]@

    // Computed Qt properties (not part of the ROS message)
@[  for info in _computed]@
    @(info['getter_decl'])
@[    if info.get('setter_decl')]@
    @(info['setter_decl'])
@[    end if]@
@[  end for]@
@[end if]@

private:
@[for info in field_infos]@
@[  if not info.get('is_computed')]@
@{
qt_type = info['qt_type']
default_val = ''
if not info['is_sequence']:
    field_type_inner = info['field'].type
    if isinstance(field_type_inner, BasicType):
        if field_type_inner.typename == 'boolean':
            default_val = ' = false'
        elif field_type_inner.typename in ['float', 'double', 'long double']:
            default_val = ' = 0.0'
        elif 'int' in field_type_inner.typename:
            default_val = ' = 0'
}@
    @(qt_type) m_@(info['name'])@(default_val);
@[  end if]@
@[end for]@
};
@[else]@
/**
 * @@brief No Qt wrapper generated for @(ros_msg_type)
 *
 * This service/action interface carries a single field, so the direct Qt type
 * should be used when talking to QML/Qt.
 */
@[  if single_field_qt_type != 'void']@
using @(qt_class_name) = @(single_field_qt_type);
@[  else]@
// This interface has no meaningful payload.
@[  end if]@
@[end if]@

} // namespace @(qt_namespace)

@[if emit_wrapper_flag]@
Q_DECLARE_METATYPE(@(qt_namespace)::@(qt_class_name))
@[end if]

#endif // @(header_guard)
