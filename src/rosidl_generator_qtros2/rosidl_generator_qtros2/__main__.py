# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0

# Copyright 2024 QtROS2 Developers
# Licensed under the Apache License, Version 2.0

import sys
import json
import argparse
from rosidl_generator_qtros2 import generate_qtros2


def main():
    parser = argparse.ArgumentParser(description='Generate Qt/QML code for ROS 2 interfaces')
    parser.add_argument(
        '--generator-arguments-file',
        required=True,
        help='Path to the generator arguments JSON file'
    )
    parser.add_argument(
        '--qt-package-mapping',
        default='{}',
        help='JSON dict mapping ROS2 package names to Qt module include directory names'
    )
    parser.add_argument(
        '--source-package',
        default='',
        help='ROS2 source package name used for namespace generation'
    )
    args = parser.parse_args()

    try:
        qt_package_mapping = json.loads(args.qt_package_mapping)
    except json.JSONDecodeError as e:
        import sys
        print(f"Warning: failed to parse --qt-package-mapping: {e}", file=sys.stderr)
        qt_package_mapping = {}

    try:
        generated_files = generate_qtros2(args.generator_arguments_file, qt_package_mapping, args.source_package or None)
        print(f"Generated {len(generated_files)} files")
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
