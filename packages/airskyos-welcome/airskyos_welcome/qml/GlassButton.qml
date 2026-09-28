import QtQuick
import QtQuick.Effects

// ガラスのボタン。accent: true で青く光るメインボタンになる
GlassPanel {
    id: btn
    property string text: ""
    property string iconText: ""
    property bool accent: false
    property int fontSize: 14
    signal clicked()

    implicitWidth: Math.max(label.implicitWidth + 44, 96)
    implicitHeight: 42
    radius: height / 2
    shadow: accent
    hovered: mouse.containsMouse && enabled
    pressedAmount: mouse.pressed ? 1 : 0
    tintOpacity: accent ? 0.0 : 0.12
    opacity: enabled ? 1 : 0.45
    scale: mouse.pressed ? 0.97 : 1
    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

    // アクセントの青いにじみ
    Rectangle {
        anchors.fill: parent
        radius: btn.radius
        visible: btn.accent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.35, 0.72, 1.0, btn.hovered ? 0.85 : 0.72) }
            GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.45, 0.95, btn.hovered ? 0.85 : 0.72) }
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
            height: parent.height / 2
            radius: height / 2
            color: Qt.rgba(1, 1, 1, 0.22)
        }
    }

    Row {
        id: label
        anchors.centerIn: parent
        spacing: 8
        Text {
            visible: btn.iconText !== ""
            text: btn.iconText
            color: "white"
            font.pixelSize: btn.fontSize + 2
            anchors.verticalCenter: parent.verticalCenter
        }
        Text {
            text: btn.text
            color: "white"
            font.pixelSize: btn.fontSize
            font.weight: btn.accent ? Font.DemiBold : Font.Medium
            anchors.verticalCenter: parent.verticalCenter
            style: Text.Raised
            styleColor: Qt.rgba(0, 0.2, 0.5, 0.25)
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: btn.enabled ? Qt.PointingHandCursor : Qt.ArrowCursor
        onClicked: if (btn.enabled) btn.clicked()
    }
}
