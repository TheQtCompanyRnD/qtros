// Copyright (C) 2026 The Qt Company Ltd.
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
from rosidl_generator_qtros2 import get_qml_value_type_name
from rosidl_generator_qtros2.template_helpers import (
    build_message_context,
    build_value_type_descriptors,
    extract_doc_info,
    value_type_brief_override,
    value_type_extra_doc,
)

context = build_message_context(package_name, message)
qt_namespace = context['qt_namespace']
qt_class_name = context['qt_class_name']
qml_value_type_name = get_qml_value_type_name(package_name, message.structure.namespaced_type.name)
ros_msg_type = context['ros_msg_type']
header_file = context['header_file']
header_subdir = qtros2_interface_subdir if 'qtros2_interface_subdir' in locals() and qtros2_interface_subdir else 'msg'
emit_wrapper_flag = emit_wrapper if 'emit_wrapper' in locals() else True
value_helpers = build_value_type_descriptors(package_name, message)
field_infos = value_helpers['field_infos']
post_init_lines = value_helpers['post_init_lines']
qml_module_uri = 'QtRos2.' + ''.join(w.capitalize() for w in package_name.split('_'))
doc_info = extract_doc_info(message, interface_path=interface_path)
_brief_override = value_type_brief_override(package_name, message)
msg_brief = _brief_override or doc_info['brief']
msg_brief_continuation = [] if _brief_override else doc_info['brief_continuation']
msg_details = doc_info['details']
field_docs = doc_info['field_docs']
deprecated = doc_info['deprecated']
deprecated_since = doc_info['deprecated_since']
deprecated_tag = ('[' + deprecated_since + '] ') if deprecated_since else ''
extra_type_doc = value_type_extra_doc(package_name, message)
}@
#include "@(header_file).hpp"
@[for info in field_infos]@
@[  if info.get('extra_cpp_includes')]@
@[    for inc in info['extra_cpp_includes']]@
#include @(inc)
@[    end for]@
@[  end if]@
@[end for]@

@[if emit_wrapper_flag]@
/*!
    \qmlvaluetype @(qml_value_type_name)
    \inqmlmodule @(qml_module_uri)
@[if msg_brief]@
    \brief @(msg_brief)
@[for line in msg_brief_continuation]@
    @(line)
@[end for]@
@[else]@
    \brief Qt value type wrapper for \c @(ros_msg_type) ROS 2 messages.
@[end if]@
@[if deprecated]@
    \deprecated @(deprecated_tag)
@[end if]@

@[for line in msg_details]@
    @(line)
@[end for]@
@[if msg_details]@

@[end if]@
    @(qml_value_type_name) is a structured value type usable in QML.
    It maps directly to the \c @(ros_msg_type) ROS 2 message type.
@[for paragraph in extra_type_doc]@

@[  for line in paragraph]@
    @(line)
@[  end for]@
@[end for]@

    \sa @(qt_class_name)Publisher, @(qt_class_name)Subscriber
*/

@[for info in field_infos]@
@{
_field_name = info.get('name')
_explicit_brief = info.get('brief_doc')
_explicit_body = info.get('doc_lines')
if _explicit_brief or _explicit_body:
    _field_brief = _explicit_brief
    _field_body_lines = list(_explicit_body or [])
else:
    _ros_lines = field_docs.get(_field_name, []) if _field_name else []
    _field_brief = _ros_lines[0] if _ros_lines else None
    _field_body_lines = list(_ros_lines[1:]) if len(_ros_lines) > 1 else []
_qt_prop = info.get('qt_prop_name') or _field_name
_qt_type = info.get('qt_type') or 'var'
_qml_doc_type = info.get('qml_doc_type') or _qt_type
_emit_prop_doc = bool(_qt_prop) and ((not info.get('is_computed')) or info.get('property_spec'))
}@
@[  if _emit_prop_doc]@
/*!
    \qmlproperty @(_qml_doc_type) @(qml_value_type_name)::@(_qt_prop)
@[    if _field_brief]@
    \brief @(_field_brief)
@[      if _field_body_lines]@

@[        for line in _field_body_lines]@
    @(line)
@[        end for]@
@[      end if]@
@[    end if]@
*/

@[  end if]@
@[  for m in info.get('qml_methods') or []]@
@[    if not m.get('static_factory')]@
/*!
    \qmlmethod @(m['signature'])
@[      if m.get('brief')]@
    \brief @(m['brief'])
@[        if m.get('body')]@

@[          for line in m['body']]@
    @(line)
@[          end for]@
@[        end if]@
@[      end if]@
*/

@[    end if]@
@[  end for]@
@[end for]@

@{_nc = [i for i in field_infos if not i.get('is_computed')]}@
@(qt_namespace)::@(qt_class_name)::@(qt_class_name)(const @(ros_msg_type)& ros)
@[if _nc]@
        :
@[for idx, info in enumerate(_nc)]@
@{
comma = '' if idx == len(_nc) - 1 else ','
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
    elif info.get('nested_mapping'):
        init_expr = f'm_{info["name"]}({info["nested_mapping"]["from_ros"]("ros." + info["name"])})'
    else:
        init_expr = f'm_{info["name"]}(ros.{info["name"]})'
}@
          @(init_expr)@(comma)
@[end for]@
@[end if]@  @# end if _nc
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
@[for info in _nc]@
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
@[    elif info.get('sequence_inner_mapping')]@
            ros.@(info['name'])[idx] = @(info['sequence_inner_mapping']['to_ros'](info['sequence_ros_value_type'], 'm_' + info['name'] + '[static_cast<int>(idx)]'));
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
@[    if info.get('sequence_inner_mapping')]@
        ros.@(info['name']).push_back(@(info['sequence_inner_mapping']['to_ros'](info['sequence_ros_value_type'], 'value')));
@[    else]@
        ros.@(info['name']).push_back(static_cast<@(info['sequence_ros_value_type'])>(value));
@[    end if]@
    }
@[  end if]@
@[elif info['is_nested']]@
@[  if info.get('nested_mapping')]@
    ros.@(info['name']) = @(info['nested_mapping']['to_ros'](info['nested_ros_type'], 'm_' + info['name']));
@[  else]@
    ros.@(info['name']) = static_cast<@(info['nested_ros_type'])>(m_@(info['name']));
@[  end if]@
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
@[for info in field_infos]@
@[  if info.get('cpp_impl')]@

@(info['cpp_impl'])
@[  end if]@
@[end for]@

@[end if]@
