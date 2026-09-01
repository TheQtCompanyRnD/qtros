# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_internal_add_test(tst_sensors_qml
    GUI
    QMLTEST
    SOURCES
        tst_sensors_qml.cpp
    LIBRARIES
        Qt::Quick
    TESTDATA
        data/tst_imu.qml
)

qt_internal_extend_target(tst_sensors_qml CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_sensors_qml CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)

# C++ QTest for the QImage conversions (Image -> QImage, CompressedImage <-> QImage),
# which can't be built/compared from QML. Qt::Gui provides QImage.
# In-tree builds only — see tests/auto/geometry.
if(QT_BUILDING_QT)
    qt_internal_add_test(tst_sensors
        SOURCES
            tst_sensors.cpp
        LIBRARIES
            Qt::Gui
            QtRos2SensorMessages
    )
endif()
