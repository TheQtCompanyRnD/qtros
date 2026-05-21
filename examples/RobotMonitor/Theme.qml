// Copyright (C) 2026 The Qt Company Ltd.
// SPDX-License-Identifier: LicenseRef-Qt-Commercial OR BSD-3-Clause
pragma Singleton

import QtQuick

QtObject {
    // Palette borrowed from the teach pendant UI
    readonly property color background: "#121826"
    readonly property color foreground: "#D4DBE6"

    readonly property color card: "#1A2332"
    readonly property color cardForeground: "#D4DBE6"

    readonly property color primary: "#3BC9DB"
    readonly property color primaryForeground: "#121826"

    readonly property color secondary: "#242E3D"
    readonly property color secondaryForeground: "#C8D0DC"

    readonly property color muted: "#1F2733"
    readonly property color mutedForeground: "#707A8A"

    readonly property color accent: "#2BA3B4"
    readonly property color accentForeground: "#E8EDF2"

    readonly property color destructive: "#E85D5D"
    readonly property color destructiveForeground: "#FFFFFF"

    readonly property color success: "#47B881"
    readonly property color successForeground: "#0B2E1A"

    readonly property color warning: "#F59E0B"
    readonly property color warningForeground: "#2E1A00"

    readonly property color border: "#2A3342"
    readonly property color input: "#242E3D"

    readonly property color panel: "#17212E"
    readonly property color panelHover: "#1E2937"

    readonly property string fontFamily: "Inter"
    readonly property string monoFontFamily: "JetBrains Mono"

    readonly property int radius: 8
    readonly property int headerHeight: 64
    readonly property int sidePanelWidth: 360

    readonly property int spacingSmall: 8
    readonly property int spacingMedium: 16
    readonly property int spacingLarge: 24

    readonly property int animationDuration: 200
}
