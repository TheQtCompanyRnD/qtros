// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include "jsfuturewrapper_p.h"
#include <QDebug>

QT_BEGIN_NAMESPACE

JsFutureWrapper::JsFutureWrapper(QQmlEngine* engine, QObject* parent)
    : QObject(parent)
    , m_engine(engine)
{
    if (!m_engine)
        return;

    m_promise = createPromise(m_engine);
    if (!m_promise.isObject())
        return;

    m_resolve = m_promise.property(QStringLiteral("resolve"));
    m_reject = m_promise.property(QStringLiteral("reject"));
}

QJSValue JsFutureWrapper::createPromise(QQmlEngine* engine)
{
    if (!engine)
        return QJSValue();

    QJSValue promise = engine->evaluate(
        QStringLiteral("(function() { let res, rej; const p = new Promise((resolve, reject) => { res = resolve; rej = reject; }); "
                       "p.resolve = res; p.reject = rej; return p; })()"));

    if (promise.isError()) {
        return QJSValue();
    }

    return promise;
}

void JsFutureWrapper::resolve(const QVariant& value)
{
    if (!isValid())
        return;

    QJSValueList args;
    if (value.isValid()) {
        args << m_engine->toScriptValue(value);
    }
    m_resolve.call(args);
}

void JsFutureWrapper::reject(const QString& message)
{
    if (!isValid())
        return;

    QJSValue error = m_engine->newErrorObject(QJSValue::GenericError, message);
    m_reject.call(QJSValueList() << error);
}

QJSValue JsFutureWrapper::makeRejectedPromise(QQmlEngine* engine, const QString& message, QObject* parent)
{
    if (!engine)
        return QJSValue();

    auto* wrapper = new JsFutureWrapper(engine, parent);
    if (!wrapper->isValid()) {
        wrapper->deleteLater();
        return QJSValue();
    }

    wrapper->reject(message);
    QJSValue promise = wrapper->promise();
    wrapper->deleteLater();
    return promise;
}

QT_END_NAMESPACE
