# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qtros2_generate_from_package(
    TARGET QtRos2SensorMessages
    SOURCE_PACKAGE sensor_msgs
    QML_MODULE_URI QtRos2.SensorMsgs
)

target_link_libraries(QtRos2SensorMessages PUBLIC Qt6::Gui)
