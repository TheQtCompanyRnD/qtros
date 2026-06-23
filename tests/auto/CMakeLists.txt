# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

add_subdirectory(geometry)
add_subdirectory(sensors)
add_subdirectory(standard)
add_subdirectory(urdfimport)
add_subdirectory(urdfimportros)
if(TARGET Qt6::Quick3DPhysics)
    add_subdirectory(urdfimportphysics)
endif()
