import QtQuick
import QtQuick.Layouts
import QtQuick.Effects

PageBase {
    id: page

    ColumnLayout {
        anchors.fill: parent
        spacing: 20

        RowLayout {
            Layout.fillWidth: true
            Layout.fillHeight: true
            spacing: 24

            // ---- ヒーロー ----
            ColumnLayout {
                Layout.fillWidth: true
                Layout.fillHeight: true
                spacing: 6

                Item { Layout.fillHeight: true }

                Text {
                    text: page.backend.userName !== ""
                          ? "ようこそ、" + page.backend.userName + " さん"
                          : "ようこそ"
                    color: Qt.rgba(1, 1, 1, 0.9)
                    font.pixelSize: 17
                    font.weight: Font.Medium
                }
                Text {
                    text: "AirSkyOS"
                    color: "white"
                    font.pixelSize: 58
                    font.weight: Font.Bold
                    font.letterSpacing: -1
                    layer.enabled: true
                    layer.effect: MultiEffect {
                        shadowEnabled: true
                        shadowColor: Qt.rgba(0, 0.25, 0.6, 0.35)
                        shadowBlur: 0.6
                        shadowVerticalOffset: 3
                    }
                }
                Text {
                    Layout.fillWidth: true
                    Layout.topMargin: 4
                    text: "透きとおる空のように、軽やかなデスクトップを。\n"
                          + "CachyOS の速さと KDE Plasma の自由さを、ひとつの青空の下に。"
                    color: Qt.rgba(1, 1, 1, 0.92)
                    font.pixelSize: 15
                    lineHeight: 1.35
                    wrapMode: Text.WordWrap
                }

                Flow {
                    Layout.fillWidth: true
                    Layout.topMargin: 14
                    spacing: 8
                    Repeater {
                        model: ["CachyOS ベース", "KDE Plasma", "Arch Linux 互換", "pacman / AUR"]
                        GlassPanel {
                            required property string modelData
                            shadow: false
                            width: chip.implicitWidth + 28
                            height: 32
                            radius: 16
                            tintOpacity: 0.16
                            Text {
                                id: chip
                                anchors.centerIn: parent
                                text: modelData
                                color: "white"
                                font.pixelSize: 13
                            }
                        }
                    }
                }

                // ---- ライブ環境: インストール ----
                GlassPanel {
                    visible: page.backend.isLive
                    Layout.fillWidth: true
                    Layout.maximumWidth: 560
                    Layout.topMargin: 18
                    Layout.preferredHeight: 92
                    tintOpacity: 0.2

                    RowLayout {
                        anchors { fill: parent; leftMargin: 20; rightMargin: 16 }
                        spacing: 14
                        Rectangle {
                            Layout.preferredWidth: 46
                            Layout.preferredHeight: 46
                            radius: 15
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.rgba(0.55, 0.85, 1, 0.95) }
                                GradientStop { position: 1; color: Qt.rgba(0.15, 0.5, 0.95, 0.95) }
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.7)
                            Text {
                                anchors.centerIn: parent
                                text: "⤓"
                                color: "white"
                                font.pixelSize: 24
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: "ライブ環境で起動しています"
                                color: "white"
                                font.pixelSize: 15
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: page.backend.installerMessage !== ""
                                      ? page.backend.installerMessage
                                      : page.backend.installerAvailable
                                        ? "AirSkyOS をこのPCにインストールできます。"
                                        : "インストーラー(Calamares)が見つかりません。"
                                color: Qt.rgba(1, 1, 1, 0.88)
                                font.pixelSize: 12
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                            }
                        }
                        GlassButton {
                            text: page.backend.installerStarting ? "起動中…" : "インストール"
                            iconText: "⤓"
                            accent: true
                            implicitWidth: 148
                            enabled: page.backend.installerAvailable && !page.backend.installerStarting
                            onClicked: if (page.backend.launchInstaller()) page.Window.window.showMinimized()
                        }
                    }
                }

                Item { Layout.fillHeight: true }
            }

            // ---- システム情報 ----
            GlassPanel {
                Layout.preferredWidth: 340
                Layout.alignment: Qt.AlignVCenter
                Layout.preferredHeight: info.implicitHeight + 44

                ColumnLayout {
                    id: info
                    anchors { fill: parent; margins: 22 }
                    spacing: 12

                    Text {
                        text: "このコンピューター"
                        color: "white"
                        font.pixelSize: 16
                        font.weight: Font.DemiBold
                    }
                    Rectangle { Layout.fillWidth: true; height: 1; color: Qt.rgba(1, 1, 1, 0.3) }

                    Repeater {
                        model: [
                            ["OS", page.backend.osName],
                            ["デスクトップ", page.backend.desktop],
                            ["カーネル", page.backend.kernel],
                            ["CPU", page.backend.cpu],
                            ["メモリ", page.backend.memory]
                        ]
                        ColumnLayout {
                            required property var modelData
                            Layout.fillWidth: true
                            spacing: 2
                            Text {
                                text: modelData[0]
                                color: Qt.rgba(1, 1, 1, 0.7)
                                font.pixelSize: 12
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData[1]
                                color: "white"
                                font.pixelSize: 14
                                elide: Text.ElideRight
                            }
                        }
                    }
                }
            }
        }

        // ---- 特長カード ----
        RowLayout {
            Layout.fillWidth: true
            Layout.preferredHeight: 116
            spacing: 16

            Repeater {
                model: [
                    { icon: "⚡", title: "速さ", body: "CachyOS の最適化カーネルと\nx86-64-v3/v4 パッケージで軽快に。" },
                    { icon: "☁", title: "透明感", body: "背面が透けて見える\nガラス風のウィンドウ。" },
                    { icon: "⟳", title: "いつも最新", body: "ローリングリリースで\n新しいソフトをすぐに使えます。" }
                ]
                GlassPanel {
                    required property var modelData
                    Layout.fillWidth: true
                    Layout.fillHeight: true
                    hovered: hov.hovered

                    HoverHandler { id: hov }

                    RowLayout {
                        anchors { fill: parent; margins: 18 }
                        spacing: 14
                        Rectangle {
                            Layout.preferredWidth: 44
                            Layout.preferredHeight: 44
                            Layout.alignment: Qt.AlignTop
                            radius: 14
                            gradient: Gradient {
                                GradientStop { position: 0; color: Qt.rgba(1, 1, 1, 0.55) }
                                GradientStop { position: 1; color: Qt.rgba(1, 1, 1, 0.2) }
                            }
                            border.color: Qt.rgba(1, 1, 1, 0.6)
                            Text {
                                anchors.centerIn: parent
                                text: modelData.icon
                                color: "white"
                                font.pixelSize: 22
                            }
                        }
                        ColumnLayout {
                            Layout.fillWidth: true
                            Layout.alignment: Qt.AlignTop
                            spacing: 4
                            Text {
                                text: modelData.title
                                color: "white"
                                font.pixelSize: 16
                                font.weight: Font.DemiBold
                            }
                            Text {
                                Layout.fillWidth: true
                                text: modelData.body
                                color: Qt.rgba(1, 1, 1, 0.88)
                                font.pixelSize: 13
                                lineHeight: 1.25
                                wrapMode: Text.WordWrap
                            }
                        }
                    }
                }
            }
        }
    }
}
