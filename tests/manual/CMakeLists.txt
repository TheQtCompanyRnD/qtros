# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Don't build manual tests when targeting iOS.
if(UIKIT)
    return()
endif()

add_subdirectory(urfdrobotarm)
