# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0

# Copyright 2024 QtROS2 Developers
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

import re
import json
import em
from typing import List
from pathlib import Path

from rosidl_parser.definition import AbstractGenericString
from rosidl_parser.definition import AbstractNestedType
from rosidl_parser.definition import AbstractSequence
from rosidl_parser.definition import AbstractString
from rosidl_parser.definition import AbstractWString
from rosidl_parser.definition import Array
from rosidl_parser.definition import BasicType
from rosidl_parser.definition import BoundedSequence
from rosidl_parser.definition import NamespacedType
from rosidl_parser.definition import UnboundedSequence
from rosidl_parser.parser import parse_idl_file
from rosidl_parser.definition import Message, Service, Action, IdlLocator

# Import dependency analyzer
from .dependency_analyzer import analyze_package_dependencies


def generate_qtros2(generator_arguments_file, qt_package_mapping=None, source_package=None) -> List[str]:
    """
    Generate Qt/QML C++ wrapper code from ROS 2 IDL definitions.

    This is called by the rosidl infrastructure with a JSON arguments file.
    """
    if qt_package_mapping is None:
        qt_package_mapping = {}

    # Load generator arguments
    with open(generator_arguments_file, 'r') as f:
        args = json.load(f)

    package_name = args['package_name']
    # namespace_package: ROS2 source package name for namespace/type generation.
    # package_name (Qt module name) is used for output directory structure only.
    namespace_package = source_package if source_package else package_name
    output_dir = Path(args['output_dir'])
    template_dir = Path(args['template_dir'])
    idl_tuples = args.get('idl_tuples', [])

    # Analyze interface package dependencies from IDL files
    dep_analysis = analyze_package_dependencies(idl_tuples, package_name)
    interface_package_deps = dep_analysis['interface_packages']

    # Write dependency information to a file for debugging and potential CMake use
    deps_file = output_dir / 'interface_dependencies.json'
    deps_file.parent.mkdir(parents=True, exist_ok=True)
    with deps_file.open('w') as f:
        json.dump(dep_analysis, f, indent=2)

    print(f"QtROS2 Generator: Package {package_name}")
    print(f"  Interface package dependencies: {interface_package_deps}")
    if dep_analysis['per_file_deps']:
        print(f"  Per-file dependencies:")
        for file_path, deps in dep_analysis['per_file_deps'].items():
            if deps:
                print(f"    {file_path}: {deps}")

    # Create output directories
    (output_dir / 'include' / package_name).mkdir(parents=True, exist_ok=True)
    (output_dir / 'src').mkdir(parents=True, exist_ok=True)

    generated_files = []
    generated_headers: List[str] = []
    generated_sources: List[str] = []
    generated_parent_folders = set()

    def record_generated_file(path: Path):
        generated_files.append(str(path))
        try:
            rel = path.relative_to(output_dir)
        except ValueError:
            rel = path
        rel_parts = rel.parts
        rel_posix = rel.as_posix()
        if rel.suffix == '.hpp':
            generated_headers.append(rel_posix)
        elif rel.suffix == '.cpp':
            generated_sources.append(rel_posix)

        if len(rel_parts) >= 3 and rel_parts[0] == 'include':
            folder = rel_parts[2]
            generated_parent_folders.add(folder)
        elif len(rel_parts) >= 2 and rel_parts[0] == 'src':
            folder = rel_parts[1]
            generated_parent_folders.add(folder)

    def _generate_message_artifacts(
        message_spec,
        interface_type,
        interface_path,
        emit_pub_sub,
        ros_include_override=None,
    ):
        if not message_spec:
            return

        msg_name = message_spec.structure.namespaced_type.name
        # Skip wrapper/publisher/subscriber generation for messages that map
        # to a Qt-native type — nothing references them after substitution.
        if f"{namespace_package}/{msg_name}" in NAMESPACED_TYPE_MAPPING:
            return
        base_name = to_snake_case(msg_name)
        out_subdir = output_dir / 'include' / package_name / interface_type
        out_src_subdir = output_dir / 'src' / interface_type
        out_subdir.mkdir(parents=True, exist_ok=True)
        out_src_subdir.mkdir(parents=True, exist_ok=True)

        needs_wrap = needs_wrapper_type(message_spec)
        # Always generate the wrapper for msg types: single-field messages may be used
        # as nested field types in other messages and must have a header to include.
        # For srv/action, only generate wrapper when the message has 2+ fields.
        emit_wrapper = True
        if interface_type in ('srv', 'action'):
            emit_wrapper = needs_wrap

        context = {
            'package_name': namespace_package,
            'qt_module_name': package_name,
            'message': message_spec,
            'spec': message_spec,
            'interface_path': interface_path,
            'interface_type': interface_type,
            'get_qt_class_name': get_qt_class_name,
            'get_qt_namespace': get_qt_namespace,
            'msg_type_to_qt_full': msg_type_to_qt_full,
            'snake_to_camel': snake_to_camel,
            'ros_type_to_cpp': ros_type_to_cpp,
            'needs_wrapper_type': needs_wrapper_type,
            'get_single_field_type': get_single_field_type,
            'get_single_field_include': get_single_field_include,
            'qtros2_interface_subdir': interface_type,
            'ros_include_override': ros_include_override,
            'emit_wrapper': emit_wrapper,
            'qt_package_mapping': qt_package_mapping,
        }

        templates = []
        if emit_wrapper:
            templates.extend([
                ('msg__value_type.hpp.em', out_subdir / f"{base_name}.hpp"),
                ('msg__value_type.cpp.em', out_src_subdir / f"{base_name}.cpp"),
            ])
            # Value types with Q_INVOKABLE static factory methods (e.g.
            # Quaternion::fromEulerAngles) also get a QML singleton helper, since
            # static methods are not callable on a QML value type directly.
            from .template_helpers import value_type_has_static_factories
            if value_type_has_static_factories(namespace_package, message_spec):
                templates.extend([
                    ('msg__factory_singleton.hpp.em', out_subdir / f"{base_name}_utils.hpp"),
                    # The singleton's \qmltype/\qmlmethod docs go in a .cpp (a qdoc
                    # sourcedir) so its QML type page is generated; qdoc does not emit
                    # a page for a \qmltype documented only in a header.
                    ('msg__factory_singleton.cpp.em', out_src_subdir / f"{base_name}_utils.cpp"),
                ])

        if emit_pub_sub:
            templates.extend([
                ('msg__publisher.hpp.em', out_subdir / f"{base_name}_publisher.hpp"),
                ('msg__publisher.cpp.em', out_src_subdir / f"{base_name}_publisher.cpp"),
                ('msg__subscriber.hpp.em', out_subdir / f"{base_name}_subscriber.hpp"),
                ('msg__subscriber.cpp.em', out_src_subdir / f"{base_name}_subscriber.cpp"),
            ])

        for template_file, output_file in templates:
            template_path = template_dir / template_file
            if not template_path.exists():
                continue

            try:
                with open(template_path, 'r') as tf:
                    template_content = tf.read()

                with open(output_file, 'w') as of:
                    interpreter = em.Interpreter(output=of, globals=dict(context))
                    interpreter.string(template_content)
                    interpreter.shutdown()

                    record_generated_file(output_file)
            except Exception as e:
                print(f"ERROR generating {output_file}: {e}")
                import traceback
                traceback.print_exc()

    # Process each IDL file
    for idl_tuple in args.get('idl_tuples', []):
        # idl_tuple format: "base_path:relative_path"
        parts = idl_tuple.split(':', 1)
        if len(parts) != 2:
            continue

        base_path, relative_path = parts
        # Construct full IDL file path
        idl_file = Path(base_path) / relative_path

        if not idl_file.exists():
            continue

        # Parse IDL file
        try:
            basepath = idl_file.parent
            locator = IdlLocator(basepath, Path(idl_file.name))
            idl_file_obj = parse_idl_file(locator)
            content = idl_file_obj.content

            messages = content.get_elements_of_type(Message)
            services = content.get_elements_of_type(Service)
            actions = content.get_elements_of_type(Action)

        except Exception as e:
            print(f"ERROR parsing {idl_file}: {e}")
            continue

        # Determine interface type from path
        interface_type = None
        if '/msg/' in str(idl_file):
            interface_type = 'msg'
        elif '/srv/' in str(idl_file):
            interface_type = 'srv'
        elif '/action/' in str(idl_file):
            interface_type = 'action'

        # Generate code for each message
        for message_spec in messages:
            emit_pub_sub = interface_type == 'msg'
            _generate_message_artifacts(message_spec, interface_type, idl_file, emit_pub_sub)

        # Generate code for each service (Qt service clients)
        services = content.get_elements_of_type(Service)
        for service_spec in services:
            service_name = service_spec.namespaced_type.name
            base_name = to_snake_case(service_name)
            out_srv_dir = output_dir / 'include' / package_name / 'srv'
            out_srv_src_dir = output_dir / 'src' / 'srv'
            out_srv_dir.mkdir(parents=True, exist_ok=True)
            out_srv_src_dir.mkdir(parents=True, exist_ok=True)

            context = {
                'package_name': namespace_package,
                'qt_module_name': package_name,
                'service': service_spec,
                'spec': service_spec,
                'interface_path': idl_file,
                'get_qt_class_name': get_qt_class_name,
                'get_qt_class_name_full': get_qt_class_name_full,
                'get_qt_namespace': get_qt_namespace,
                'needs_wrapper_type': needs_wrapper_type,
                'get_single_field_type': get_single_field_type,
                'get_single_field_include': get_single_field_include,
                'msg_type_to_qt': msg_type_to_qt,
                'msg_type_to_cpp': msg_type_to_cpp,
                'qt_package_mapping': qt_package_mapping,
            }

            service_templates = [
                ('srv__client.hpp.em', out_srv_dir / f"{base_name}_service_client.hpp"),
                ('srv__client.cpp.em', out_srv_src_dir / f"{base_name}_service_client.cpp"),
                ('srv__server.hpp.em', out_srv_dir / f"{base_name}_service_server.hpp"),
                ('srv__server.cpp.em', out_srv_src_dir / f"{base_name}_service_server.cpp"),
            ]

            for template_file, output_file in service_templates:
                template_path = template_dir / template_file
                if not template_path.exists():
                    continue

                try:
                    with open(template_path, 'r') as tf:
                        template_content = tf.read()

                    with open(output_file, 'w') as of:
                        interpreter = em.Interpreter(output=of, globals=dict(context))
                        interpreter.string(template_content)
                        interpreter.shutdown()

                    record_generated_file(output_file)
                except Exception as e:
                    print(f"ERROR generating {output_file}: {e}")
                    import traceback
                    traceback.print_exc()

            # Generate wrappers for request / response so QML can construct payloads
            ros_pkg = service_spec.namespaced_type.namespaces[0] \
                if service_spec.namespaced_type.namespaces else package_name
            ros_service_include = f"{ros_pkg}/srv/{to_snake_case(service_name)}.hpp"

            _generate_message_artifacts(
                service_spec.request_message,
                'srv',
                idl_file,
                emit_pub_sub=False,
                ros_include_override=ros_service_include,
            )
            _generate_message_artifacts(
                service_spec.response_message,
                'srv',
                idl_file,
                emit_pub_sub=False,
                ros_include_override=ros_service_include,
            )

        for action_spec in actions:
            action_name = action_spec.namespaced_type.name
            base_name = to_snake_case(action_name)
            out_action_dir = output_dir / 'include' / package_name / 'action'
            out_action_src_dir = output_dir / 'src' / 'action'
            out_action_dir.mkdir(parents=True, exist_ok=True)
            out_action_src_dir.mkdir(parents=True, exist_ok=True)

            ros_pkg = action_spec.namespaced_type.namespaces[0] \
                if action_spec.namespaced_type.namespaces else package_name
            ros_action_include = f"{ros_pkg}/action/{to_snake_case(action_name)}.hpp"

            for action_message in (
                action_spec.goal,
                action_spec.result,
                action_spec.feedback,
            ):
                _generate_message_artifacts(
                    action_message,
                    'action',
                    idl_file,
                    emit_pub_sub=False,
                    ros_include_override=ros_action_include,
                )

            action_context = {
                'package_name': namespace_package,
                'qt_module_name': package_name,
                'action': action_spec,
                'spec': action_spec,
                'interface_path': idl_file,
                'get_qt_class_name': get_qt_class_name,
                'get_qt_class_name_full': get_qt_class_name_full,
                'get_qt_namespace': get_qt_namespace,
                'needs_wrapper_type': needs_wrapper_type,
                'get_single_field_type': get_single_field_type,
                'get_single_field_include': get_single_field_include,
                'msg_type_to_qt': msg_type_to_qt,
                'msg_type_to_cpp': msg_type_to_cpp,
                'to_snake_case': to_snake_case,
                'ros_action_include': ros_action_include,
                'qt_package_mapping': qt_package_mapping,
            }

            action_templates = [
                ('action__client.hpp.em', out_action_dir / f"{base_name}_action_client.hpp"),
                ('action__client.cpp.em', out_action_src_dir / f"{base_name}_action_client.cpp"),
                ('action__server.hpp.em', out_action_dir / f"{base_name}_action_server.hpp"),
                ('action__server.cpp.em', out_action_src_dir / f"{base_name}_action_server.cpp"),
            ]

            for template_file, output_file in action_templates:
                template_path = template_dir / template_file
                if not template_path.exists():
                    continue

                try:
                    with open(template_path, 'r') as tf:
                        template_content = tf.read()

                    with open(output_file, 'w') as of:
                        interpreter = em.Interpreter(output=of, globals=dict(action_context))
                        interpreter.string(template_content)
                        interpreter.shutdown()

                    record_generated_file(output_file)
                except Exception as e:
                    print(f"ERROR generating {output_file}: {e}")
                    import traceback
                    traceback.print_exc()

    generated_headers = sorted(dict.fromkeys(generated_headers))
    generated_sources = sorted(dict.fromkeys(generated_sources))
    generated_parent_folders_list = sorted(generated_parent_folders)

    manifest_path = output_dir / "qtros2_generated_files.cmake"
    manifest_lines = [
        "# Autogenerated by rosidl_generator_qtros2. DO NOT EDIT.",
        "",
    ]

    def _emit_list(name: str, values: List[str]):
        manifest_lines.append(f"set({name}")
        for value in values:
            manifest_lines.append(f"    {value}")
        manifest_lines.append(")")
        manifest_lines.append("")

    _emit_list("_qtros2_generated_headers", generated_headers)
    _emit_list("_qtros2_generated_sources", generated_sources)
    _emit_list("_qtros2_generated_parent_folders", generated_parent_folders_list)

    manifest_path.write_text("\n".join(manifest_lines))

    return generated_files


def generate_cmake_vars(
    output_path: str,
    target_name: str,
    qml_uri: str,
    qml_imports: List[str],
    generated_headers: List[str],
    generated_sources: List[str],
    dependency_packages: List[str],
    dependency_qt_targets: dict,
    generated_parent_folders: List[str],
):
    """
    Generate qtros2_module_vars.cmake — cmake variable assignments consumed by
    rosidl_generator_qtros2_generate_interfaces.cmake via include().

    See also: qtros2_generated_files.cmake
    """
    from pathlib import Path as _Path

    out = _Path(output_path) / "qtros2_module_vars.cmake"
    out.parent.mkdir(parents=True, exist_ok=True)

    # Derive module name from the last component of the target (CamelCase)
    module_name = target_name

    # Build import list (URIs as passed in, format: "Module.URI/version")
    imports_lines = "\n".join(f'    "{imp}"' for imp in qml_imports)

    # Source file lists (relative paths)
    headers_lines = "\n".join(f'    "{h}"' for h in generated_headers)
    sources_lines = "\n".join(f'    "{s}"' for s in generated_sources)

    # Public include dirs use CMAKE_CURRENT_LIST_DIR because the vars file is include()d
    include_dirs = [
        '"$<BUILD_INTERFACE:${CMAKE_CURRENT_LIST_DIR}/include>"',
    ]
    for folder in sorted(set(generated_parent_folders)):
        include_dirs.append(
            f'"$<BUILD_INTERFACE:${{CMAKE_CURRENT_LIST_DIR}}/include/{module_name}/{folder}>"'
        )
    include_dirs.append('"$<INSTALL_INTERFACE:include>"')
    include_dirs_lines = "\n".join(f"    {d}" for d in include_dirs)

    # Public libraries: Qt6::Ros2Core + Qt6::Gui (generated headers reference
    # QVector3D / QQuaternion / QImage) + Qt targets for each dependency
    public_libs = ["Qt6::Ros2Core", "Qt6::Gui"]
    private_libs = ["Qt6::Ros2CorePrivate"]
    no_qt_fallbacks = []
    for dep in dependency_packages:
        qt_target = dependency_qt_targets.get(dep, "")
        if qt_target:
            public_libs.append(f'"{qt_target}"')
        else:
            no_qt_fallbacks.append(dep)
    public_libs_lines = "\n".join(f'    {lib}' for lib in public_libs)
    private_libs_lines = "\n".join(f'    {lib}' for lib in private_libs)

    lines = [
        f"# Generated cmake variables for {module_name}",
        "# DO NOT EDIT - Regenerated from IDL files",
        "",
        f'set(_qtros2_module_name "{module_name}")',
        f'set(_qtros2_module_uri "{qml_uri}")',
        "",
        "set(_qtros2_module_imports",
        imports_lines,
        ")",
        "",
        "set(_qtros2_module_sources",
        headers_lines,
        sources_lines,
        ")",
        "",
        "set(_qtros2_module_public_include_dirs",
        include_dirs_lines,
        ")",
        "",
        "set(_qtros2_module_public_libs",
        public_libs_lines,
        ")",
        "",
    ]

    if no_qt_fallbacks:
        lines += [
            "# Non-Qt dependency fallbacks (packages without a known Qt target at generation time)",
        ]
    lines += [
        "set(_qtros2_module_private_libs",
        private_libs_lines,
        ")",
    ]

    out.write_text("\n".join(lines) + "\n")
    return str(out)


# ROS messages that should map directly to a Qt-native type instead of
# getting a generated Q_GADGET wrapper. Used for messages whose precision
# matches a Qt type exactly (e.g. Point32's float32 fields match QVector3D).
# Keys are "package/MessageName". Each entry provides:
#   - qt_type:        Qt-native C++ type substituted everywhere the message appears
#   - include:        header to add wherever the type would have been included
#   - qml_doc_type:   QML type name for \qmlproperty docs
#   - from_ros:       lambda(expr) -> C++ expression building the Qt value from a ROS value
#   - to_ros:         lambda(ros_type, qt_expr) -> C++ expression building the ROS value
#
# When a message is mapped, its wrapper / publisher / subscriber are NOT
# generated; nothing references them after substitution.
NAMESPACED_TYPE_MAPPING = {
    "geometry_msgs/Point32": {
        "qt_type": "QVector3D",
        "include": "<QVector3D>",
        "qml_doc_type": "vector3d",
        "from_ros": lambda e: f"QVector3D({e}.x, {e}.y, {e}.z)",
        "to_ros": lambda r, e: (
            f"[&]{{ {r} _v; _v.x = {e}.x(); _v.y = {e}.y(); _v.z = {e}.z(); return _v; }}()"
        ),
    },
}


def get_namespaced_type_mapping(type_):
    """If the given NamespacedType is in NAMESPACED_TYPE_MAPPING, return its
    mapping dict; else None."""
    if not isinstance(type_, NamespacedType):
        return None
    parts = type_.namespaced_name()
    if len(parts) >= 3 and parts[-2] == 'msg':
        return NAMESPACED_TYPE_MAPPING.get(f"{parts[0]}/{parts[-1]}")
    return None


# Type mapping from ROS IDL types to Qt types
MSG_TYPE_TO_QT = {
    'boolean': 'bool',
    'octet': 'uint8_t',
    'char': 'uint8_t',
    'wchar': 'char16_t',
    'float': 'float',
    'double': 'double',
    'long double': 'long double',
    'uint8': 'uint8_t',
    'int8': 'int8_t',
    'uint16': 'uint16_t',
    'int16': 'int16_t',
    'uint32': 'uint32_t',
    'int32': 'int32_t',
    'uint64': 'uint64_t',
    'int64': 'int64_t',
    'string': 'QString',
    'wstring': 'QString',
}

# Type mapping from ROS IDL types to ROS C++ types
MSG_TYPE_TO_CPP = {
    'boolean': 'bool',
    'octet': 'uint8_t',
    'char': 'uint8_t',
    'wchar': 'char16_t',
    'float': 'float',
    'double': 'double',
    'long double': 'long double',
    'uint8': 'uint8_t',
    'int8': 'int8_t',
    'uint16': 'uint16_t',
    'int16': 'int16_t',
    'uint32': 'uint32_t',
    'int32': 'int32_t',
    'uint64': 'uint64_t',
    'int64': 'int64_t',
    'string': 'std::string',
    'wstring': 'std::wstring',
}


def is_empty_message(message):
    """Check if a message is effectively empty."""
    if not hasattr(message, 'structure') or not hasattr(message.structure, 'members'):
        return True

    members = message.structure.members
    if len(members) == 0:
        return True

    # Check for dummy field added by ROS 2
    if len(members) == 1 and members[0].name == 'structure_needs_at_least_one_member':
        return True

    return False


def needs_wrapper_type(message):
    """Check if a message needs a wrapper Q_GADGET type."""
    if is_empty_message(message):
        return False

    if not hasattr(message, 'structure') or not hasattr(message.structure, 'members'):
        return False

    field_count = len(message.structure.members)
    return field_count >= 2


def get_single_field_type(message, package_name):
    """Get the Qt type for a simple message (0 or 1 field)."""
    if is_empty_message(message):
        return 'void'

    if not hasattr(message, 'structure') or not hasattr(message.structure, 'members'):
        return 'void'

    members = message.structure.members

    if len(members) == 0:
        return 'void'

    if len(members) == 1:
        field = members[0]
        return msg_type_to_qt_full(field.type)

    return 'void'


def msg_type_to_qt(type_):
    """Convert a ROS message type to Qt C++ type with proper namespace."""
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type

    if isinstance(type_, BasicType):
        return MSG_TYPE_TO_QT.get(type_.typename, type_.typename)
    elif isinstance(type_, (AbstractString, AbstractWString)):
        return 'QString'
    elif isinstance(type_, NamespacedType):
        parts = type_.namespaced_name()
        if len(parts) >= 3 and parts[-2] == 'msg':
            mapping = NAMESPACED_TYPE_MAPPING.get(f"{parts[0]}/{parts[-1]}")
            if mapping:
                return mapping["qt_type"]
            package = parts[0]
            msg_name = parts[-1]
            namespace = get_qt_namespace(package)
            return f"{namespace}::{msg_name}"
        else:
            return ''.join(p.title() for p in parts)
    else:
        raise ValueError(f'Unknown type: {type_}')


def msg_type_to_qt_full(type_):
    """Convert a ROS message type (including arrays) to full Qt C++ type."""
    if isinstance(type_, Array):
        inner_type = msg_type_to_qt(type_.value_type)
        return f"QList<{inner_type}>"
    elif isinstance(type_, UnboundedSequence):
        inner_type = msg_type_to_qt(type_.value_type)
        if inner_type in ['uint8_t', 'int8_t']:
            return 'QByteArray'
        elif inner_type == 'QString':
            return 'QStringList'
        else:
            return f"QList<{inner_type}>"
    elif isinstance(type_, BoundedSequence):
        inner_type = msg_type_to_qt(type_.value_type)
        if inner_type in ['uint8_t', 'int8_t']:
            return 'QByteArray'
        elif inner_type == 'QString':
            return 'QStringList'
        else:
            return f"QList<{inner_type}>"
    else:
        return msg_type_to_qt(type_)


def msg_type_to_cpp(type_):
    """Convert a message field type to the ROS C++ type."""
    if isinstance(type_, AbstractNestedType):
        type_ = type_.value_type

    if isinstance(type_, BasicType):
        return MSG_TYPE_TO_CPP.get(type_.typename, type_.typename)
    elif isinstance(type_, (AbstractString, AbstractWString)):
        return 'std::string'
    elif isinstance(type_, NamespacedType):
        return '::'.join(type_.namespaced_name())
    else:
        return str(type_)


def ros_type_to_cpp(type_):
    """Convert a ROS type to the full ROS C++ type."""
    if isinstance(type_, NamespacedType):
        return '::'.join(type_.namespaced_name())
    else:
        return str(type_)


def snake_to_camel(snake_str: str) -> str:
    """Convert snake_case to camelCase."""
    components = snake_str.split('_')
    return components[0] + ''.join(x.title() for x in components[1:])


def to_snake_case(name: str) -> str:
    """Convert CamelCase or mixed case ROS identifiers to snake_case."""
    if not name:
        return ''

    if '_' in name and name.lower() == name:
        return name

    s1 = re.sub('(.)([A-Z][a-z]+[a-z0-9]*)', r'\1_\2', name)
    s2 = re.sub('([a-z0-9])([A-Z])', r'\1_\2', s1)
    return s2.replace('__', '_').lower()


# Override QML type names that would conflict with built-in QML value types.
# Keys are "package/MessageName"; values are the QML type name to use instead.
_QML_NAME_OVERRIDES: dict = {
    # 'string' is a built-in QML value type; using it would prevent qdoc from
    # linking plain 'string' properties to the built-in type.
    "std_msgs/String": "rosString",
}


def get_qml_value_type_name(package: str, message_name: str) -> str:
    """QML value type name for a ROS message, in lowercase camelCase.

    Qt's QML value-type convention uses a lowercase initial letter
    (e.g. ``point``, ``rect``, ``color``). The QML module URI provides
    package scoping; users alias with ``import ... as`` on the rare
    collision (e.g. ``keyValue`` exists in both diagnostic_msgs and
    type_description_interfaces).

    Examples::

        Duration            -> duration
        TwistWithCovariance -> twistWithCovariance
        NavSatFix           -> navSatFix
    """
    key = f"{package}/{message_name}"
    if key in _QML_NAME_OVERRIDES:
        return _QML_NAME_OVERRIDES[key]
    name = get_qt_class_name(package, message_name)
    return name[:1].lower() + name[1:] if name else name


def get_qt_namespace(package: str) -> str:
    """Generate Qt namespace from package name with QtROS2 prefix."""
    normalized = package
    if normalized.startswith('qtros2_'):
        normalized = normalized[len('qtros2_'):]
    normalized = normalized.replace('_msgs', '')
    parts = [part for part in normalized.replace('-', '_').split('_') if part]
    core = ''.join(part.capitalize() for part in parts) or normalized.title()
    return f"Qtros2{core}Msgs"


def get_qt_class_name(package: str, message_name: str) -> str:
    """Generate Qt class name from package and message name (without namespace)."""
    return message_name.replace('_', '')


def get_qt_class_name_full(package: str, message_name: str) -> str:
    """Generate fully qualified Qt class name with namespace."""
    namespace = get_qt_namespace(package)
    class_name = get_qt_class_name(package, message_name)
    return f"{namespace}::{class_name}"


def get_include_guard(filename: str) -> str:
    """Generate include guard from filename."""
    return filename.upper().replace('.', '_').replace('/', '_')


def get_single_field_include(message, current_package):
    """Get the include directive needed for a single-field message type."""
    if is_empty_message(message):
        return None

    if not hasattr(message, 'structure') or not hasattr(message.structure, 'members'):
        return None

    members = message.structure.members

    if len(members) != 1:
        return None

    field = members[0]
    field_type = field.type

    # Unwrap nested types (arrays, sequences)
    if isinstance(field_type, AbstractNestedType):
        field_type = field_type.value_type

    # Check if it's a complex type that needs an include
    if isinstance(field_type, NamespacedType):
        parts = field_type.namespaced_name()
        if len(parts) >= 3 and parts[-2] == 'msg':
            package = parts[0]
            msg_name = parts[-1]
            is_cross_package = (package != current_package)
            return (package, msg_name, is_cross_package)

    return None
