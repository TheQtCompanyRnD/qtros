// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtTest/QtTest>
#include <QtGui/QImage>
#include <QtGui/QColor>

#include <QtRos2SensorMessages/msg/image.hpp>
#include <QtRos2SensorMessages/msg/compressed_image.hpp>

#include <sensor_msgs/msg/image.hpp>
#include <sensor_msgs/msg/compressed_image.hpp>

using namespace Qtros2SensorMsgs;

class tst_sensors : public QObject
{
    Q_OBJECT
private slots:
    void image_to_qimage();              // raw rgb8 buffer -> QImage
    void compressed_image_roundtrip();   // QImage <-> PNG bytes
};

void tst_sensors::image_to_qimage()
{
    // 2x2 rgb8 image; set pixel (0,0) to red.
    QByteArray data(12, '\0'); // 2*2 px * 3 bytes
    data[0] = char(0xFF);      // R of pixel(0,0)

    Image img;
    img.setWidth(2);
    img.setHeight(2);
    img.setEncoding(QStringLiteral("rgb8"));
    img.setStep(6); // 2 px * 3 bytes
    img.setData(data);

    const QImage qi = img.image();
    QCOMPARE(qi.width(), 2);
    QCOMPARE(qi.height(), 2);
    QCOMPARE(qi.format(), QImage::Format_RGB888);
    QCOMPARE(qi.pixelColor(0, 0), QColor(255, 0, 0));

    // Round-trip the raw message through the ROS struct.
    const auto ros = static_cast<sensor_msgs::msg::Image>(img);
    QCOMPARE(ros.width, 2u);
    QCOMPARE(ros.height, 2u);
    QCOMPARE(QString::fromStdString(ros.encoding), QStringLiteral("rgb8"));
    QCOMPARE(int(ros.data.size()), 12);

    const Image back(ros);
    QCOMPARE(back.image().pixelColor(0, 0), QColor(255, 0, 0));
}

void tst_sensors::compressed_image_roundtrip()
{
    QImage src(2, 2, QImage::Format_RGB888);
    src.fill(QColor(0, 255, 0)); // green

    CompressedImage ci;
    ci.setFormat(QStringLiteral("png")); // setImage encodes PNG (lossless)
    ci.setImage(src);

    const QImage decoded = ci.image();
    QCOMPARE(decoded.size(), src.size());
    QCOMPARE(decoded.pixelColor(0, 0), QColor(0, 255, 0));

    const auto ros = static_cast<sensor_msgs::msg::CompressedImage>(ci);
    QCOMPARE(QString::fromStdString(ros.format), QStringLiteral("png"));
    QVERIFY(!ros.data.empty());

    const CompressedImage back(ros);
    QCOMPARE(back.image().pixelColor(0, 0), QColor(0, 255, 0));
}

QTEST_GUILESS_MAIN(tst_sensors)
#include "tst_sensors.moc"
