# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0

#!/usr/bin/env python3
"""
Dependency analyzer for rosidl interface files.

Extracts actual message/service/action package dependencies from IDL files,
without relying on CMake package dependency lists.
"""

from pathlib import Path
from typing import Set, Dict, List
import json

from rosidl_parser.definition import (
    Message, Service, Action, IdlLocator,
    NamespacedType, AbstractNestedType
)
from rosidl_parser.parser import parse_idl_file


def extract_package_dependencies_from_type(type_obj, current_package: str) -> Set[str]:
    """
    Extract package dependencies from a type object.

    Returns a set of package names that this type depends on (excluding current_package).
    """
    dependencies = set()

    # Unwrap nested types (arrays, sequences)
    if isinstance(type_obj, AbstractNestedType):
        type_obj = type_obj.value_type

    # Check if it's a namespaced type (complex message type)
    if isinstance(type_obj, NamespacedType):
        parts = type_obj.namespaced_name()
        if len(parts) >= 1:
            package = parts[0]
            # Convert Token to string if necessary
            if hasattr(package, 'value'):
                package = package.value
            else:
                package = str(package)
            # Only add if it's from a different package
            if package != current_package:
                dependencies.add(package)

    return dependencies


def extract_package_dependencies_from_message(message_spec, current_package: str) -> Set[str]:
    """Extract package dependencies from a message specification."""
    dependencies = set()

    if not hasattr(message_spec, 'structure') or not hasattr(message_spec.structure, 'members'):
        return dependencies

    for member in message_spec.structure.members:
        member_deps = extract_package_dependencies_from_type(member.type, current_package)
        dependencies.update(member_deps)

    return dependencies


def extract_package_dependencies_from_service(service_spec, current_package: str) -> Set[str]:
    """Extract package dependencies from a service specification."""
    dependencies = set()

    # Process request message
    if hasattr(service_spec, 'request_message'):
        dependencies.update(
            extract_package_dependencies_from_message(service_spec.request_message, current_package)
        )

    # Process response message
    if hasattr(service_spec, 'response_message'):
        dependencies.update(
            extract_package_dependencies_from_message(service_spec.response_message, current_package)
        )

    return dependencies


def extract_package_dependencies_from_action(action_spec, current_package: str) -> Set[str]:
    """Extract package dependencies from an action specification."""
    dependencies = set()

    # Process goal, result, and feedback messages
    for attr in ['goal', 'result', 'feedback']:
        if hasattr(action_spec, attr):
            message = getattr(action_spec, attr)
            dependencies.update(
                extract_package_dependencies_from_message(message, current_package)
            )

    return dependencies


def extract_package_dependencies_from_idl_file(idl_file_path: Path, current_package: str) -> Set[str]:
    """
    Extract package dependencies from a single IDL file.

    Args:
        idl_file_path: Path to the IDL file
        current_package: Name of the current package (to exclude self-dependencies)

    Returns:
        Set of package names that this IDL file depends on
    """
    dependencies = set()

    try:
        # Parse IDL file
        basepath = idl_file_path.parent
        locator = IdlLocator(basepath, Path(idl_file_path.name))
        idl_file_obj = parse_idl_file(locator)
        content = idl_file_obj.content

        # Extract dependencies from messages
        messages = content.get_elements_of_type(Message)
        for message_spec in messages:
            deps = extract_package_dependencies_from_message(message_spec, current_package)
            dependencies.update(deps)

        # Extract dependencies from services
        services = content.get_elements_of_type(Service)
        for service_spec in services:
            deps = extract_package_dependencies_from_service(service_spec, current_package)
            dependencies.update(deps)

        # Extract dependencies from actions
        actions = content.get_elements_of_type(Action)
        for action_spec in actions:
            deps = extract_package_dependencies_from_action(action_spec, current_package)
            dependencies.update(deps)

    except Exception as e:
        print(f"Warning: Failed to parse {idl_file_path}: {e}")

    return dependencies


def analyze_package_dependencies(idl_tuples: List[str], package_name: str) -> Dict[str, any]:
    """
    Analyze all IDL files in a package and extract dependencies.

    Args:
        idl_tuples: List of IDL file paths in "base_path:relative_path" format
        package_name: Name of the current package

    Returns:
        Dictionary containing:
        - 'interface_packages': Set of packages that provide interfaces used by this package
        - 'per_file_deps': Dict mapping each IDL file to its dependencies
    """
    all_dependencies = set()
    per_file_deps = {}

    for idl_tuple in idl_tuples:
        # Parse tuple format: "base_path:relative_path"
        parts = idl_tuple.split(':', 1)
        if len(parts) != 2:
            continue

        base_path, relative_path = parts
        idl_file = Path(base_path) / relative_path

        if not idl_file.exists():
            continue

        # Extract dependencies for this file
        file_deps = extract_package_dependencies_from_idl_file(idl_file, package_name)
        per_file_deps[str(relative_path)] = sorted(file_deps)
        all_dependencies.update(file_deps)

    return {
        'interface_packages': sorted(all_dependencies),
        'per_file_deps': per_file_deps
    }


def is_interface_package(package_name: str) -> bool:
    """
    Heuristic to determine if a package is likely an interface package.

    This is more accurate than the regex-based approach, but still a heuristic.
    True interface packages will be verified by checking if they have IDL files.
    """
    # Common patterns for interface packages
    if package_name in ['builtin_interfaces']:
        return True

    if package_name.endswith('_msgs'):
        return True

    if package_name.endswith('_interfaces'):
        return True

    # Some packages have interfaces but don't follow the naming pattern
    # e.g., rcl_interfaces has subpackages
    known_interface_packages = {
        'action_msgs',
        'lifecycle_msgs',
        'test_msgs',
        'unique_identifier_msgs',
        'rosgraph_msgs',
    }

    if package_name in known_interface_packages:
        return True

    return False


def main():
    """Command-line interface for testing."""
    import sys
    import argparse

    parser = argparse.ArgumentParser(
        description='Analyze ROS 2 IDL files to extract interface package dependencies'
    )
    parser.add_argument('package_name', help='Name of the package being analyzed')
    parser.add_argument('idl_files', nargs='+', help='IDL files to analyze')
    parser.add_argument('--format', choices=['human', 'json', 'cmake'], default='human',
                        help='Output format (default: human)')
    parser.add_argument('--output', '-o', help='Output file (default: stdout)')

    args = parser.parse_args()

    # Convert to tuples format
    idl_tuples = []
    for idl_file in args.idl_files:
        idl_path = Path(idl_file)
        if not idl_path.exists():
            print(f"Warning: {idl_file} does not exist", file=sys.stderr)
            continue

        # Create tuple format "base_path:relative_path"
        base_path = idl_path.parent
        relative_path = idl_path.name
        idl_tuples.append(f"{base_path}:{relative_path}")

    # Analyze dependencies
    result = analyze_package_dependencies(idl_tuples, args.package_name)

    # Format output
    output_str = ""
    if args.format == 'json':
        output_str = json.dumps(result, indent=2)
    elif args.format == 'cmake':
        # CMake list format: semicolon-separated
        output_str = ";".join(result['interface_packages'])
    else:  # human
        lines = [
            f"Package: {args.package_name}",
            "",
            "Interface Package Dependencies:"
        ]
        for dep in result['interface_packages']:
            indicator = " (likely interface package)" if is_interface_package(dep) else ""
            lines.append(f"  - {dep}{indicator}")

        lines.append("")
        lines.append("Per-file dependencies:")
        for file_path, deps in result['per_file_deps'].items():
            lines.append(f"  {file_path}:")
            if deps:
                for dep in deps:
                    lines.append(f"    - {dep}")
            else:
                lines.append(f"    (no dependencies)")

        output_str = "\n".join(lines)

    # Write output
    if args.output:
        with open(args.output, 'w') as f:
            f.write(output_str)
            if args.format != 'cmake':
                f.write('\n')
    else:
        print(output_str)


if __name__ == '__main__':
    main()
