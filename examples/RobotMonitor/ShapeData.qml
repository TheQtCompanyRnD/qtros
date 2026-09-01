// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
import QtQuick

VisualSettings {
    id: pathData
    readonly property alias shapePoints: _d.points
    readonly property alias center: _d.center
    readonly property alias width: _d.width
    readonly property alias height: _d.height
    readonly property alias textureWidth: _d.textureWidth
    readonly property alias textureHeight: _d.textureHeight

    property int strokeWidth: 8
    property color strokeColor: "#00FF00"
    property color fillColor: "transparent"
    property bool closed: false

    property list<vector3d> sourcePoints: []

    property QtObject _d: QtObject {
        id: _d
        property list<point> points: []
        property real textureWidth: 128
        property real textureHeight: 128

        property vector3d center: Qt.vector3d(0, 0, 0)
        property real width: 0
        property real height: 0

        function updatePoints() {
            let points = []
            if (pathData.sourcePoints.length === 0) {
                _d.center = Qt.vector3d(0, 0, 0)
                _d.width = 0
                _d.height = 0
                _d.points = []
                return
            }

            let minX = Number.POSITIVE_INFINITY
            let maxX = Number.NEGATIVE_INFINITY
            let minY = Number.POSITIVE_INFINITY
            let maxY = Number.NEGATIVE_INFINITY

            pathData.sourcePoints.forEach(p => {
                                              minX = Math.min(minX, p.x)
                                              maxX = Math.max(maxX, p.x)
                                              minY = Math.min(minY, p.y)
                                              maxY = Math.max(maxY, p.y)
                                          })

            _d.width = maxX - minX
            _d.height = maxY - minY
            const padding = pathData.strokeWidth + 4
            const minTexSizeX = Math.max(pathData.width * 128, padding)
            const minTexSizeY = Math.max(pathData.height * 128, padding)
            const logX = Math.log2(minTexSizeX)
            const logY = Math.log2(minTexSizeY)

            _d.textureWidth = 2 ** Math.ceil(logX)
            _d.textureHeight = 2 ** Math.ceil(logY)

            _d.center = Qt.vector3d(minX + pathData.width / 2,
                                    minY + pathData.height / 2, 0)

            const innerW = _d.textureWidth - 4 - pathData.strokeWidth
            const innerH = _d.textureHeight - 4 - pathData.strokeWidth
            const halfStroke = pathData.strokeWidth / 2 + 2
            points = pathData.sourcePoints.map(
                        p => Qt.point(
                            (p.x - minX) / _d.width * innerW + halfStroke,
                            (p.y - minY) / _d.height * innerH + halfStroke))

            if (pathData.closed) {
                points.push(points[0])
            }

            _d.points = points
        }
    }

    onSourcePointsChanged: _d.updatePoints()
}
