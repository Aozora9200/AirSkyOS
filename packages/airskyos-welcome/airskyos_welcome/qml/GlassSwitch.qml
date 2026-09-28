import QtQuick
import QtQuick.Effects

// ガラス調のトグルスイッチ(ラベル付き)
Item {
    id: sw
    property bool checked: false
    property string text: ""
    signal toggled(bool checked)

    implicitWidth: row.implicitWidth
    implicitHeight: 32

    Row {
        id: row
        anchors.verticalCenter: parent.verticalCenter
        spacing: 12

        Item {
            id: track
            width: 52; height: 30
            anchors.verticalCenter: parent.verticalCenter

            Rectangle {
                anchors.fill: parent
                radius: height / 2
                color: sw.checked ? Qt.rgba(0.25, 0.65, 1.0, 0.85) : Qt.rgba(1, 1, 1, 0.18)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, sw.checked ? 0.6 : 0.4)
                Behavior on color { ColorAnimation { duration: 220 } }
                Rectangle {
                    anchors { left: parent.left; right: parent.right; top: parent.top; margins: 2 }
                    height: parent.height / 2 - 2
                    radius: height / 2
                    color: Qt.rgba(1, 1, 1, 0.18)
                }
            }

            // つまみ(ドラッグ中は少し伸びる=液体っぽさ)
            Rectangle {
                id: knob
                readonly property real baseW: 24
                width: mouse.pressed ? 30 : baseW
                height: 24
                radius: 12
                y: 3
                x: sw.checked ? track.width - width - 3 : 3
                color: "white"
                Behavior on x { NumberAnimation { duration: 260; easing.type: Easing.OutBack; easing.overshoot: 1.6 } }
                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                layer.enabled: true
                layer.effect: MultiEffect {
                    shadowEnabled: true
                    shadowColor: Qt.rgba(0, 0.15, 0.4, 0.45)
                    shadowBlur: 0.5
                    shadowVerticalOffset: 2
                }
            }
        }

        Text {
            text: sw.text
            color: "white"
            font.pixelSize: 14
            anchors.verticalCenter: parent.verticalCenter
        }
    }

    MouseArea {
        id: mouse
        anchors.fill: parent
        cursorShape: Qt.PointingHandCursor
        onClicked: {
            sw.checked = !sw.checked
            sw.toggled(sw.checked)
        }
    }

    Accessible.role: Accessible.CheckBox
    Accessible.name: text
    Accessible.checked: checked
}
