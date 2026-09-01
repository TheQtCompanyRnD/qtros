# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# NOTE: builtin and rcl are added directly in src/CMakeLists.txt (phase 1) before
# messages packages, so they are NOT listed here. composition and type_description
# are added in phase 3 (after messages). This file is kept for reference only.
#
# Dependency order:
#   builtin → (none)
#   rcl     → builtin
#   composition → rcl
#   type_description → service_msgs (messages package)
