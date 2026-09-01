# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

# Topological order (interface/builtin and interfaces/rcl already added before this):
#   standard, service, unique_identifier, lifecycle, statistics, rosgraph
#     → depend only on builtin_interfaces (already added)
#   geometry → standard
#   action   → builtin, service, unique_identifier
#   diagnostics, sensors, shapes, stereo, trajectory, navigation
#     → geometry (and/or standard, sensor_msgs)
#   visualization → geometry + sensors + standard
#   tf2          → geometry, action, service (LookupTransform.action, FrameGraph.srv)

add_subdirectory(standard)
add_subdirectory(service)
add_subdirectory(unique_identifier)
add_subdirectory(lifecycle)
add_subdirectory(statistics)
add_subdirectory(rosgraph)
add_subdirectory(geometry)
add_subdirectory(action)
add_subdirectory(diagnostics)
add_subdirectory(sensors)
add_subdirectory(shapes)
add_subdirectory(stereo)
add_subdirectory(trajectory)
add_subdirectory(navigation)
add_subdirectory(visualization)
add_subdirectory(tf2)
