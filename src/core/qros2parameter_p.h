// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_PARAMETER_P_H
#define QROS2_PARAMETER_P_H

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

#include <QtRos2Core/qtros2coreexports.h>
#include "qros2nodechild_p.h"
#include <QString>
#include <QVariant>
#ifndef Q_QDOC
#include <rclcpp/rclcpp.hpp>
#endif

QT_BEGIN_NAMESPACE

class Q_ROS2CORE_EXPORT QRos2Parameter : public QRos2NodeChild
{
    Q_OBJECT
    QML_NAMED_ELEMENT(Parameter)

    Q_PROPERTY(QString name READ name WRITE setName NOTIFY nameChanged)
    Q_PROPERTY(QVariant value READ value WRITE setValue NOTIFY valueChanged)
    Q_PROPERTY(Type type READ type WRITE setType NOTIFY typeChanged)
    Q_PROPERTY(QString description READ description WRITE setDescription NOTIFY descriptionChanged)
    Q_PROPERTY(bool readOnly READ isReadOnly WRITE setReadOnly NOTIFY readOnlyChanged)
    Q_PROPERTY(QVariant minimum READ minimum WRITE setMinimum NOTIFY minimumChanged)
    Q_PROPERTY(QVariant maximum READ maximum WRITE setMaximum NOTIFY maximumChanged)
    Q_PROPERTY(QVariant step READ step WRITE setStep NOTIFY stepChanged)
    Q_PROPERTY(bool declared READ isDeclared NOTIFY declaredChanged)

public:
    enum Type {
        Auto,
        Bool,
        Integer,
        Double,
        String,
        ByteArray,
        BoolList,
        IntegerList,
        DoubleList,
        StringList
    };
    Q_ENUM(Type)

    explicit QRos2Parameter(QObject* parent = nullptr);
    ~QRos2Parameter() override;

    QString name() const { return m_name; }
    void setName(const QString& name);

    QVariant value() const { return m_value; }
    void setValue(const QVariant& value);

    Type type() const { return m_type; }
    void setType(Type type);

    QString description() const { return m_description; }
    void setDescription(const QString& description);

    bool isReadOnly() const { return m_readOnly; }
    void setReadOnly(bool readOnly);

    QVariant minimum() const { return m_minimum; }
    void setMinimum(const QVariant& minimum);

    QVariant maximum() const { return m_maximum; }
    void setMaximum(const QVariant& maximum);

    QVariant step() const { return m_step; }
    void setStep(const QVariant& step);

    bool isDeclared() const { return m_declared; }

    void setupConnection() override;
    void clearConnection() override;

Q_SIGNALS:
    void nameChanged();
    void valueChanged();
    void typeChanged();
    void descriptionChanged();
    void readOnlyChanged();
    void minimumChanged();
    void maximumChanged();
    void stepChanged();
    void declaredChanged();
    void valueEdited(const QVariant& value);
    void setRejected(const QString& reason);

private:
    void tryDeclare();
    void redeclare();
    void handleExternalSet(const QVariant& value);
    void descriptorChanged();

    QString m_name;
    QVariant m_value;
    Type m_type = Auto;
    QString m_description;
    bool m_readOnly = false;
    QVariant m_minimum;
    QVariant m_maximum;
    QVariant m_step;
    bool m_declared = false;

#ifndef Q_QDOC
    rclcpp::ParameterType m_resolvedType = rclcpp::ParameterType::PARAMETER_NOT_SET;
    rclcpp::node_interfaces::PostSetParametersCallbackHandle::SharedPtr m_postSetHandle;
#endif
};

QT_END_NAMESPACE

#endif // QROS2_PARAMETER_P_H
