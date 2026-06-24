// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template carrying the QML documentation for a value type's factory
@# singleton. The class itself is header-only (see msg__factory_singleton.hpp.em);
@# this translation unit exists so the \qmltype / \qmlmethod docs sit in a qdoc
@# sourcedir (.cpp), which is required for qdoc to generate the QML type page.
@# ===================================================
@#
@# Template arguments:
@# - package_name
@# - message
@{
from rosidl_generator_qtros2.template_helpers import build_factory_singleton

fs = build_factory_singleton(package_name, message)
header_file = fs['value_type_include'][:-4]  # strip ".hpp"
qml_module = fs['qml_module_uri']
value_type = fs['qml_value_type_name']
}@
#include "@(header_file)_utils.hpp"

@[if fs['has_factories']]@
/*!
    \qmltype @(fs['qml_element'])
    \inqmlmodule @(qml_module)
    \brief Factory functions for constructing \l {@(qml_module)::}{@(value_type)} values.

    A singleton helper (mirroring QtQuick3D's \c Quaternion type) that exposes the
    \l {@(qml_module)::}{@(value_type)} factory functions to QML. For example:
    \c {@(fs['qml_element']).fromEulerAngles(0, 90, 0)}.
*/

@[for m in fs['qml_method_docs']]@
/*!
    \qmlmethod @(m['signature'])
@[  if m.get('brief')]@
    \brief @(m['brief'])
@[    if m.get('body')]@

@[      for line in m['body']]@
    @(line)
@[      end for]@
@[    end if]@
@[  end if]@
*/

@[end for]@
@[end if]@
