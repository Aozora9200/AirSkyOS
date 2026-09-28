import QtQuick

// ウィンドウ全面のガラス層。
// blurActive=true: KWin がウィンドウ背面をぼかしてくれるので薄いティントだけ
// blurActive=false: ブラーが使えない環境(コンポジタ無し等)では読みやすさ優先で不透明寄りに
Item {
    id: base
    property bool blurActive: true
    readonly property real a: blurActive ? 1.0 : 2.4

    // 空色のティント(上ほど明るい青、下ほど深い青)
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(0.30, 0.60, 0.98, Math.min(0.40 * base.a, 0.92)) }
            GradientStop { position: 0.55; color: Qt.rgba(0.18, 0.46, 0.90, Math.min(0.44 * base.a, 0.94)) }
            GradientStop { position: 1.0; color: Qt.rgba(0.10, 0.34, 0.78, Math.min(0.50 * base.a, 0.96)) }
        }
    }
    // 左上から差し込む光
    Rectangle {
        anchors.fill: parent
        gradient: Gradient {
            orientation: Gradient.Horizontal
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.10) }
            GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
    // 上端の光沢
    Rectangle {
        anchors { left: parent.left; right: parent.right; top: parent.top }
        height: 140
        gradient: Gradient {
            GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.16) }
            GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
        }
    }
}
