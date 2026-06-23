# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: BSD-3-Clause

qt_internal_add_test(tst_standard_qml
    GUI
    QMLTEST
    SOURCES
        tst_standard_qml.cpp
    LIBRARIES
        Qt::Quick
    TESTDATA
        data/tst_color_rgba.qml
        data/tst_string.qml
)

qt_internal_extend_target(tst_standard_qml CONDITION ANDROID OR IOS
    DEFINES
        QT_QMLTEST_DATADIR=":/data"
)
qt_internal_extend_target(tst_standard_qml CONDITION NOT ANDROID AND NOT IOS
    DEFINES
        QT_QMLTEST_DATADIR="${CMAKE_CURRENT_SOURCE_DIR}/data"
)

qt_internal_add_test(tst_standard
    SOURCES
        tst_standard.cpp
    LIBRARIES
        QtRos2StandardMessages
)
