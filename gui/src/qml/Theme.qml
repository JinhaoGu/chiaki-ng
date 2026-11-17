pragma Singleton
import QtQuick

// Shared look for the whole UI. Colors follow the macOS dark appearance so the app sits
// naturally next to other Mac apps; the same values are used on every platform.
QtObject {
    // Surfaces, from back to front
    readonly property color background: "#1c1c1e"
    readonly property color sidebar: "#242426"
    readonly property color card: "#2c2c2e"
    readonly property color cardHover: "#353538"
    readonly property color control: "#3a3a3c"
    readonly property color separator: "#38383a"

    // Text
    readonly property color textPrimary: "#f5f5f7"
    readonly property color textSecondary: "#98989d"
    readonly property color textTertiary: "#636366"

    // Tints
    readonly property color accent: "#0a84ff"
    readonly property color accentPressed: "#0060df"
    readonly property color green: "#30d158"
    readonly property color orange: "#ff9f0a"
    readonly property color red: "#ff453a"

    // Shape
    readonly property int radiusSmall: 6
    readonly property int radius: 10
    readonly property int radiusLarge: 14

    // Type scale (pixels)
    readonly property int fontCaption: 12
    readonly property int fontBody: 14
    readonly property int fontHeadline: 16
    readonly property int fontTitle: 22
    readonly property int fontLargeTitle: 28

    // Spacing
    readonly property int gap: 8
    readonly property int margin: 24
}
