# Copyright (C) 2026 The Qt Company Ltd.
# SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only WITH Qt-GPL-exception-1.0
# generated from qtros2_core/cmake/environment_hooks/qtros2_core_qml_import_path.sh

if [ -n "$AMENT_CURRENT_PREFIX" ] && [ -d "$AMENT_CURRENT_PREFIX/lib/qt6/qml" ]; then
  ament_prepend_unique_value QML_IMPORT_PATH "$AMENT_CURRENT_PREFIX/lib/qt6/qml"
  ament_prepend_unique_value QML2_IMPORT_PATH "$AMENT_CURRENT_PREFIX/lib/qt6/qml"
fi
