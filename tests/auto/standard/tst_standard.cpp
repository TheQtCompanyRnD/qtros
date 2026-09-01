// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtTest/QtTest>

#include <QtRos2StandardMessages/msg/color_rgba.hpp>
#include <QtRos2StandardMessages/msg/string.hpp>
#include <QtRos2StandardMessages/msg/int32.hpp>

#include <std_msgs/msg/color_rgba.hpp>
#include <std_msgs/msg/string.hpp>
#include <std_msgs/msg/int32.hpp>

using namespace Qtros2StdMsgs;

class tst_standard : public QObject
{
    Q_OBJECT
private slots:
    void colorRgba_roundtrip();
    void string_roundtrip();   // QString <-> std::string
    void int32_roundtrip();
};

void tst_standard::colorRgba_roundtrip()
{
    ColorRGBA c;
    c.setR(0.1f);
    c.setG(0.2f);
    c.setB(0.3f);
    c.setA(1.0f);

    const auto ros = static_cast<std_msgs::msg::ColorRGBA>(c);
    QCOMPARE(ros.r, 0.1f);
    QCOMPARE(ros.g, 0.2f);
    QCOMPARE(ros.b, 0.3f);
    QCOMPARE(ros.a, 1.0f);

    const ColorRGBA back(ros);
    QVERIFY(back == c);
}

void tst_standard::string_roundtrip()
{
    const QString text = QStringLiteral("héllo, ROS — 日本語");
    String s;
    s.setData(text);

    const auto ros = static_cast<std_msgs::msg::String>(s);
    QCOMPARE(QString::fromStdString(ros.data), text);

    const String back(ros);
    QCOMPARE(back.data(), text);
}

void tst_standard::int32_roundtrip()
{
    Int32 i;
    i.setData(-1234567);

    const auto ros = static_cast<std_msgs::msg::Int32>(i);
    QCOMPARE(ros.data, -1234567);

    const Int32 back(ros);
    QCOMPARE(back.data(), -1234567);
}

QTEST_GUILESS_MAIN(tst_standard)
#include "tst_standard.moc"
