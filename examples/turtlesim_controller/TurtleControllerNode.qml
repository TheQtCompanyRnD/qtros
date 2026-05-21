// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick
import QtRos2.Core
import QtRos2.Imported.Turtlesim
import QtRos2.GeometryMsgs as Geom

Item {
    id: root
    property string baseName: ""
    required property Node rosNode
    readonly property alias rotateAction: rotateAction
    readonly property alias setPenService: setPenService
    readonly property alias twistPublisher: twistPublisher
    readonly property alias poseSubscriber: poseSubscriber
    readonly property alias teleportAbsoluteService: teleportAbsoluteService
    readonly property alias teleportRelativeService: teleportRelativeService
    readonly property alias rotateFeedbackText: _d.feedbackText
    readonly property alias rotateStatusText: _d.statusText
    readonly property alias rotateResultText: _d.resultText
    readonly property alias pose: poseSubscriber.message

    function publishVelocity(lx, ly, lz, ax, ay, az) {
        root.publishTwist({
                              "linear": {
                                  "x": lx,
                                  "y": ly,
                                  "z": lz
                              },
                              "angular": {
                                  "x": ax,
                                  "y": ay,
                                  "z": az
                              }
                          })
    }

    function publishTwist(t: Geom.geometrymsgs_twist) {
        twistPublisher.publish(t)
    }

    function sendRotationGoal(theta) {
        _d.feedbackText = "Feedback: ..."
        _d.resultText = "Result: ..."
        rotateAction.sendGoal(theta).then(delta => {
                                              _d.resultText = "Delta: " + delta.toFixed(
                                                  3) + " rad"
                                          }).catch(error => {
                                                       console.error(
                                                           "Rotation failed:",
                                                           error)
                                                   })
    }

    function drawQt(r, g, b, width) {

        const svgWidth = 960
        const svgHeight = 705
        const turtleWidth = 11
        const turtleHeight = 11


        const margin = 0.5
        const scaleX = (turtleWidth - 2 * margin) / svgWidth
        const scaleY = (turtleHeight - 2 * margin) / svgHeight

        function mapX(svgX) {
            return margin + svgX * scaleX
        }

        function mapY(svgY) {
            return turtleHeight - (margin + svgY * scaleY)
        }

        function moveTo(x, y) {
            return setPenService.callService({r: r, g: g, b: b, width: width, off: true})
                .then(() => teleportAbsoluteService.callService({x: x, y: y, theta: 0}))
        }

        function lineTo(x, y, penWidth) {
            return setPenService.callService({r: r, g: g, b: b, width: penWidth, off: false})
                .then(() => teleportAbsoluteService.callService({x: x, y: y, theta: 0}))
        }

        console.log("Starting Qt drawing...")

        const qOuter = [
            [340, 180], [315, 182], [292, 188], [272, 198],
            [254, 212], [239, 230], [227, 252], [219, 278],
            [214, 307], [212, 338],
            [212, 347], [214, 378], [219, 407], [227, 433],
            [239, 455], [254, 473], [272, 487], [292, 497],
            [315, 503], [340, 505],
            [365, 503], [388, 497], [408, 487], [426, 473],
            [441, 455], [453, 433], [461, 407], [466, 378],
            [468, 347],
            [468, 338], [466, 307], [461, 278], [453, 252],
            [441, 230], [426, 212], [408, 198], [388, 188],
            [365, 182], [340, 180]
        ]

        const qTail = [
            [420, 475], [442, 497], [465, 520], [487, 542]
        ]

        const tVertical = [
            [590, 200], [590, 235], [590, 270], [590, 305],
            [590, 340], [590, 375], [590, 410], [590, 445],
            [590, 470], [595, 485], [605, 495], [620, 502],
            [640, 505], [660, 505]
        ]

        const tCross = [
            [540, 285], [560, 285], [580, 285], [600, 285],
            [620, 285], [640, 285], [660, 285], [680, 285]
        ]

        let promise = moveTo(mapX(qOuter[0][0]), mapY(qOuter[0][1]))

        for (let i = 1; i < qOuter.length; i++) {
            promise = promise.then(() => lineTo(mapX(qOuter[i][0]), mapY(qOuter[i][1]), width))
        }

        promise = promise.then(() => moveTo(mapX(qTail[0][0]), mapY(qTail[0][1])))
        for (let i = 1; i < qTail.length; i++) {
            promise = promise.then(() => lineTo(mapX(qTail[i][0]), mapY(qTail[i][1]), width))
        }

        promise = promise.then(() => moveTo(mapX(tVertical[0][0]), mapY(tVertical[0][1])))
        for (let i = 1; i < tVertical.length; i++) {
            promise = promise.then(() => lineTo(mapX(tVertical[i][0]), mapY(tVertical[i][1]), width))
        }

        promise = promise.then(() => moveTo(mapX(tCross[0][0]), mapY(tCross[0][1])))
        for (let i = 1; i < tCross.length; i++) {
            promise = promise.then(() => lineTo(mapX(tCross[i][0]), mapY(tCross[i][1]), width))
        }

        promise.then(() => {
            console.log("Qt drawing complete!")
        }).catch(error => {
            console.error("Drawing failed:", error)
        })
    }

    readonly property QtObject _d: QtObject {
        id: _d
        property string feedbackText: "Feedback: N/A"
        property string resultText: "Result: N/A"

        function getFeedbackText(state): string {
            switch (state) {
            case RotateAbsoluteActionClient.Idle:
                return "Status: Idle"
            case RotateAbsoluteActionClient.Requested:
                return "Sending goal..."
            case RotateAbsoluteActionClient.Accepted:
                return "Rotation Goal Accepted"
            case RotateAbsoluteActionClient.Rejected:
                return "Rotation Goal Rejected"
            case RotateAbsoluteActionClient.Canceled:
                return "Rotation Cancelled"
            case RotateAbsoluteActionClient.Aborted:
                return "Rotation Aborted"
            case RotateAbsoluteActionClient.Succeeded:
                return "Rotation Complete"
            }
        }

        readonly property string statusText: getFeedbackText(rotateAction.state)
    }

    RotateAbsoluteActionClient {
        id: rotateAction
        node: root.rosNode

        topic: `/${root.baseName}/rotate_absolute`

        onFeedbackChanged: feedback => _d.feedbackText = "Remaining: " + feedback.toFixed(
                               3) + " rad"
    }

    // Service Client for pen control
    SetPenServiceClient {
        id: setPenService
        node: root.rosNode

        topic: `/${root.baseName}/set_pen`
    }

    // Publisher for velocity commands
    Geom.TwistPublisher {
        id: twistPublisher
        node: root.rosNode

        topic: `/${root.baseName}/cmd_vel`
    }

    // Subscriber for turtle pose
    PoseSubscriber {
        id: poseSubscriber
        node: root.rosNode
        topic: `/${root.baseName}/pose`
    }

    TeleportAbsoluteServiceClient {
        id: teleportAbsoluteService
        node: root.rosNode

        topic: `/${root.baseName}/teleport_absolute`
    }

    TeleportRelativeServiceClient {
        id: teleportRelativeService
        node: root.rosNode

        topic: `/${root.baseName}/teleport_relative`
    }
}
