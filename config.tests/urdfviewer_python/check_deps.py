# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0
#
# Configure-time check: verify that the Python packages required by
# urdf2quickexporter.py are importable.  Exit 0 on success, 1 on failure.

import sys

missing = []

try:
    import urdf_parser_py
except ImportError:
    missing.append("urdf_parser_py")

try:
    import jinja2
except ImportError:
    missing.append("jinja2")

if missing:
    print(f"Missing Python packages: {', '.join(missing)}", file=sys.stderr)
    sys.exit(1)

sys.exit(0)
