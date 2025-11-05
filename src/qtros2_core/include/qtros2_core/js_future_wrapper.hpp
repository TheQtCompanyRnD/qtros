// Copyright (C) 2022 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#pragma once

#include <QQmlEngine>
#include <QPointer>
#include <QJSValue>
#include <QFuture>
#include <QFutureWatcher>
#include <QVariant>
#include <type_traits>
#include <exception>
#include <memory>

class JsFutureWrapper : public QObject
{
    Q_OBJECT

public:
    explicit JsFutureWrapper(QQmlEngine* engine, QObject* parent = nullptr);
    ~JsFutureWrapper() override = default;

    bool isValid() const { return !m_engine.isNull() && m_promise.isObject(); }
    QJSValue promise() const { return m_promise; }

    void resolve(const QVariant& value = QVariant());
    void reject(const QString& message);

    static QJSValue makeRejectedPromise(QQmlEngine* engine, const QString& message, QObject* parent = nullptr);

    template<typename T>
    static QJSValue fromFuture(QQmlEngine* engine,
                               const QFuture<T>& future,
                               QObject* parent = nullptr,
                               std::shared_ptr<QString> errorMsg = nullptr)
    {
        if (!engine)
            return QJSValue();

        auto* wrapper = new JsFutureWrapper(engine, parent);
        if (!wrapper->isValid()) {
            wrapper->deleteLater();
            return QJSValue();
        }

        auto* watcher = new QFutureWatcher<T>(wrapper);
        QObject::connect(
            watcher,
            &QFutureWatcher<T>::finished,
            wrapper,
            [wrapper, watcher, errorMsg]() {
                auto future = watcher->future();
                if (future.isCanceled()) {
                    wrapper->reject(QStringLiteral("Operation canceled"));
                } else if (errorMsg && !errorMsg->isEmpty()) {
                    wrapper->reject(*errorMsg);
                } else {
                    if constexpr (std::is_void_v<T>) {
                        try {
                            future.waitForFinished();
                            wrapper->resolve();
                        } catch (const std::exception& e) {
                            wrapper->reject(QString::fromUtf8(e.what()));
                        } catch (...) {
                            wrapper->reject(QStringLiteral("Unknown error"));
                        }
                    } else {
                        try {
                            wrapper->resolve(QVariant::fromValue(future.result()));
                        } catch (const std::exception& e) {
                            wrapper->reject(QString::fromUtf8(e.what()));
                        } catch (...) {
                            wrapper->reject(QStringLiteral("Unknown error"));
                        }
                    }
                }

                watcher->deleteLater();
                wrapper->deleteLater();
            });

        watcher->setFuture(future);
        return wrapper->promise();
    }

private:
    static QJSValue createPromise(QQmlEngine* engine);

    QPointer<QQmlEngine> m_engine;
    QJSValue m_promise;
    QJSValue m_resolve;
    QJSValue m_reject;
};
