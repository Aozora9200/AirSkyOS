/* AirSkyOS installer slideshow */
import QtQuick 2.15
import calamares.slideshow 1.0

Presentation {
    id: presentation

    Timer {
        interval: 8000
        running: presentation.activatedInCalamares
        repeat: true
        onTriggered: presentation.goToNextSlide()
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/ClearSky/contents/images/5120x2880.png"
            fillMode: Image.PreserveAspectCrop
        }
        Text {
            anchors.centerIn: parent
            text: "AirSkyOS をインストールしています…"
            color: "white"
            font.pixelSize: 28
            style: Text.Outline
            styleColor: "#40000000"
        }
    }

    Slide {
        Image {
            anchors.fill: parent
            source: "file:///usr/share/wallpapers/ClearSky/contents/images_dark/5120x2880.png"
            fillMode: Image.PreserveAspectCrop
        }
        Text {
            anchors.centerIn: parent
            width: parent.width * 0.8
            horizontalAlignment: Text.AlignHCenter
            wrapMode: Text.WordWrap
            text: "ClearSky / ClearSky Dark は\nシステム設定 → 外観 からいつでも切り替えられます"
            color: "white"
            font.pixelSize: 22
        }
    }

    function onActivate() { presentation.currentSlide = 0 }
    function onLeave() { }
}
