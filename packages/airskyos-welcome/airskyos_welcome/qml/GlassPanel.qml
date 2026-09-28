import QtQuick
import QtQuick.Effects

// ガラス調パネル(ウィンドウのガラス層の上に重ねる一段明るいガラス)
//  背面のぼかしは KWin がウィンドウ全体に掛けているので、ここでは
//  ティント + 上部の光沢 + 縁のハイライト(光の屈折っぽさ)+ 影 を描く
Item {
    id: root

    property real radius: 26
    property real tintOpacity: 0.14
    property real glossOpacity: 0.20
    property bool shadow: true
    property bool hovered: false
    property real pressedAmount: 0
    default property alias content: contentArea.data
    readonly property alias contentItem: contentArea

    // ---- 影 ----
    RectangularShadow {
        visible: root.shadow
        anchors.fill: parent
        radius: root.radius
        offset.y: 8
        blur: 30
        spread: -6
        color: Qt.rgba(0.0, 0.08, 0.3, 0.22)
    }

    // ---- ガラス本体 ----
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.tintOpacity + 0.08 + (root.hovered ? 0.06 : 0) + root.pressedAmount * 0.06) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, root.tintOpacity + (root.hovered ? 0.06 : 0) + root.pressedAmount * 0.06) }
        }
        Behavior on opacity { NumberAnimation { duration: 150 } }
    }
    // 上部の光沢(角丸に沿うよう、上半分だけ見せる)
    Item {
        id: glossClip
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: Math.min(parent.height * 0.5, 120)
        clip: true
        Rectangle {
            width: parent.width
            height: root.height
            radius: root.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, root.glossOpacity) }
                GradientStop { position: glossClip.height / Math.max(root.height, 1); color: Qt.rgba(1, 1, 1, 0) }
            }
        }
    }

    // ---- 縁のハイライト(左上と右下が光る) ----
    Rectangle {
        anchors.fill: parent
        radius: root.radius
        color: "transparent"
        border.width: 1.2
        border.color: Qt.rgba(1, 1, 1, 0.6)
        layer.enabled: true
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: rimMask
            maskThresholdMin: 0.0
            maskSpreadAtMin: 1.0
        }
    }
    Item {
        id: rimMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle {
            anchors.fill: parent
            gradient: Gradient {
                orientation: Gradient.Horizontal
                GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 1) }
                GradientStop { position: 0.5; color: Qt.rgba(0, 0, 0, 0.35) }
                GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.85) }
            }
        }
    }
    // 内側のうっすらした縁
    Rectangle {
        anchors.fill: parent
        anchors.margins: 1.5
        radius: root.radius - 1.5
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.12)
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }
}
