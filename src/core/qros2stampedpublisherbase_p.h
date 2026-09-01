// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#ifndef QROS2_STAMPEDPUBLISHERBASE_P_H
#define QROS2_STAMPEDPUBLISHERBASE_P_H

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
#include "qros2publisherbase_p.h"
#ifndef Q_QDOC
#include <builtin_interfaces/msg/time.hpp>
#endif

class Q_ROS2CORE_EXPORT QRos2StampedPublisherBase : public QRos2PublisherBase
{
    Q_OBJECT
    QML_NAMED_ELEMENT(StampedPublisherBase)
    QML_UNCREATABLE("Abstract")

    Q_PROPERTY(bool autoStamp READ autoStamp WRITE setAutoStamp NOTIFY autoStampChanged)

public:
    explicit QRos2StampedPublisherBase(QObject* parent = nullptr);

    bool autoStamp() const { return m_autoStamp; }
    void setAutoStamp(bool autoStamp);

Q_SIGNALS:
    void autoStampChanged();

protected:
    // Called by generated stamped publishers just before sending. When autoStamp
    // is enabled and the stamp is still unset (zero), fills it with the node clock
    // time; an explicitly-set or forwarded stamp is left untouched.
    void applyAutoStamp(builtin_interfaces::msg::Time& stamp) const;

private:
    bool m_autoStamp = true;
};

#endif // QROS2_STAMPEDPUBLISHERBASE_P_H
