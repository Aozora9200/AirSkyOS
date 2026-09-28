/*
    SPDX-FileCopyrightText: 2014 Marco Martin <mart@kde.org>

    SPDX-License-Identifier: GPL-2.0-or-later
*/

import QtQuick
import org.kde.kirigami as Kirigami

Rectangle {
    id: root
    
    // 1. 初期状態の不透明度を 0 に設定
    opacity: 0

    Image {
        anchors.fill: parent
        source: "images/clearsky.png"
        fillMode: Image.PreserveAspectCrop
    }

    property int stage

    onStageChanged: {
        if (stage == 2) {
            introAnimation.running = true;
        } else if (stage == 5) {
            // ステージ5で終了時のアニメーション
            introAnimation.target = busyIndicator;
            introAnimation.from = 1;
            introAnimation.to = 0;
            introAnimation.running = true;
        }
    }

    Item {
        id: content
        anchors.fill: parent
        // root の opacity が 0 なので、こちらは 1 のままで連動してフェードインします
        opacity: 1

        // TODO: port to PlasmaComponents3.BusyIndicator
        Row {
            spacing: Kirigami.Units.largeSpacing
            anchors {
                bottom: parent.bottom
                right: parent.right
                margins: Kirigami.Units.gridUnit
            }
            Text {
                color: "#eff0f1"
                anchors.verticalCenter: parent.verticalCenter
                text: i18ndc("plasma_lookandfeel_org.kde.lookandfeel", "This is the first text the user sees while starting in the splash screen, should be translated as something short, is a form that can be seen on a product. Plasma is the project name so shouldn't be translated.", "Plasma made by KDE")
                Accessible.name: text
                Accessible.role: Accessible.StaticText
            }
        }
    }

    // 2. アニメーションの対象を root に変更
    OpacityAnimator {
        id: introAnimation
        running: false
        target: root                // content から root に変更
        from: 0
        to: 1
        duration: Kirigami.Units.veryLongDuration * 2
        easing.type: Easing.InOutQuad
    }
}
