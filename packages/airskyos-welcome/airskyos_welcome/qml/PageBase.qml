import QtQuick
import QtQuick.Effects

// ページ共通:横スライド+フェードで切り替わる
Item {
    id: page
    property var backend
    property int pageIndex: 0
    property int current: 0
    readonly property bool active: pageIndex === current

    x: (pageIndex - current) * (width * 0.6)
    opacity: active ? 1 : 0
    visible: opacity > 0.01
    enabled: active
    Behavior on x { NumberAnimation { duration: 520; easing.type: Easing.OutCubic } }
    // 明るい背面の上でも白文字が読めるよう、ごく薄い影を落とす
    layer.enabled: true
    layer.effect: MultiEffect {
        shadowEnabled: true
        shadowColor: Qt.rgba(0.0, 0.1, 0.35, 0.45)
        shadowBlur: 0.25
        shadowVerticalOffset: 1
        shadowHorizontalOffset: 0
    }
    Behavior on opacity { NumberAnimation { duration: 380; easing.type: Easing.OutCubic } }
}
