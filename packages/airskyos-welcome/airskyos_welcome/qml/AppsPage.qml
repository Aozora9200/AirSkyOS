import QtQuick
import QtQuick.Layouts
import QtQuick.Controls.Basic

PageBase {
    id: page

    // 選択中のパッケージ(pkg文字列の配列)
    property var selected: []
    readonly property bool busy: backend ? backend.busy : false

    function toggle(pkg) {
        const s = selected.slice()
        const i = s.indexOf(pkg)
        if (i >= 0) s.splice(i, 1); else s.push(pkg)
        selected = s
    }

    Connections {
        target: page.backend
        // インストール完了後、導入済みになったものを選択から外す
        function onInstalledChanged() {
            page.selected = page.selected.filter(p => !page.backend.isInstalled(p))
        }
    }
    onActiveChanged: if (active && backend && !busy) backend.refreshInstalled()

    ColumnLayout {
        anchors.fill: parent
        spacing: 18

        // ---- システム更新 ----
        GlassPanel {
            Layout.fillWidth: true
            Layout.preferredHeight: 104

            RowLayout {
                anchors { fill: parent; leftMargin: 24; rightMargin: 20 }
                spacing: 18

                Rectangle {
                    Layout.preferredWidth: 52
                    Layout.preferredHeight: 52
                    radius: 17
                    gradient: Gradient {
                        GradientStop { position: 0; color: Qt.rgba(0.55, 0.85, 1, 0.9) }
                        GradientStop { position: 1; color: Qt.rgba(0.15, 0.5, 0.95, 0.9) }
                    }
                    border.color: Qt.rgba(1, 1, 1, 0.7)
                    Text {
                        anchors.centerIn: parent
                        text: "⟳"
                        color: "white"
                        font.pixelSize: 28
                        RotationAnimation on rotation {
                            running: page.busy
                            from: 0; to: 360; duration: 1400
                            loops: Animation.Infinite
                        }
                    }
                }

                ColumnLayout {
                    Layout.fillWidth: true
                    spacing: 4
                    Text {
                        text: "システムを最新の状態に"
                        color: "white"
                        font.pixelSize: 19
                        font.weight: Font.DemiBold
                    }
                    Text {
                        Layout.fillWidth: true
                        text: page.busy
                              ? "ターミナルで実行中です… 終わったらウィンドウを閉じてください。"
                              : page.backend.isLive
                                ? "ライブ環境での更新やアプリの追加は、再起動すると消えます。インストール後に行うのがおすすめです。"
                                : "初回起動後はまず更新するのがおすすめです。パスワードの入力を求められます。"
                        color: Qt.rgba(1, 1, 1, 0.88)
                        font.pixelSize: 13
                        wrapMode: Text.WordWrap
                    }
                }

                GlassButton {
                    visible: page.backend.hasRateMirrors
                    text: "ミラーを最適化"
                    enabled: !page.busy
                    onClicked: page.backend.rateMirrors()
                }
                GlassButton {
                    text: "今すぐ更新"
                    accent: true
                    implicitWidth: 132
                    enabled: !page.busy
                    onClicked: page.backend.updateSystem()
                }
            }
        }

        // ---- おすすめアプリ見出し ----
        RowLayout {
            Layout.fillWidth: true
            Layout.leftMargin: 4
            spacing: 12
            ColumnLayout {
                spacing: 2
                Text {
                    text: "おすすめアプリ"
                    color: "white"
                    font.pixelSize: 19
                    font.weight: Font.DemiBold
                }
                Text {
                    text: "使いたいアプリを選んで、まとめてインストールできます。"
                    color: Qt.rgba(1, 1, 1, 0.85)
                    font.pixelSize: 13
                }
            }
            Item { Layout.fillWidth: true }
            GlassButton {
                text: "選択を解除"
                visible: page.selected.length > 0
                onClicked: page.selected = []
            }
            GlassButton {
                text: page.selected.length > 0
                      ? page.selected.length + " 個をインストール"
                      : "インストール"
                accent: page.selected.length > 0
                implicitWidth: 170
                enabled: page.selected.length > 0 && !page.busy
                onClicked: page.backend.installPackages(page.selected)
            }
        }

        // ---- アプリ一覧 ----
        GridView {
            id: grid
            Layout.fillWidth: true
            Layout.fillHeight: true
            clip: true
            readonly property int columns: Math.max(3, Math.floor(width / 210))
            cellWidth: Math.floor(width / columns)
            cellHeight: 84
            model: page.backend.apps
            boundsBehavior: Flickable.StopAtBounds
            ScrollBar.vertical: ScrollBar {
                policy: grid.contentHeight > grid.height ? ScrollBar.AsNeeded : ScrollBar.AlwaysOff
                contentItem: Rectangle { implicitWidth: 5; radius: 3; color: Qt.rgba(1, 1, 1, 0.55) }
                background: null
            }

            delegate: Item {
                id: cell
                required property var modelData
                readonly property bool installed: {
                    page.backend.installed    // 依存関係として参照
                    return page.backend.isInstalled(modelData.pkg)
                }
                readonly property bool checked: page.selected.indexOf(modelData.pkg) >= 0
                width: grid.cellWidth
                height: grid.cellHeight

                GlassPanel {
                    anchors { fill: parent; margins: 6 }
                    radius: 20
                    shadow: false
                    hovered: tileMouse.containsMouse && !cell.installed
                    tintOpacity: cell.checked ? 0.30 : 0.12
                    pressedAmount: tileMouse.pressed ? 1 : 0

                    Rectangle {
                        anchors.fill: parent
                        radius: 20
                        color: "transparent"
                        border.width: 2
                        border.color: Qt.rgba(0.75, 0.92, 1, 0.95)
                        opacity: cell.checked ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 180 } }
                    }

                    RowLayout {
                        anchors { fill: parent; leftMargin: 12; rightMargin: 12 }
                        spacing: 10
                        Item {
                            Layout.preferredWidth: 36
                            Layout.preferredHeight: 36
                            readonly property bool themed: page.backend.hasIcon(cell.modelData.icon)
                            Image {
                                anchors.fill: parent
                                visible: parent.themed
                                source: parent.themed ? "image://icon/" + cell.modelData.icon : ""
                                sourceSize: Qt.size(72, 72)
                                smooth: true
                            }
                            // アイコンが無いときは頭文字のガラス玉
                            Rectangle {
                                anchors.fill: parent
                                visible: !parent.themed
                                radius: 12
                                gradient: Gradient {
                                    GradientStop { position: 0; color: Qt.rgba(0.6, 0.87, 1, 0.95) }
                                    GradientStop { position: 1; color: Qt.rgba(0.18, 0.52, 0.96, 0.95) }
                                }
                                border.color: Qt.rgba(1, 1, 1, 0.7)
                                Text {
                                    anchors.centerIn: parent
                                    text: cell.modelData.name.charAt(0)
                                    color: "white"
                                    font.pixelSize: 18
                                    font.bold: true
                                }
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 1
                            Text {
                                Layout.fillWidth: true
                                text: cell.modelData.name
                                color: "white"
                                font.pixelSize: 14
                                font.weight: Font.DemiBold
                                elide: Text.ElideRight
                            }
                            Text {
                                Layout.fillWidth: true
                                text: cell.installed ? "インストール済み" : cell.modelData.desc
                                color: Qt.rgba(1, 1, 1, cell.installed ? 0.95 : 0.8)
                                font.pixelSize: 12
                                elide: Text.ElideRight
                            }
                        }
                        // チェックマーク
                        Rectangle {
                            Layout.preferredWidth: 22
                            Layout.preferredHeight: 22
                            radius: 11
                            color: cell.installed ? Qt.rgba(0.4, 0.85, 0.6, 0.9)
                                 : cell.checked ? Qt.rgba(0.25, 0.65, 1, 0.95)
                                 : Qt.rgba(1, 1, 1, 0.12)
                            border.width: 1.5
                            border.color: Qt.rgba(1, 1, 1, 0.8)
                            Behavior on color { ColorAnimation { duration: 180 } }
                            Text {
                                anchors.centerIn: parent
                                text: "✓"
                                color: "white"
                                font.pixelSize: 13
                                font.bold: true
                                visible: cell.checked || cell.installed
                            }
                        }
                    }

                    MouseArea {
                        id: tileMouse
                        anchors.fill: parent
                        hoverEnabled: true
                        enabled: !cell.installed
                        cursorShape: Qt.PointingHandCursor
                        onClicked: page.toggle(cell.modelData.pkg)
                    }
                }
            }
        }
    }
}
