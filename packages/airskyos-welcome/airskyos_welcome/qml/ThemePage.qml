import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

// AirSkyOS のテーマ(ClearSky / ClearSky Dark)を
// 「デフォルトに戻す」「デザインだけ」「レイアウトだけ」で適用するページ
PageBase {
    id: page
    objectName: "themePage"
    property var theme

    readonly property bool busy: theme ? theme.busy : false
    property string selected: {
        if (!theme) return "ClearSky"
        const c = theme.current
        return (c === "ClearSky" || c === "ClearSky Dark") ? c : theme.defaultTheme
    }
    // 確認ダイアログ用
    property string pendingMode: ""

    readonly property var actions: [
        { mode: "default", icon: "↺", title: "デフォルトに戻す", accent: true, confirm: true,
          body: "デザインとレイアウト(パネル・ウィジェット・壁紙)を、すべて AirSkyOS の既定に戻します。" },
        { mode: "design", icon: "◐", title: "デザインだけ適用", accent: false, confirm: false,
          body: "配色・Plasma スタイル・ウィンドウ装飾・カーソル・アイコン。パネルや壁紙はそのまま。" },
        { mode: "layout", icon: "▦", title: "レイアウトだけ適用", accent: false, confirm: true,
          body: "パネル・ウィジェットの配置と壁紙だけ。今の配色やスタイルはそのまま。" }
    ]

    function run(mode) {
        const a = actions.find(x => x.mode === mode)
        if (a.confirm) pendingMode = mode
        else theme.apply(mode, selected)
    }

    ColumnLayout {
        anchors.fill: parent
        spacing: 16

        // ---- 見出し ----
        ColumnLayout {
            Layout.leftMargin: 4
            spacing: 2
            Text {
                text: "AirSkyOS のテーマ"
                color: "white"
                font.pixelSize: 19
                font.weight: Font.DemiBold
            }
            Text {
                text: "ライト / ダークを選んで、適用したい内容のボタンを押してください。"
                color: Qt.rgba(1, 1, 1, 0.85)
                font.pixelSize: 13
            }
        }

        // ---- テーマ選択 ----
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 16

            Repeater {
                model: page.theme ? page.theme.themes : []
                GlassPanel {
                    id: card
                    required property var modelData
                    readonly property bool isSelected: page.selected === modelData.id
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    tintOpacity: isSelected ? 0.26 : 0.12
                    hovered: cardMouse.containsMouse && modelData.installed
                    opacity: modelData.installed ? 1 : 0.55

                    Rectangle {
                        anchors.fill: parent
                        radius: card.radius
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(0.75, 0.92, 1, 0.95)
                        opacity: card.isSelected ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    ColumnLayout {
                        anchors { fill: parent; margins: 14 }
                        spacing: 10

                        // プレビュー(角丸)
                        Item {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: Qt.rgba(1, 1, 1, 0.1)
                                visible: prev.status !== Image.Ready
                                Text {
                                    anchors.centerIn: parent
                                    text: card.modelData.installed ? "プレビューなし" : "未インストール"
                                    color: Qt.rgba(1, 1, 1, 0.8)
                                    font.pixelSize: 13
                                }
                            }
                            Image {
                                id: prev
                                anchors.fill: parent
                                source: card.modelData.preview
                                fillMode: Image.PreserveAspectCrop
                                asynchronous: true
                                smooth: true
                                visible: false
                            }
                            MultiEffect {
                                anchors.fill: prev
                                source: prev
                                visible: prev.status === Image.Ready
                                maskEnabled: true
                                maskSource: prevMask
                                maskThresholdMin: 0.5
                                maskSpreadAtMin: 1.0
                            }
                            Item {
                                id: prevMask
                                anchors.fill: parent
                                layer.enabled: true
                                visible: false
                                Rectangle { anchors.fill: parent; radius: 14; color: "black" }
                            }
                            Rectangle {
                                anchors.fill: parent
                                radius: 14
                                color: "transparent"
                                border.color: Qt.rgba(1, 1, 1, 0.45)
                            }
                        }

                        RowLayout {
                            Layout.fillWidth: true
                            spacing: 8
                            // ラジオ
                            Rectangle {
                                width: 20; height: 20; radius: 10
                                color: card.isSelected ? Qt.rgba(0.25, 0.65, 1, 0.95) : Qt.rgba(1, 1, 1, 0.12)
                                border.width: 1.5
                                border.color: Qt.rgba(1, 1, 1, 0.8)
                                Rectangle {
                                    anchors.centerIn: parent
                                    width: 8; height: 8; radius: 4
                                    color: "white"
                                    visible: card.isSelected
                                }
                            }
                            Text {
                                text: card.modelData.id
                                color: "white"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                text: card.modelData.label
                                color: Qt.rgba(1, 1, 1, 0.8)
                                font.pixelSize: 13
                            }
                            Item { Layout.fillWidth: true }
                            Badge { text: "使用中"; visible: page.theme.current === card.modelData.id }
                            Badge { text: "既定"; visible: page.theme.defaultTheme === card.modelData.id }
                        }
                    }

                    MouseArea {
                        id: cardMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: card.modelData.installed && !page.busy
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.selected = card.modelData.id
                    }
                }
            }
        }

        // ---- 操作 ----
        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: false
            Layout.preferredHeight: 176
            Layout.maximumHeight: 176
            spacing: 16

            Repeater {
                model: page.actions
                GlassPanel {
                    id: act
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hovered: actHover.hovered
                    HoverHandler { id: actHover }

                    ColumnLayout {
                        anchors { fill: parent; margins: 16 }
                        spacing: 6
                        RowLayout {
                            spacing: 10
                            Rectangle {
                                width: 32; height: 32; radius: 10
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.5) }
                                    GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.18) }
                                }
                                border.color: Qt.rgba(1, 1, 1, 0.6)
                                Text {
                                    anchors.centerIn: parent
                                    text: act.modelData.icon
                                    color: "white"
                                    font.pixelSize: 17
                                }
                            }
                            Text {
                                text: act.modelData.title
                                color: "white"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                        }
                        Text {
                            Layout.fillWidth: true
                            Layout.fillHeight: true
                            text: act.modelData.body
                            color: Qt.rgba(1, 1, 1, 0.88)
                            font.pixelSize: 12
                            lineHeight: 1.15
                            wrapMode: Text.WordWrap
                            maximumLineCount: 3
                            elide: Text.ElideRight
                        }
                        GlassButton {
                            Layout.alignment: Qt.AlignRight
                            text: page.busy ? "適用中…" : "適用"
                            accent: act.modelData.accent
                            implicitHeight: 36
                            implicitWidth: 104
                            enabled: !page.busy && page.theme.available
                            onClicked: page.run(act.modelData.mode)
                        }
                    }
                }
            }
        }

        // ---- 状態 ----
        Text {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            Layout.preferredHeight: 18
            text: !page.theme ? ""
                  : !page.theme.available ? "plasma-apply-lookandfeel が見つかりません(KDE Plasma 上で実行してください)"
                  : page.theme.status
            color: page.theme && !page.theme.statusOk ? "#ffd2d2" : Qt.rgba(1, 1, 1, 0.92)
            font.pixelSize: 13
            elide: Text.ElideRight
        }
    }

    // ---- 確認ダイアログ ----
    Item {
        anchors.fill: parent
        visible: opacity > 0.01
        opacity: page.pendingMode !== "" ? 1 : 0
        Behavior on opacity { NumberAnimation { duration: 180 } }
        z: 10

        Rectangle {
            anchors.fill: parent
            radius: 26
            color: Qt.rgba(0.02, 0.08, 0.25, 0.55)
            MouseArea { anchors.fill: parent; onClicked: page.pendingMode = "" }
        }

        GlassPanel {
            anchors.centerIn: parent
            width: 480
            height: 236
            tintOpacity: 0.22
            scale: page.pendingMode !== "" ? 1 : 0.94
            Behavior on scale { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            // 読みやすさのため、ダイアログだけ濃い空色を敷く
            Rectangle {
                anchors.fill: parent
                radius: 26
                color: Qt.rgba(0.12, 0.38, 0.82, 0.55)
            }
            ColumnLayout {
                id: dlg
                anchors { fill: parent; margins: 24 }
                spacing: 12
                Text {
                    text: page.pendingMode === "default" ? "デフォルトに戻しますか?" : "レイアウトを適用しますか?"
                    color: "white"
                    font.pixelSize: 18
                    font.weight: Font.DemiBold
                }
                Text {
                    Layout.fillWidth: true
                    text: "今のパネル・ウィジェットの配置と壁紙は「" + page.selected
                          + "」の既定のものに置き換わります。元には戻せません。"
                          + (page.pendingMode === "default" ? "\n配色やスタイルなどのデザインも既定に戻ります。" : "")
                    color: Qt.rgba(1, 1, 1, 0.9)
                    font.pixelSize: 13
                    lineHeight: 1.3
                    wrapMode: Text.WordWrap
                }
                Item { Layout.fillHeight: true }
                RowLayout {
                    Layout.alignment: Qt.AlignRight
                    spacing: 10
                    GlassButton {
                        text: "キャンセル"
                        onClicked: page.pendingMode = ""
                    }
                    GlassButton {
                        text: "適用する"
                        accent: true
                        implicitWidth: 120
                        onClicked: {
                            const m = page.pendingMode
                            page.pendingMode = ""
                            page.theme.apply(m, page.selected)
                        }
                    }
                }
            }
        }
    }

    component Badge: Rectangle {
        property alias text: badgeText.text
        implicitWidth: badgeText.implicitWidth + 16
        implicitHeight: 22
        radius: 11
        color: Qt.rgba(1, 1, 1, 0.2)
        border.color: Qt.rgba(1, 1, 1, 0.5)
        Text {
            id: badgeText
            anchors.centerIn: parent
            color: "white"
            font.pixelSize: 11
        }
    }
}
