# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

from __future__ import annotations

import re
from typing import Any, Dict, List, Tuple

from rosidl_parser.definition import (
    AbstractNestedType,
    AbstractString,
    AbstractWString,
    Array,
    BoundedSequence,
    NamespacedType,
    UnboundedSequence,
)

from . import (
    get_qml_value_type_name,
    get_qt_class_name,
    get_qt_class_name_full,
    get_qt_namespace,
    msg_type_to_qt,
    msg_type_to_qt_full,
    msg_type_to_cpp,
    snake_to_camel,
    to_snake_case,
)


def get_qml_module_uri(package_name: str) -> str:
    """Compute the QML module URI for a ROS package (e.g. QtRos2.BuiltinInterfaces)."""
    return 'QtRos2.' + ''.join(w.capitalize() for w in package_name.split('_') if w)

NestedInclude = Tuple[str, str, bool]

# Computed (Qt-only) properties appended to field_infos for specific messages.
# cpp_impl_tmpl uses {ns}/{cls} as format placeholders; C++ braces are doubled.
_COMPUTED_PROPERTIES: Dict[str, List[Dict[str, Any]]] = {
    "sensor_msgs/CompressedImage": [
        {
            "is_computed": True,
            "name": "image",
            "qt_type": "QImage",
            "qt_prop_name": "image",
            "property_spec": "Q_PROPERTY(QImage image READ image WRITE setImage)",
            "getter_decl": "QImage image() const;",
            "setter_decl": "void setImage(const QImage& img);",
            "extra_includes": ["<QImage>"],
            "extra_cpp_includes": ["<QBuffer>"],
            "cpp_impl_tmpl": (
                "QImage {ns}::{cls}::image() const\n"
                "{{\n"
                "    return QImage::fromData(m_data);\n"
                "}}\n"
                "\n"
                "void {ns}::{cls}::setImage(const QImage& img)\n"
                "{{\n"
                "    const char* qtFmt = m_format.contains(QLatin1String(\"png\")) ? \"PNG\" : \"JPEG\";\n"
                "    m_data.clear();\n"
                "    QBuffer buf(&m_data);\n"
                "    buf.open(QIODevice::WriteOnly);\n"
                "    img.save(&buf, qtFmt);\n"
                "}}\n"
            ),
        }
    ],
    "sensor_msgs/Image": [
        {
            "is_computed": True,
            "name": "image",
            "qt_type": "QImage",
            "qt_prop_name": "image",
            "property_spec": "Q_PROPERTY(QImage image READ image)",
            "getter_decl": "QImage image() const;",
            "setter_decl": None,
            "extra_includes": ["<QImage>"],
            "extra_cpp_includes": [],
            "cpp_impl_tmpl": (
                "QImage {ns}::{cls}::image() const\n"
                "{{\n"
                "    if (m_data.isEmpty() || m_width == 0 || m_height == 0)\n"
                "        return {{}};\n"
                "    static const QHash<QString, QImage::Format> fmtMap = {{\n"
                "        {{ QStringLiteral(\"rgb8\"),   QImage::Format_RGB888     }},\n"
                "        {{ QStringLiteral(\"rgba8\"),  QImage::Format_RGBA8888   }},\n"
                "        {{ QStringLiteral(\"bgr8\"),   QImage::Format_BGR888     }},\n"
                "        {{ QStringLiteral(\"mono8\"),  QImage::Format_Grayscale8  }},\n"
                "        {{ QStringLiteral(\"mono16\"), QImage::Format_Grayscale16 }},\n"
                "    }};\n"
                "    const QImage::Format fmt = fmtMap.value(m_encoding, QImage::Format_Invalid);\n"
                "    if (fmt == QImage::Format_Invalid)\n"
                "        return {{}};\n"
                "    return QImage(reinterpret_cast<const uchar*>(m_data.constData()),\n"
                "                  static_cast<int>(m_width), static_cast<int>(m_height),\n"
                "                  static_cast<int>(m_step), fmt).copy();\n"
                "}}\n"
            ),
        }
    ],
}


def build_message_context(package_name: str, message_spec, *, ros_include_override: str | None = None) -> Dict[str, Any]:
    """Prepare commonly used identifiers for message templates."""
    ns_list = message_spec.structure.namespaced_type.namespaces
    msg_name = message_spec.structure.namespaced_type.name
    header_file = to_snake_case(msg_name)
    ros_include_parts = ns_list + [header_file]
    ros_include = ros_include_override or "/".join(ros_include_parts) + ".hpp"

    return {
        "qt_namespace": get_qt_namespace(package_name),
        "qt_class_name": get_qt_class_name(package_name, msg_name),
        "qt_class_name_full": get_qt_class_name_full(package_name, msg_name),
        "qml_value_type_name": get_qml_value_type_name(package_name, msg_name),
        "qml_module_uri": get_qml_module_uri(package_name),
        "ros_msg_type": "::".join(ns_list + [msg_name]),
        "ros_include": ros_include,
        "header_file": header_file,
        "value_type_include": f"{header_file}.hpp",
    }


# Per-message overrides for single-field pub/sub type.  Keys are "package/MessageName".
# These bypass the normal field-type inspection and return a fully specified info dict.
_SINGLE_FIELD_TYPE_OVERRIDES: Dict[str, Dict[str, Any]] = {
    # uint8[16] uuid → QString (RFC 4122 without braces, e.g. "xxxxxxxx-xxxx-xxxx-xxxx-xxxxxxxxxxxx").
    # QUuid is not a QML value type so using it as a Q_PROPERTY would give QML an opaque var.
    "unique_identifier_msgs/UUID": {
        "qt_type":      "QString",
        "field_name":   "uuid",
        "param_decl":   "const QString& uuid",
        "ros_to_qt":    "QUuid::fromRfc4122(QByteArray("
                        "reinterpret_cast<const char*>(msg->uuid.data()), 16))"
                        ".toString(QUuid::WithoutBraces)",
        "qt_to_ros":    "const QByteArray _b = QUuid::fromString(uuid).toRfc4122();\n"
                        "    std::copy(_b.begin(), _b.end(), ros_msg.uuid.begin());",
        "extra_inc":    "<QtCore/QUuid>",
        "qml_doc_type": "string",
    },
}


def build_single_field_info(package_name: str, message_spec) -> Dict[str, Any] | None:
    """For single-field messages, return type/conversion info for direct use in pub/sub.

    Returns None for empty messages and messages with 2+ fields.
    """
    msg_name = message_spec.structure.namespaced_type.name
    key = f"{package_name}/{msg_name}"
    if key in _SINGLE_FIELD_TYPE_OVERRIDES:
        return _SINGLE_FIELD_TYPE_OVERRIDES[key]

    members = message_spec.structure.members
    if len(members) != 1 or members[0].name == 'structure_needs_at_least_one_member':
        return None

    member = members[0]
    field_name = member.name
    field_type = member.type

    # Array/sequence fields need non-trivial conversions — keep the wrapper for those.
    if isinstance(field_type, (Array, BoundedSequence, UnboundedSequence)):
        return None

    resolved_type = field_type
    if isinstance(resolved_type, AbstractNestedType):
        resolved_type = resolved_type.value_type

    qt_type = msg_type_to_qt_full(field_type)

    if isinstance(resolved_type, AbstractWString):
        ros_to_qt = f'QString::fromStdWString(msg->{field_name})'
        qt_to_ros = f'ros_msg.{field_name} = {field_name}.toStdWString();'
        extra_inc = '<QtCore/QString>'
        const_ref = True
    elif isinstance(resolved_type, AbstractString):
        ros_to_qt = f'QString::fromStdString(msg->{field_name})'
        qt_to_ros = f'ros_msg.{field_name} = {field_name}.toStdString();'
        extra_inc = '<QtCore/QString>'
        const_ref = True
    elif isinstance(resolved_type, NamespacedType):
        nested_pkg = resolved_type.namespaces[0] if resolved_type.namespaces else package_name
        nested_ros = '::'.join(resolved_type.namespaces + [resolved_type.name])
        nested_qt  = get_qt_class_name_full(nested_pkg, resolved_type.name)
        ros_to_qt  = f'{nested_qt}(msg->{field_name})'
        qt_to_ros  = f'ros_msg.{field_name} = static_cast<{nested_ros}>({field_name});'
        extra_inc  = to_snake_case(resolved_type.name) + '.hpp'
        const_ref  = True
    else:
        ros_to_qt = f'msg->{field_name}'
        qt_to_ros = f'ros_msg.{field_name} = {field_name};'
        extra_inc = None
        const_ref = False

    _QT_TO_QML: Dict[str, str] = {'QString': 'string', 'QStringList': 'list<string>'}
    if isinstance(resolved_type, NamespacedType):
        nested_pkg = resolved_type.namespaces[0] if resolved_type.namespaces else package_name
        qml_doc_type = get_qml_value_type_name(nested_pkg, resolved_type.name)
    else:
        qml_doc_type = _QT_TO_QML.get(qt_type, qt_type)

    param_decl = f'const {qt_type}& {field_name}' if const_ref else f'{qt_type} {field_name}'

    return {
        'qt_type':      qt_type,
        'field_name':   field_name,
        'param_decl':   param_decl,
        'ros_to_qt':    ros_to_qt,
        'qt_to_ros':    qt_to_ros,
        'extra_inc':    extra_inc,
        'qml_doc_type': qml_doc_type,
    }


def build_field_props_for_pubsub(package_name: str, message_spec) -> List[Dict[str, Any]] | None:
    """Per-field Q_PROPERTY descriptors for multi-field pub/sub templates.

    Returns None for empty messages and single-field messages (those are handled by
    build_single_field_info or suppressed). For messages with two or more fields,
    returns one descriptor per field with keys:
      qt_type, field_name, prop_name, setter_name, signal_name,
      param_decl, const_ref, getter_expr, qml_doc_type.
    """
    members = message_spec.structure.members
    real_members = [m for m in members if m.name != 'structure_needs_at_least_one_member']
    if len(real_members) < 2:
        return None

    vt = build_value_type_descriptors(package_name, message_spec)
    real_infos = [fi for fi in vt['field_infos'] if not fi.get('is_computed')]

    result = []
    for fi in real_infos:
        prop_name = fi['qt_prop_name']
        setter_name = 'set' + prop_name[0].upper() + prop_name[1:]
        signal_name = prop_name + 'Changed'
        const_ref = (
            fi['is_nested'] or fi['is_string'] or fi['is_wstring'] or fi['is_sequence']
        )
        qt_type = fi['qt_type']
        param_decl = f'const {qt_type}& {prop_name}' if const_ref else f'{qt_type} {prop_name}'
        result.append({
            'qt_type':      qt_type,
            'field_name':   fi['name'],
            'prop_name':    prop_name,
            'setter_name':  setter_name,
            'signal_name':  signal_name,
            'param_decl':   param_decl,
            'const_ref':    const_ref,
            'getter_expr':  f'm_message.{prop_name}()',
            'qml_doc_type': fi['qml_doc_type'],
        })

    return result if result else None


def build_value_type_descriptors(package_name: str, message_spec) -> Dict[str, Any]:
    """
    Compute field descriptors and nested includes needed by the value type template.
    Mirrors the logic previously embedded directly in the template.
    """
    nested_includes: List[NestedInclude] = []
    field_infos: List[Dict[str, Any]] = []
    post_init_lines: List[str] = []

    def add_nested_include(type_obj):
        if not isinstance(type_obj, NamespacedType):
            return
        nested_pkg = type_obj.namespaces[0] if type_obj.namespaces else package_name
        nested_name = type_obj.name
        is_cross = nested_pkg != package_name
        entry = (nested_pkg, nested_name, is_cross)
        if entry not in nested_includes:
            nested_includes.append(entry)

    for member in message_spec.structure.members:
        info: Dict[str, Any] = {
            "field": member,
            "name": member.name,
            "qt_type": msg_type_to_qt_full(member.type),
            "qt_prop_name": snake_to_camel(member.name),
        }

        field_type = member.type
        resolved_type = field_type
        if isinstance(resolved_type, AbstractNestedType):
            resolved_type = resolved_type.value_type

        info["is_array"] = isinstance(field_type, Array)
        info["is_dynamic_sequence"] = isinstance(field_type, (BoundedSequence, UnboundedSequence))
        info["is_sequence"] = info["is_array"] or info["is_dynamic_sequence"]
        info["sequence_value_type"] = field_type.value_type if info["is_sequence"] else None
        info["sequence_inner_qt"] = (
            msg_type_to_qt(info["sequence_value_type"]) if info["is_sequence"] else None
        )
        info["sequence_inner_is_nested"] = (
            isinstance(info["sequence_value_type"], NamespacedType) if info["is_sequence"] else False
        )
        info["is_qbytearray"] = info["qt_type"] == "QByteArray"
        info["is_qstring_list"] = info["qt_type"] == "QStringList"
        info["sequence_inner_is_wstring"] = (
            isinstance(info["sequence_value_type"], AbstractWString) if info["is_sequence"] else False
        )
        info["sequence_inner_is_string"] = (
            isinstance(info["sequence_value_type"], AbstractString) if info["is_sequence"] else False
        )
        info["sequence_ros_value_type"] = (
            msg_type_to_cpp(info["sequence_value_type"]) if info["is_sequence"] else None
        )

        info["resolved_type"] = resolved_type
        info["is_nested"] = isinstance(resolved_type, NamespacedType)
        info["nested_ros_type"] = (
            "::".join(resolved_type.namespaces + [resolved_type.name]) if info["is_nested"] else None
        )
        info["is_wstring"] = isinstance(resolved_type, AbstractWString)
        info["is_string"] = isinstance(resolved_type, AbstractString)

        if info["is_nested"]:
            add_nested_include(resolved_type)
        if info["sequence_inner_is_nested"]:
            add_nested_include(info["sequence_value_type"])

        if info["is_qstring_list"]:
            if info["sequence_inner_is_wstring"]:
                qt_conv = "QString::fromStdWString(value)"
                ros_conv = "value.toStdWString()"
            else:
                qt_conv = "QString::fromStdString(value)"
                ros_conv = "value.toStdString()"
            info["string_to_qt"] = qt_conv
            info["string_to_ros"] = ros_conv
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            post_init_lines.append(f"            m_{member.name}.append({qt_conv});")
            post_init_lines.append("        }")
        elif info["is_sequence"] and (info["sequence_inner_is_string"] or info["sequence_inner_is_wstring"]):
            if info["sequence_inner_is_wstring"]:
                qt_conv = "QString::fromStdWString(value)"
                ros_conv = "value.toStdWString()"
            else:
                qt_conv = "QString::fromStdString(value)"
                ros_conv = "value.toStdString()"
            info["string_to_qt"] = qt_conv
            info["string_to_ros"] = ros_conv
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            post_init_lines.append(f"            m_{member.name}.append({qt_conv});")
            post_init_lines.append("        }")

        if info["sequence_inner_is_nested"]:
            post_init_lines.append(
                f"        m_{member.name}.reserve(static_cast<int>(ros.{member.name}.size()));"
            )
            post_init_lines.append(f"        for (const auto& value : ros.{member.name}) {{")
            post_init_lines.append(f"            m_{member.name}.append({info['sequence_inner_qt']}(value));")
            post_init_lines.append("        }")

        # QML-friendly type name used in \qmlproperty docs so qdoc can auto-link.
        _QT_TO_QML: Dict[str, str] = {"QString": "string", "QStringList": "list<string>"}
        if info["is_sequence"]:
            if info["is_qbytearray"]:
                info["qml_doc_type"] = "ArrayBuffer"
            elif info["is_qstring_list"] or info["sequence_inner_is_string"] or info["sequence_inner_is_wstring"]:
                info["qml_doc_type"] = "list<string>"
            elif info["sequence_inner_is_nested"]:
                inner = info["sequence_value_type"]
                pkg = inner.namespaces[0] if inner.namespaces else package_name
                info["qml_doc_type"] = f"list<{get_qml_value_type_name(pkg, inner.name)}>"
            else:
                inner_qt = info["sequence_inner_qt"] or ""
                info["qml_doc_type"] = f"list<{inner_qt}>"
        elif info["is_nested"]:
            t = resolved_type
            pkg = t.namespaces[0] if t.namespaces else package_name
            info["qml_doc_type"] = get_qml_value_type_name(pkg, t.name)
        else:
            info["qml_doc_type"] = _QT_TO_QML.get(info["qt_type"], info["qt_type"])

        field_infos.append(info)

    msg_name = message_spec.structure.namespaced_type.name
    pkg_msg_key = f"{package_name}/{msg_name}"
    qt_ns = get_qt_namespace(package_name)
    qt_cls = get_qt_class_name(package_name, msg_name)
    for tmpl in _COMPUTED_PROPERTIES.get(pkg_msg_key, []):
        entry: Dict[str, Any] = dict(tmpl)
        if "cpp_impl_tmpl" in entry:
            entry["cpp_impl"] = entry.pop("cpp_impl_tmpl").format(ns=qt_ns, cls=qt_cls)
        field_infos.append(entry)

    return {
        "nested_includes": nested_includes,
        "field_infos": field_infos,
        "post_init_lines": post_init_lines,
    }


def _strip_blank_edges(lines: List[str]) -> List[str]:
    out = list(lines)
    while out and not out[0].strip():
        out.pop(0)
    while out and not out[-1].strip():
        out.pop()
    return out


def _sanitize_doc_line(line: str) -> str:
    """Defensively neutralize sequences that would break a qdoc /*! ... */ block."""
    return line.replace("*/", "* /")


def _format_list_items(lines: List[str]) -> List[str]:
    """Convert runs of indented lines in ROS comment text to qdoc \\list / \\li markup.

    ROS .msg comments frequently use leading-whitespace indentation for lists of
    named items (e.g. the image topic list in sensor_msgs/CameraInfo). qdoc
    ignores extra whitespace, so without this conversion the items render as
    undifferentiated paragraph text.  Any contiguous block of lines that start
    with at least one space is wrapped in \\list ... \\endlist, with each line
    emitted as a \\li item (with the leading whitespace stripped).
    """
    result: List[str] = []
    in_list = False
    for line in lines:
        stripped = line.lstrip()
        is_indented = len(line) > len(stripped) and bool(stripped)
        if is_indented and not in_list:
            result.append(r'\list')
            in_list = True
        elif not is_indented and in_list:
            result.append(r'\endlist')
            in_list = False
        result.append((r'\li ' + stripped) if is_indented else line)
    if in_list:
        result.append(r'\endlist')
    return result


_DEPRECATED_RE = re.compile(r'\bdeprecated\b', re.IGNORECASE)
_DEPRECATED_VERSION_RE = re.compile(r'\b(?:as\s+of|since)\s+([\w]+)', re.IGNORECASE)
_DEPRECATED_FAVOUR_RE = re.compile(r'\bin\s+favou?r\s+of\s+(.+?)\.?\s*$', re.IGNORECASE)


def extract_doc_info(message_spec) -> Dict[str, Any]:
    """
    Pull human-authored documentation out of a parsed ROS interface.

    The ROS .msg comments are preserved by rosidl_adapter as
    @verbatim(language="comment", ...) annotations on the struct and on
    each member. rosidl_parser exposes them via Annotatable.get_comment_lines().
    Both struct-level and per-member text flow through here so the qdoc
    templates can emit a meaningful \\brief and per-property documentation.

    Deprecation notices (lines containing the word "deprecated") are stripped
    from the main text and returned separately as ``deprecated`` /
    ``deprecated_since`` so templates can emit a qdoc \\deprecated tag.
    """
    msg_lines: List[str] = []
    try:
        msg_lines = list(message_spec.structure.get_comment_lines() or [])
    except (AttributeError, ValueError):
        msg_lines = []
    msg_lines = [_sanitize_doc_line(ln) for ln in _strip_blank_edges(msg_lines)]

    # Detect and strip deprecation lines before building brief/details
    deprecated = False
    deprecated_since = ''
    clean_lines: List[str] = []
    for line in msg_lines:
        if _DEPRECATED_RE.search(line):
            deprecated = True
            if not deprecated_since:
                m = _DEPRECATED_VERSION_RE.search(line)
                if m:
                    deprecated_since = m.group(1)
            # "deprecated in favour of X" → capture as version-less detail
            # (kept in clean_lines so it becomes part of brief/details)
            if _DEPRECATED_FAVOUR_RE.search(line):
                clean_lines.append(line)
        else:
            clean_lines.append(line)
    if deprecated:
        msg_lines = list(_strip_blank_edges(clean_lines))

    # Split at the first blank line: everything before is the brief paragraph,
    # everything after is the detailed description. This preserves multi-line
    # first paragraphs so \brief doesn't end mid-sentence.
    first_blank = next((i for i, l in enumerate(msg_lines) if not l.strip()), len(msg_lines))
    brief_lines = msg_lines[:first_blank]
    details = _format_list_items(list(_strip_blank_edges(msg_lines[first_blank + 1:] if first_blank < len(msg_lines) else [])))

    brief = brief_lines[0].strip() if brief_lines else ""
    brief_continuation = brief_lines[1:] if len(brief_lines) > 1 else []

    field_docs: Dict[str, List[str]] = {}
    members = []
    if hasattr(message_spec, "structure") and hasattr(message_spec.structure, "members"):
        members = message_spec.structure.members
    for member in members:
        try:
            lines = list(member.get_comment_lines() or [])
        except (AttributeError, ValueError):
            lines = []
        lines = _format_list_items([_sanitize_doc_line(ln) for ln in _strip_blank_edges(lines)])
        field_docs[member.name] = lines

    return {
        "brief": brief,
        "brief_continuation": brief_continuation,
        "details": details,
        "field_docs": field_docs,
        "deprecated": deprecated,
        "deprecated_since": deprecated_since,
    }


def build_include_guard(*parts: str, suffix: str = "HPP") -> str:
    """
    Create a deterministic include guard identifier based on the provided parts.
    """
    tokens: List[str] = ["QTROS2"]
    for part in parts:
        normalized = re.sub(r"[^0-9A-Za-z]+", "_", part).strip("_")
        if normalized:
            tokens.append(normalized.upper())
    if suffix:
        tokens.append(suffix.upper())
    return "_".join(tokens)
