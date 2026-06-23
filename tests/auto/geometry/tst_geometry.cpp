// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR GPL-3.0-only

#include <QtTest/QtTest>
#include <QtGui/QQuaternion>
#include <QtGui/QVector3D>

#include <QtRos2GeometryMessages/msg/quaternion.hpp>
#include <QtRos2GeometryMessages/msg/vector3.hpp>
#include <QtRos2GeometryMessages/msg/point.hpp>
#include <QtRos2GeometryMessages/msg/pose.hpp>
#include <QtRos2GeometryMessages/msg/twist.hpp>

#include <geometry_msgs/msg/quaternion.hpp>
#include <geometry_msgs/msg/vector3.hpp>
#include <geometry_msgs/msg/point.hpp>
#include <geometry_msgs/msg/pose.hpp>
#include <geometry_msgs/msg/twist.hpp>

using namespace Qtros2GeometryMsgs;

// Exercises the C++ value-type <-> ROS message struct conversions
// (the operator geometry_msgs::msg::X() and the X(const ros&) constructor),
// which are not reachable from QML.
class tst_geometry : public QObject
{
    Q_OBJECT
private slots:
    void quaternion_roundtrip();
    void quaternion_default_w_is_one();
    void quaternion_from_qquaternion();
    void vector3_roundtrip();
    void point_roundtrip();
    void pose_roundtrip();
    void twist_roundtrip();
};

void tst_geometry::quaternion_roundtrip()
{
    Quaternion q;
    q.setX(0.1);
    q.setY(0.2);
    q.setZ(0.3);
    q.setW(0.4);

    const auto ros = static_cast<geometry_msgs::msg::Quaternion>(q);
    QCOMPARE(ros.x, 0.1);
    QCOMPARE(ros.y, 0.2);
    QCOMPARE(ros.z, 0.3);
    QCOMPARE(ros.w, 0.4);

    const Quaternion back(ros);
    QVERIFY(back == q);
}

void tst_geometry::quaternion_default_w_is_one()
{
    const Quaternion q;
    QCOMPARE(q.w(), 1.0); // identity, honoring the IDL @default(value=1.0)
    const auto ros = static_cast<geometry_msgs::msg::Quaternion>(q);
    QCOMPARE(ros.w, 1.0);
    QCOMPARE(ros.x, 0.0);
    QCOMPARE(ros.y, 0.0);
    QCOMPARE(ros.z, 0.0);
}

void tst_geometry::quaternion_from_qquaternion()
{
    // QQuaternion is (scalar, x, y, z); scalar must map onto w.
    const QQuaternion qq(0.7071f, 0.0f, 0.7071f, 0.0f);
    const Quaternion q(qq);
    QVERIFY(qFuzzyCompare(float(q.w()), 0.7071f));
    QVERIFY(qFuzzyCompare(float(q.y()), 0.7071f));
    QVERIFY(qFuzzyIsNull(float(q.x())));
    QVERIFY(qFuzzyIsNull(float(q.z())));
}

void tst_geometry::vector3_roundtrip()
{
    Vector3 v;
    v.setX(1.0);
    v.setY(2.0);
    v.setZ(3.0);

    const auto ros = static_cast<geometry_msgs::msg::Vector3>(v);
    QCOMPARE(ros.x, 1.0);
    QCOMPARE(ros.y, 2.0);
    QCOMPARE(ros.z, 3.0);

    const Vector3 back(ros);
    QVERIFY(back == v);
}

void tst_geometry::point_roundtrip()
{
    Point p;
    p.setX(-1.0);
    p.setY(-2.0);
    p.setZ(-3.0);

    const auto ros = static_cast<geometry_msgs::msg::Point>(p);
    QCOMPARE(ros.x, -1.0);
    QCOMPARE(ros.y, -2.0);
    QCOMPARE(ros.z, -3.0);

    const Point back(ros);
    QVERIFY(back == p);
}

void tst_geometry::pose_roundtrip()
{
    Point pos;
    pos.setX(1.0);
    pos.setY(2.0);
    pos.setZ(3.0);
    Quaternion orient;
    orient.setX(0.0);
    orient.setY(0.0);
    orient.setZ(0.0);
    orient.setW(1.0);

    Pose pose;
    pose.setPosition(pos);
    pose.setOrientation(orient);

    const auto ros = static_cast<geometry_msgs::msg::Pose>(pose);
    QCOMPARE(ros.position.x, 1.0);
    QCOMPARE(ros.position.z, 3.0);
    QCOMPARE(ros.orientation.w, 1.0);

    const Pose back(ros);
    QVERIFY(back == pose);
}

void tst_geometry::twist_roundtrip()
{
    Vector3 lin;
    lin.setX(1.0);
    lin.setY(2.0);
    lin.setZ(3.0);
    Vector3 ang;
    ang.setX(4.0);
    ang.setY(5.0);
    ang.setZ(6.0);

    Twist twist;
    twist.setLinear(lin);
    twist.setAngular(ang);

    const auto ros = static_cast<geometry_msgs::msg::Twist>(twist);
    QCOMPARE(ros.linear.x, 1.0);
    QCOMPARE(ros.angular.z, 6.0);

    const Twist back(ros);
    QVERIFY(back == twist);
}

QTEST_GUILESS_MAIN(tst_geometry)
#include "tst_geometry.moc"
