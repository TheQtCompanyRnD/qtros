// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "qros2parameter_p.h"
#include "qros2node_p.h"
#include "qros2parametervalue_p.h"

#include <QCoreApplication>
#include <QLoggingCategory>
#include <QPointer>
#include <QThread>

#include <limits>

/*!
    \qmltype Parameter
    \inqmlmodule QtRos2.Core
    \inherits NodeChild
    \brief Declares a ROS 2 node parameter: named, settable, observable state.

    Parameter exposes one named value on its \l {NodeChild::node}{node}
    through the standard ROS 2 parameter machinery: it can be read and
    set with \c {ros2 param get/set}, by rqt, or by a \l RemoteParameter
    in another process; every change is announced on the global
    \c /parameter_events topic; and \l minimum, \l maximum and
    \l readOnly are enforced by rclcpp itself before any change is
    accepted.

    \qml
    Node {
        nodeName: "robot"
        Parameter {
            name: "audio.master"
            value: volumeCtl.master
            minimum: 0.0; maximum: 1.0
            description: "Master (default sink) volume"
            onValueEdited: (v) => volumeCtl.master = v
        }
    }
    \endqml

    The \l value property works both ways, following the
    \c {TextField.text} / \c textEdited convention: writes from the
    application (including bindings) are published as parameter changes,
    and an external set updates the property and then emits
    \l valueEdited. When \l value is bound, the application is the
    authority: handle \l valueEdited and route the new value into the
    binding's source, which then echoes it back (a no-op when equal).
    If \l valueEdited is ignored on a bound value, an external set only
    holds until the binding re-evaluates.
*/

/*!
    \qmlproperty string Parameter::name

    The parameter name (e.g. \c {"audio.master"}). Changing it after the
    parameter is declared undeclares and redeclares it.
*/

/*!
    \qmlproperty var Parameter::value

    The parameter value. Writes are coerced to the declared \l type and
    rejected (with \l setRejected) when not representable or when they
    violate the declared constraints. External sets update this property
    and emit \l valueEdited.
*/

/*!
    \qmlproperty enumeration Parameter::type

    The declared ROS parameter type. With the default \c Parameter.Auto
    the type is inferred from the first valid \l value; until then the
    declaration is deferred (\l declared stays \c false). Set an explicit
    type to declare immediately with that type's default value.

    \value Parameter.Auto infer from the first valid value
    \value Parameter.Bool \value Parameter.Integer \value Parameter.Double
    \value Parameter.String \value Parameter.ByteArray
    \value Parameter.BoolList \value Parameter.IntegerList
    \value Parameter.DoubleList \value Parameter.StringList

    \note Integer parameters are 64-bit on the wire but JavaScript
    numbers in QML: values beyond 2^53 lose precision.
*/

/*!
    \qmlproperty string Parameter::description

    Human-readable description, published in the parameter descriptor
    (visible to \c {ros2 param describe} and rqt).
*/

/*!
    \qmlproperty bool Parameter::readOnly

    Declares the parameter immutable: every set after declaration —
    including the application's own writes — is rejected by rclcpp.
    Useful for publishing constants for introspection.
*/

/*!
    \qmlproperty var Parameter::minimum
    \qmlproperty var Parameter::maximum
    \qmlproperty var Parameter::step

    Range constraint for \c Integer and \c Double parameters, published
    in the descriptor and enforced by rclcpp: an out-of-range set is
    rejected before the value changes (the CLI reports the allowed
    range). Leave undefined for no constraint; ignored with a warning
    for other types.
*/

/*!
    \qmlproperty bool Parameter::declared

    Read-only: \c true while the parameter is declared on the node.
    \c false before the node initializes and while an \c Auto-typed
    parameter is still waiting for its first valid value.
*/

/*!
    \qmlsignal Parameter::valueEdited(var value)

    Emitted when the parameter was set externally (\c {ros2 param set},
    a \l RemoteParameter, another node) — after \l value has been
    updated. Not emitted for the application's own writes. When \l value
    is bound, handle this signal and route \a value into the binding's
    source of truth.
*/

/*!
    \qmlsignal Parameter::setRejected(string reason)

    Emitted when a write to \l value could not be applied — \a reason
    describes why (wrong type, or rejected by rclcpp: range violation,
    read-only). \l value is restored to the actual parameter value.
*/

QT_BEGIN_NAMESPACE

Q_STATIC_LOGGING_CATEGORY(lcParam, "qt.robotics.parameter")

using namespace QRos2ParameterValueHelpers;

static rclcpp::ParameterType toRosType(QRos2Parameter::Type type)
{
    switch (type) {
    case QRos2Parameter::Bool:        return rclcpp::ParameterType::PARAMETER_BOOL;
    case QRos2Parameter::Integer:     return rclcpp::ParameterType::PARAMETER_INTEGER;
    case QRos2Parameter::Double:      return rclcpp::ParameterType::PARAMETER_DOUBLE;
    case QRos2Parameter::String:      return rclcpp::ParameterType::PARAMETER_STRING;
    case QRos2Parameter::ByteArray:   return rclcpp::ParameterType::PARAMETER_BYTE_ARRAY;
    case QRos2Parameter::BoolList:    return rclcpp::ParameterType::PARAMETER_BOOL_ARRAY;
    case QRos2Parameter::IntegerList: return rclcpp::ParameterType::PARAMETER_INTEGER_ARRAY;
    case QRos2Parameter::DoubleList:  return rclcpp::ParameterType::PARAMETER_DOUBLE_ARRAY;
    case QRos2Parameter::StringList:  return rclcpp::ParameterType::PARAMETER_STRING_ARRAY;
    case QRos2Parameter::Auto:        break;
    }
    return rclcpp::ParameterType::PARAMETER_NOT_SET;
}

// The default value used when declaring with an explicit type before the
// first application write (so the parameter is visible to tooling from
// node start).
static QVariant zeroVariant(rclcpp::ParameterType type)
{
    switch (type) {
    case rclcpp::ParameterType::PARAMETER_BOOL:    return QVariant(false);
    case rclcpp::ParameterType::PARAMETER_INTEGER: return QVariant(qlonglong(0));
    case rclcpp::ParameterType::PARAMETER_DOUBLE:  return QVariant(0.0);
    case rclcpp::ParameterType::PARAMETER_STRING:  return QVariant(QString());
    case rclcpp::ParameterType::PARAMETER_BYTE_ARRAY: return QVariant(QByteArray());
    default: return QVariant(QVariantList());
    }
}

QRos2Parameter::QRos2Parameter(QObject* parent)
    : QRos2NodeChild(parent)
{
}

QRos2Parameter::~QRos2Parameter()
{
    // Base destructor unregisters from the node; the post-set callback
    // handle is a weak registration in rclcpp and expires with it.
}

void QRos2Parameter::setName(const QString& name)
{
    if (m_name == name) return;
    const bool wasDeclared = m_declared;
    if (wasDeclared)
        clearConnection();
    m_name = name;
    emit nameChanged();
    setupConnection();
}

void QRos2Parameter::setType(Type type)
{
    if (m_type == type) return;
    m_type = type;
    emit typeChanged();
    if (m_declared)
        redeclare();
    else
        tryDeclare();
}

void QRos2Parameter::setDescription(const QString& description)
{
    if (m_description == description) return;
    m_description = description;
    emit descriptionChanged();
    descriptorChanged();
}

void QRos2Parameter::setReadOnly(bool readOnly)
{
    if (m_readOnly == readOnly) return;
    m_readOnly = readOnly;
    emit readOnlyChanged();
    descriptorChanged();
}

void QRos2Parameter::setMinimum(const QVariant& minimum)
{
    if (m_minimum == minimum) return;
    m_minimum = minimum;
    emit minimumChanged();
    descriptorChanged();
}

void QRos2Parameter::setMaximum(const QVariant& maximum)
{
    if (m_maximum == maximum) return;
    m_maximum = maximum;
    emit maximumChanged();
    descriptorChanged();
}

void QRos2Parameter::setStep(const QVariant& step)
{
    if (m_step == step) return;
    m_step = step;
    emit stepChanged();
    descriptorChanged();
}

void QRos2Parameter::descriptorChanged()
{
    if (m_declared)
        redeclare();
}

void QRos2Parameter::setValue(const QVariant& value)
{
    if (m_declared && m_node && m_node->rosNode()) {
        // Coerce to the declared type; normalized so property comparisons
        // are stable (e.g. an int write to a Double parameter stores 1.0).
        const rclcpp::ParameterValue pv = toParameterValue(value, m_resolvedType);
        if (pv.get_type() == rclcpp::ParameterType::PARAMETER_NOT_SET) {
            qCWarning(lcParam) << m_name << "value" << value
                               << "is not convertible to the declared parameter type";
            emit setRejected(QStringLiteral("value not convertible to declared type"));
            return;
        }
        const QVariant normalized = toVariant(pv);
        if (normalized == m_value)
            return;
        m_value = normalized;
        emit valueChanged();

        // Our own set: rclcpp runs the callbacks synchronously on this
        // thread; the post-set callback recognizes it (thread check).
        const auto result = m_node->rosNode()->set_parameter(
            rclcpp::Parameter(m_name.toStdString(), pv));
        if (!result.successful) {
            const QString reason = QString::fromStdString(result.reason);
            qCWarning(lcParam) << m_name << "set rejected:" << reason;
            emit setRejected(reason);
            // Restore from the actual parameter value.
            rclcpp::Parameter actual;
            if (m_node->rosNode()->get_parameter(m_name.toStdString(), actual)) {
                const QVariant v = toVariant(actual.get_parameter_value());
                if (v != m_value) {
                    m_value = v;
                    emit valueChanged();
                }
            }
        }
        return;
    }

    // Not declared yet: store, and declare if the type is now resolvable.
    if (value == m_value)
        return;
    m_value = value;
    emit valueChanged();
    tryDeclare();
}

void QRos2Parameter::setupConnection()
{
    tryDeclare();
}

void QRos2Parameter::tryDeclare()
{
    if (m_declared || !m_node || !m_node->rosNode() || m_name.isEmpty())
        return;

    rclcpp::ParameterType type = toRosType(m_type);
    if (type == rclcpp::ParameterType::PARAMETER_NOT_SET)
        type = inferType(m_value);
    if (type == rclcpp::ParameterType::PARAMETER_NOT_SET) {
        // Auto type and no valid value yet (e.g. state arriving
        // asynchronously): defer until the first valid write.
        qCDebug(lcParam) << m_name << "declare deferred until a value is set";
        return;
    }

    QVariant initial = m_value;
    rclcpp::ParameterValue pv = toParameterValue(initial, type);
    if (pv.get_type() == rclcpp::ParameterType::PARAMETER_NOT_SET) {
        initial = zeroVariant(type);
        pv = toParameterValue(initial, type);
    }

    rcl_interfaces::msg::ParameterDescriptor descriptor;
    descriptor.name = m_name.toStdString();
    descriptor.description = m_description.toStdString();
    descriptor.read_only = m_readOnly;
    const bool hasRange = m_minimum.isValid() || m_maximum.isValid();
    if (hasRange) {
        if (type == rclcpp::ParameterType::PARAMETER_DOUBLE) {
            rcl_interfaces::msg::FloatingPointRange range;
            range.from_value = m_minimum.isValid() ? m_minimum.toDouble()
                                                   : std::numeric_limits<double>::lowest();
            range.to_value = m_maximum.isValid() ? m_maximum.toDouble()
                                                 : std::numeric_limits<double>::max();
            range.step = m_step.isValid() ? m_step.toDouble() : 0.0;
            descriptor.floating_point_range.push_back(range);
        } else if (type == rclcpp::ParameterType::PARAMETER_INTEGER) {
            rcl_interfaces::msg::IntegerRange range;
            range.from_value = m_minimum.isValid() ? m_minimum.toLongLong()
                                                   : std::numeric_limits<int64_t>::lowest();
            range.to_value = m_maximum.isValid() ? m_maximum.toLongLong()
                                                 : std::numeric_limits<int64_t>::max();
            range.step = m_step.isValid() ? m_step.toULongLong() : 0;
            descriptor.integer_range.push_back(range);
        } else {
            qCWarning(lcParam) << m_name
                               << "minimum/maximum are only supported for Integer and Double parameters";
        }
    }

    try {
        m_node->rosNode()->declare_parameter(m_name.toStdString(), pv, descriptor);
    } catch (const std::exception& e) {
        qCWarning(lcParam) << m_name << "declare_parameter failed:" << e.what();
        return;
    }

    m_resolvedType = type;

    // Reflect normalization (or the zero default) in the property.
    const QVariant declared = toVariant(pv);
    if (declared != m_value) {
        m_value = declared;
        emit valueChanged();
    }

    // React to external sets. rclcpp invokes this synchronously on the
    // thread that called set_parameter: our own writes come from the GUI
    // thread (recognized and ignored), external service requests arrive
    // on the executor spin thread and are marshalled over.
    auto weakThis = QPointer<QRos2Parameter>(this);
    const std::string paramName = m_name.toStdString();
    m_postSetHandle = m_node->rosNode()->add_post_set_parameters_callback(
        [weakThis, paramName](const std::vector<rclcpp::Parameter>& parameters) {
            if (!weakThis)
                return;
            for (const auto& parameter : parameters) {
                if (parameter.get_name() != paramName)
                    continue;
                if (QThread::currentThread() == weakThis->thread())
                    continue;   // self-set; state already consistent
                const QVariant v = toVariant(parameter.get_parameter_value());
                QMetaObject::invokeMethod(
                    qApp,
                    [weakThis, v] {
                        if (weakThis)
                            weakThis->handleExternalSet(v);
                    },
                    Qt::QueuedConnection);
            }
        });

    m_declared = true;
    emit declaredChanged();
}

void QRos2Parameter::handleExternalSet(const QVariant& value)
{
    if (value == m_value)
        return;
    m_value = value;
    emit valueChanged();
    emit valueEdited(value);
}

void QRos2Parameter::redeclare()
{
    clearConnection();
    setupConnection();
}

void QRos2Parameter::clearConnection()
{
    m_postSetHandle.reset();
    if (m_declared && m_node && m_node->rosNode() && !m_readOnly) {
        try {
            m_node->rosNode()->undeclare_parameter(m_name.toStdString());
        } catch (const std::exception& e) {
            qCDebug(lcParam) << m_name << "undeclare_parameter:" << e.what();
        }
    }
    m_resolvedType = rclcpp::ParameterType::PARAMETER_NOT_SET;
    if (m_declared) {
        m_declared = false;
        emit declaredChanged();
    }
}

QT_END_NAMESPACE
