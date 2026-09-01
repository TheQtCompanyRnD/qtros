// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_PARAMETERVALUE_P_H
#define QROS2_PARAMETERVALUE_P_H

//
//  W A R N I N G
//  -------------
//
// This file is not part of the Qt API.  It exists purely as an
// implementation detail.  This header file may change from version to
// version without notice, or even be removed.
//
// We mean it.
//

// QVariant <-> rclcpp::ParameterValue conversion shared by QRos2Parameter
// and QRos2RemoteParameter. Header-only, private.
//
// Mapping (QML/JS -> ROS):
//   bool                          -> BOOL
//   int/uint/longlong/ulonglong   -> INTEGER (int64; JS int literals)
//   double/float                  -> DOUBLE  (JS non-integral numbers)
//   QString                       -> STRING
//   QByteArray                    -> BYTE_ARRAY
//   QVariantList (homogeneous)    -> BOOL_/INTEGER_/DOUBLE_/STRING_ARRAY
//                                    (any double element promotes to DOUBLE_ARRAY)
//   invalid/undefined             -> NOT_SET (never sent; means defer/unset)
//
// Note: INTEGER is int64 on the wire but a JS number in QML; values beyond
// 2^53 lose precision when observed from QML.

#include <QVariant>
#include <QString>
#include <QByteArray>
#ifndef Q_QDOC
#include <rclcpp/parameter_value.hpp>
#endif

QT_BEGIN_NAMESPACE

namespace QRos2ParameterValueHelpers {

inline rclcpp::ParameterType inferType(const QVariant& value)
{
    switch (value.metaType().id()) {
    case QMetaType::Bool:
        return rclcpp::ParameterType::PARAMETER_BOOL;
    case QMetaType::Int:
    case QMetaType::UInt:
    case QMetaType::LongLong:
    case QMetaType::ULongLong:
        return rclcpp::ParameterType::PARAMETER_INTEGER;
    case QMetaType::Double:
    case QMetaType::Float:
        return rclcpp::ParameterType::PARAMETER_DOUBLE;
    case QMetaType::QString:
        return rclcpp::ParameterType::PARAMETER_STRING;
    case QMetaType::QByteArray:
        return rclcpp::ParameterType::PARAMETER_BYTE_ARRAY;
    case QMetaType::QVariantList: {
        const QVariantList list = value.toList();
        if (list.isEmpty())
            return rclcpp::ParameterType::PARAMETER_NOT_SET;
        bool anyDouble = false, allNumeric = true, allBool = true, allString = true;
        for (const QVariant& v : list) {
            switch (v.metaType().id()) {
            case QMetaType::Double:
            case QMetaType::Float:
                anyDouble = true;
                allBool = allString = false;
                break;
            case QMetaType::Int:
            case QMetaType::UInt:
            case QMetaType::LongLong:
            case QMetaType::ULongLong:
                allBool = allString = false;
                break;
            case QMetaType::Bool:
                allNumeric = allString = false;
                break;
            case QMetaType::QString:
                allNumeric = allBool = false;
                break;
            default:
                return rclcpp::ParameterType::PARAMETER_NOT_SET;
            }
        }
        if (allBool)
            return rclcpp::ParameterType::PARAMETER_BOOL_ARRAY;
        if (allString)
            return rclcpp::ParameterType::PARAMETER_STRING_ARRAY;
        if (allNumeric)
            return anyDouble ? rclcpp::ParameterType::PARAMETER_DOUBLE_ARRAY
                             : rclcpp::ParameterType::PARAMETER_INTEGER_ARRAY;
        return rclcpp::ParameterType::PARAMETER_NOT_SET;
    }
    default:
        return rclcpp::ParameterType::PARAMETER_NOT_SET;
    }
}

// Convert a QVariant to a ParameterValue of the given type. Returns a
// NOT_SET value when the variant cannot be coerced (caller reports the
// error). int<->double coercion is allowed (integral doubles to int).
inline rclcpp::ParameterValue toParameterValue(const QVariant& value,
                                               rclcpp::ParameterType type)
{
    using rclcpp::ParameterType;
    using rclcpp::ParameterValue;
    bool ok = false;
    switch (type) {
    case ParameterType::PARAMETER_BOOL:
        if (value.metaType().id() == QMetaType::Bool)
            return ParameterValue(value.toBool());
        break;
    case ParameterType::PARAMETER_INTEGER: {
        const qlonglong i = value.toLongLong(&ok);
        if (ok) {
            // reject non-integral doubles
            if (value.metaType().id() == QMetaType::Double
                    && value.toDouble() != static_cast<double>(i))
                break;
            return ParameterValue(static_cast<int64_t>(i));
        }
        break;
    }
    case ParameterType::PARAMETER_DOUBLE: {
        const double d = value.toDouble(&ok);
        if (ok)
            return ParameterValue(d);
        break;
    }
    case ParameterType::PARAMETER_STRING:
        if (value.metaType().id() == QMetaType::QString)
            return ParameterValue(value.toString().toStdString());
        break;
    case ParameterType::PARAMETER_BYTE_ARRAY: {
        if (value.metaType().id() == QMetaType::QByteArray) {
            const QByteArray ba = value.toByteArray();
            return ParameterValue(std::vector<uint8_t>(ba.begin(), ba.end()));
        }
        break;
    }
    case ParameterType::PARAMETER_BOOL_ARRAY: {
        std::vector<bool> out;
        for (const QVariant& v : value.toList()) {
            if (v.metaType().id() != QMetaType::Bool)
                return ParameterValue();
            out.push_back(v.toBool());
        }
        return ParameterValue(out);
    }
    case ParameterType::PARAMETER_INTEGER_ARRAY: {
        std::vector<int64_t> out;
        for (const QVariant& v : value.toList()) {
            const qlonglong i = v.toLongLong(&ok);
            if (!ok)
                return ParameterValue();
            out.push_back(static_cast<int64_t>(i));
        }
        return ParameterValue(out);
    }
    case ParameterType::PARAMETER_DOUBLE_ARRAY: {
        std::vector<double> out;
        for (const QVariant& v : value.toList()) {
            const double d = v.toDouble(&ok);
            if (!ok)
                return ParameterValue();
            out.push_back(d);
        }
        return ParameterValue(out);
    }
    case ParameterType::PARAMETER_STRING_ARRAY: {
        std::vector<std::string> out;
        for (const QVariant& v : value.toList()) {
            if (v.metaType().id() != QMetaType::QString)
                return ParameterValue();
            out.push_back(v.toString().toStdString());
        }
        return ParameterValue(out);
    }
    case ParameterType::PARAMETER_NOT_SET:
        break;
    }
    return ParameterValue();   // NOT_SET: not convertible
}

inline QVariant toVariant(const rclcpp::ParameterValue& value)
{
    using rclcpp::ParameterType;
    switch (value.get_type()) {
    case ParameterType::PARAMETER_BOOL:
        return QVariant(value.get<bool>());
    case ParameterType::PARAMETER_INTEGER:
        return QVariant(static_cast<qlonglong>(value.get<int64_t>()));
    case ParameterType::PARAMETER_DOUBLE:
        return QVariant(value.get<double>());
    case ParameterType::PARAMETER_STRING:
        return QVariant(QString::fromStdString(value.get<std::string>()));
    case ParameterType::PARAMETER_BYTE_ARRAY: {
        const auto& bytes = value.get<std::vector<uint8_t>>();
        return QVariant(QByteArray(reinterpret_cast<const char*>(bytes.data()),
                                   static_cast<qsizetype>(bytes.size())));
    }
    case ParameterType::PARAMETER_BOOL_ARRAY: {
        QVariantList out;
        for (bool b : value.get<std::vector<bool>>())
            out.append(b);
        return out;
    }
    case ParameterType::PARAMETER_INTEGER_ARRAY: {
        QVariantList out;
        for (int64_t i : value.get<std::vector<int64_t>>())
            out.append(static_cast<qlonglong>(i));
        return out;
    }
    case ParameterType::PARAMETER_DOUBLE_ARRAY: {
        QVariantList out;
        for (double d : value.get<std::vector<double>>())
            out.append(d);
        return out;
    }
    case ParameterType::PARAMETER_STRING_ARRAY: {
        QVariantList out;
        for (const std::string& s : value.get<std::vector<std::string>>())
            out.append(QString::fromStdString(s));
        return out;
    }
    case ParameterType::PARAMETER_NOT_SET:
        break;
    }
    return QVariant();
}

} // namespace QRos2ParameterValueHelpers

QT_END_NAMESPACE

#endif // QROS2_PARAMETERVALUE_P_H
