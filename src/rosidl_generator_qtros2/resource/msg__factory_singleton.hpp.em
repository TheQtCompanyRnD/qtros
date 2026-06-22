// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

@# Generation template for a QML singleton exposing a value type's static
@# factory methods (which are not callable on a QML_VALUE_TYPE directly).
@# ===================================================
@#
@# Template arguments:
@# - package_name
@# - message
@{
from rosidl_generator_qtros2.template_helpers import (
    build_factory_singleton,
    build_include_guard,
)

fs = build_factory_singleton(package_name, message)
header_file = fs['value_type_include'][:-4]  # strip ".hpp"
header_guard = build_include_guard(package_name, 'msg', header_file + '_utils')
qt_export_macro = f'Q_{qt_module_name.upper()}_EXPORT'
qt_build_define = f'QT_BUILD_{qt_module_name.upper()}_LIB'
}@
#ifndef @(header_guard)
#define @(header_guard)

#include <QtCore/qglobal.h>
#if defined(@(qt_build_define))
#  define @(qt_export_macro) Q_DECL_EXPORT
#else
#  define @(qt_export_macro) Q_DECL_IMPORT
#endif

#include "@(fs['value_type_include'])"
#include <QObject>
#include <QtQml/qqmlregistration.h>

@[if fs['has_factories']]@
/*!
    \qmltype @(fs['qml_element'])
    \inqmlmodule @(fs['qml_module_uri'])
    \brief Factory functions for constructing \l @(fs['qml_value_type_name']) values.

    A singleton helper (mirroring QtQuick3D's \c Quaternion type) that exposes
    the \l @(fs['qml_value_type_name']) factory functions to QML — static methods
    on a QML value type are not otherwise callable. For example:
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
class @(qt_export_macro) @(fs['singleton_class']) : public QObject
{
    Q_OBJECT
    QML_NAMED_ELEMENT(@(fs['qml_element']))
    QML_SINGLETON

public:
    explicit @(fs['singleton_class'])(QObject* parent = nullptr) : QObject(parent) {}

@[for m in fs['methods']]@
    Q_INVOKABLE static @(m['ret']) @(m['name'])(@(m['param_decls']))
    { return @(m['ret'])::@(m['name'])(@(m['arg_names'])); }
@[  if m['vector3_overload']]@
    Q_INVOKABLE static @(m['ret']) @(m['name'])(double x, double y, double z)
    { return @(m['ret'])::@(m['name'])(QVector3D(x, y, z)); }
@[  end if]@
@[end for]@
};
@[end if]@

#endif // @(header_guard)
