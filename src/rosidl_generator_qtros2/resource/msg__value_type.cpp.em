// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for Qt value type (Q_GADGET) implementation
@# ===================================================
@#
@# Template arguments:
@# - package_name
@# - interface_path
@# - message
@# - spec
@{
from rosidl_generator_qtros2 import get_qt_namespace
from rosidl_generator_qtros2.template_helpers import (
    build_message_context,
    build_value_type_descriptors,
)

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
ros_msg_type = context['ros_msg_type']
header_file = context['header_file']
header_subdir = qtros2_interface_subdir if 'qtros2_interface_subdir' in locals() and qtros2_interface_subdir else 'msg'
emit_wrapper_flag = emit_wrapper if 'emit_wrapper' in locals() else True
value_helpers = build_value_type_descriptors(package_name, message)
field_infos = value_helpers['field_infos']
post_init_lines = value_helpers['post_init_lines']
}@
#include "@(package_name)/@(header_subdir)/@(header_file).hpp"

@[if emit_wrapper_flag]@
@(qt_namespace)::@(qt_class_name)::@(qt_class_name)(const @(ros_msg_type)& ros)
@[if field_infos]@
        :
@[for idx, info in enumerate(field_infos)]@
@{
comma = '' if idx == len(field_infos) - 1 else ','
if info['is_sequence']:
    if info['is_qbytearray']:
        init_expr = f'm_{info["name"]}(reinterpret_cast<const char*>(ros.{info["name"]}.data()), static_cast<int>(ros.{info["name"]}.size()))'
    elif info['is_qstring_list']:
        init_expr = f'm_{info["name"]}()'
    elif info['sequence_inner_is_nested']:
        init_expr = f'm_{info["name"]}()'
    elif info['sequence_inner_is_string'] or info['sequence_inner_is_wstring']:
        init_expr = f'm_{info["name"]}()'
    else:
        init_expr = f'm_{info["name"]}(ros.{info["name"]}.begin(), ros.{info["name"]}.end())'
else:
    if info['is_wstring']:
        init_expr = f'm_{info["name"]}(QString::fromStdWString(ros.{info["name"]}))'
    elif info['is_string']:
        init_expr = f'm_{info["name"]}(QString::fromStdString(ros.{info["name"]}))'
    else:
        init_expr = f'm_{info["name"]}(ros.{info["name"]})'
}@
          @(init_expr)@(comma)
@[end for]@
@[end if]@
@[if post_init_lines]@
{
@[for line in post_init_lines]@
@(line)
@[end for]@
}
@[else]@
{}
@[end if]@

@(qt_namespace)::@(qt_class_name)::operator @(ros_msg_type)() const
{
    @(ros_msg_type) ros;
@[for info in field_infos]@
@[if info['is_sequence']]@
@[  if info['is_array']]@
    {
        const size_t qt_size = static_cast<size_t>(m_@(info['name']).size());
        const size_t ros_size = ros.@(info['name']).size();
        const size_t copy_count = (qt_size < ros_size) ? qt_size : ros_size;
        size_t idx = 0;
        for (; idx < copy_count; ++idx) {
@[    if info['sequence_inner_is_string']]@
            ros.@(info['name'])[idx] = m_@(info['name'])[static_cast<int>(idx)].toStdString();
@[    elif info['sequence_inner_is_wstring']]@
            ros.@(info['name'])[idx] = m_@(info['name'])[static_cast<int>(idx)].toStdWString();
@[    else]@
            ros.@(info['name'])[idx] = static_cast<@(info['sequence_ros_value_type'])>(m_@(info['name'])[static_cast<int>(idx)]);
@[    end if]@
        }
        for (; idx < ros_size; ++idx) {
            ros.@(info['name'])[idx] = @(info['sequence_ros_value_type']){};
        }
    }
@[  elif info['is_qbytearray']]@
    ros.@(info['name']).assign(
        reinterpret_cast<const uint8_t*>(m_@(info['name']).constData()),
        reinterpret_cast<const uint8_t*>(m_@(info['name']).constData()) + m_@(info['name']).size()
    );
@[  elif info['is_qstring_list']]@
    ros.@(info['name']).clear();
    ros.@(info['name']).reserve(m_@(info['name']).size());
    for (const auto& value : m_@(info['name'])) {
        ros.@(info['name']).push_back(@(info['string_to_ros']));
    }
@[  else]@
    ros.@(info['name']).clear();
    ros.@(info['name']).reserve(m_@(info['name']).size());
    for (const auto& value : m_@(info['name'])) {
        ros.@(info['name']).push_back(static_cast<@(info['sequence_ros_value_type'])>(value));
    }
@[  end if]@
@[elif info['is_nested']]@
    ros.@(info['name']) = static_cast<@(info['nested_ros_type'])>(m_@(info['name']));
@[elif info['is_wstring']]@
    ros.@(info['name']) = m_@(info['name']).toStdWString();
@[elif info['is_string']]@
    ros.@(info['name']) = m_@(info['name']).toStdString();
@[else]@
    ros.@(info['name']) = m_@(info['name']);
@[end if]@
@[end for]@
    return ros;
}

@[end if]@
