# Copyright (C) 2022 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

# Copyright 2024 QtROS2 Developers
# Licensed under the Apache License, Version 2.0

import sys
import argparse
from rosidl_generator_qtros2 import generate_qtros2


def main():
    parser = argparse.ArgumentParser(description='Generate Qt/QML code for ROS 2 interfaces')
    parser.add_argument(
        '--generator-arguments-file',
        required=True,
        help='Path to the generator arguments JSON file'
    )
    args = parser.parse_args()

    try:
        generated_files = generate_qtros2(args.generator_arguments_file)
        print(f"Generated {len(generated_files)} files")
        return 0
    except Exception as e:
        print(f"Error: {e}", file=sys.stderr)
        import traceback
        traceback.print_exc()
        return 1


if __name__ == '__main__':
    sys.exit(main())
