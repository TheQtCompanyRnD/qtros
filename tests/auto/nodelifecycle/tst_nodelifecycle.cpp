// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: BSD-3-Clause

#include <QtRos2Core/private/qros2node_p.h>
#include <QtRos2Core/private/qros2entity_p.h>

#include <QtTest/qtest.h>

// A minimal concrete entity: implements the pure-virtual connection hooks as
// no-ops so the test needs no generated message module. The node is never
// componentComplete()'d, so no rclcpp context / participant is created -- this
// exercises the pure Qt object-model teardown, nothing ROS.
class TestEntity : public QRos2Entity
{
    Q_OBJECT
public:
    using QRos2Entity::QRos2Entity;
protected:
    void setupConnection() override {}
    void clearConnection() override {}
};

class tst_nodelifecycle : public QObject
{
    Q_OBJECT
private slots:
    void destroyNodeWithEntityChildren();
};

// Regression test for the use-after-free seen when a QtRos2 GUI app with a
// subscriber quit: ~QRos2Node frees its m_entities list, then the ~QObject base
// destructor deletes the child entities, whose ~QRos2Entity calls back into
// QRos2Node::unregisterEntity() and mutated the freed list. The entities here are
// QObject children of the node (as QML arranges) and are registered via setNode(),
// reproducing both halves of the bug. Run under AddressSanitizer
// (LD_PRELOAD=libasan.so) for a deterministic check; on a plain build the loop and
// multiple children make the corruption very likely to surface.
void tst_nodelifecycle::destroyNodeWithEntityChildren()
{
    for (int iter = 0; iter < 20; ++iter) {
        auto *node = new QRos2Node;
        for (int i = 0; i < 8; ++i) {
            auto *entity = new TestEntity(node); // QObject child of the node
            entity->setNode(node);               // also registers in m_entities
        }
        delete node; // ~QRos2Node frees m_entities, then deletes the children
    }
    QVERIFY(true); // reaching here without aborting is the test
}

QTEST_GUILESS_MAIN(tst_nodelifecycle)

#include "tst_nodelifecycle.moc"
