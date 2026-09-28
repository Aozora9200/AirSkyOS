import QtQuick
import QtQuick.Window
import QtQuick.Effects

Window {
    id: win
    readonly property var backend: appBackend
    property int startPage: 0
    property int currentPage: Math.max(0, Math.min(startPage, pageCount - 1))
    // ライブ環境では1枚目(ようこそ+インストール)だけを表示し、ページ移動をさせない
    readonly property int pageCount: backend.isLive ? 1 : 3
    readonly property bool roundCorners: visibility !== Window.Maximized
                                         && visibility !== Window.FullScreen

    width: 1000
    height: 680
    minimumWidth: 860
    minimumHeight: 600
    visible: true
    title: "AirSkyOS へようこそ"
    color: "transparent"
    flags: Qt.Window | Qt.FramelessWindowHint

    Item {
        id: frame
        anchors.fill: parent
        layer.enabled: win.roundCorners
        layer.effect: MultiEffect {
            maskEnabled: true
            maskSource: frameMask
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }

        // ---------- ウィンドウ全体のガラス ----------
        // 背面のデスクトップ/ウィンドウは KWin のブラーでぼかされて透ける。
        // ここではその上に空色のティントと光沢だけを重ねる。
        GlassBase {
            anchors.fill: parent
            blurActive: win.backend.blurActive
        }

        // ---------- タイトルバー ----------
        Item {
            id: titleBar
            anchors { left: parent.left; right: parent.right; top: parent.top }
            height: 52

            DragHandler {
                target: null
                onActiveChanged: if (active) win.startSystemMove()
            }
            TapHandler {
                onDoubleTapped: win.visibility === Window.Maximized ? win.showNormal() : win.showMaximized()
            }

            Row {
                anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                spacing: 10
                Image {
                    source: "logo.svg"
                    sourceSize: Qt.size(24, 24)
                    anchors.verticalCenter: parent.verticalCenter
                }
                Text {
                    text: "AirSkyOS"
                    color: "white"
                    font.pixelSize: 14
                    font.weight: Font.DemiBold
                    anchors.verticalCenter: parent.verticalCenter
                }
            }

            Row {
                anchors { right: parent.right; rightMargin: 16; verticalCenter: parent.verticalCenter }
                spacing: 8
                WindowDot { glyph: "–"; onClicked: win.showMinimized() }
                WindowDot { glyph: "✕"; danger: true; onClicked: Qt.quit() }
            }
        }

        // ---------- ページ ----------
        Item {
            id: pagesView
            anchors {
                left: parent.left; right: parent.right
                top: titleBar.bottom; bottom: bottomBar.top
                leftMargin: 28; rightMargin: 28; bottomMargin: 16
            }
            clip: true

            WelcomePage {
                width: pagesView.width; height: pagesView.height
                backend: win.backend
                pageIndex: 0; current: win.currentPage
            }
            ThemePage {
                width: pagesView.width; height: pagesView.height
                backend: win.backend
                theme: appTheme
                pageIndex: 1; current: win.currentPage
            }
            AppsPage {
                width: pagesView.width; height: pagesView.height
                backend: win.backend
                pageIndex: 2; current: win.currentPage
            }
        }

        // ---------- 下部バー ----------
        GlassPanel {
            id: bottomBar
            anchors {
                left: parent.left; right: parent.right; bottom: parent.bottom
                leftMargin: 28; rightMargin: 28; bottomMargin: 22
            }
            height: 64
            radius: 32

            // ライブ環境では「起動時に表示」の代わりにインストールボタン
            GlassButton {
                visible: win.backend.isLive
                anchors { left: parent.left; leftMargin: 12; verticalCenter: parent.verticalCenter }
                text: win.backend.installerStarting ? "起動中…" : "AirSkyOS をインストール"
                iconText: "⤓"
                accent: true
                enabled: win.backend.installerAvailable && !win.backend.installerStarting
                onClicked: if (win.backend.launchInstaller()) win.showMinimized()
            }
            GlassSwitch {
                visible: !win.backend.isLive
                anchors { left: parent.left; leftMargin: 22; verticalCenter: parent.verticalCenter }
                text: "起動時に表示する"
                checked: win.backend.showOnStartup
                onToggled: (c) => win.backend.showOnStartup = c
            }

            Row {
                anchors.centerIn: parent
                spacing: 10
                visible: win.pageCount > 1
                Repeater {
                    model: win.pageCount
                    Rectangle {
                        required property int index
                        width: index === win.currentPage ? 26 : 9
                        height: 9
                        radius: 4.5
                        color: Qt.rgba(1, 1, 1, index === win.currentPage ? 0.95 : 0.45)
                        Behavior on width { NumberAnimation { duration: 300; easing.type: Easing.OutCubic } }
                        MouseArea {
                            anchors.fill: parent
                            anchors.margins: -6
                            cursorShape: Qt.PointingHandCursor
                            onClicked: win.currentPage = parent.index
                        }
                    }
                }
            }

            Row {
                anchors { right: parent.right; rightMargin: 12; verticalCenter: parent.verticalCenter }
                spacing: 10
                GlassButton {
                    text: "戻る"
                    visible: win.currentPage > 0
                    onClicked: win.currentPage--
                }
                GlassButton {
                    visible: !win.backend.isLive
                    text: win.currentPage < win.pageCount - 1 ? "次へ" : "はじめる"
                    accent: true
                    implicitWidth: 120
                    onClicked: {
                        if (win.currentPage < win.pageCount - 1)
                            win.currentPage++
                        else
                            Qt.quit()
                    }
                }
            }
        }
    }

    Item {
        id: frameMask
        anchors.fill: parent
        layer.enabled: true
        visible: false
        Rectangle { anchors.fill: parent; radius: 22; color: "black" }
    }

    // ウィンドウの細い縁
    Rectangle {
        anchors.fill: parent
        visible: win.roundCorners
        radius: 22
        color: "transparent"
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.35)
    }

    // キーボード操作
    Shortcut { sequence: "Right"; onActivated: if (win.currentPage < win.pageCount - 1) win.currentPage++ }
    Shortcut { sequence: "Left";  onActivated: if (win.currentPage > 0) win.currentPage-- }
    Shortcut { sequences: [StandardKey.Quit]; onActivated: Qt.quit() }
    Shortcut { sequence: "Escape"; onActivated: Qt.quit() }

    component WindowDot: Rectangle {
        id: dot
        property string glyph: ""
        property bool danger: false
        signal clicked()
        width: 30; height: 30; radius: 15
        color: dotMouse.containsMouse
               ? (danger ? Qt.rgba(1, 0.35, 0.4, 0.85) : Qt.rgba(1, 1, 1, 0.35))
               : Qt.rgba(1, 1, 1, 0.18)
        border.width: 1
        border.color: Qt.rgba(1, 1, 1, 0.45)
        Behavior on color { ColorAnimation { duration: 150 } }
        Text {
            anchors.centerIn: parent
            text: dot.glyph
            color: "white"
            font.pixelSize: 13
        }
        MouseArea {
            id: dotMouse
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: dot.clicked()
        }
    }
}
