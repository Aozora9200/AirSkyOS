"""AirSkyOS ようこそアプリ

  airskyos-welcome              通常起動
  airskyos-welcome --autostart  ログイン時の自動起動(「起動時に表示」がOFFなら何もせず終了)
"""
import argparse
import os
import sys

from PySide6.QtCore import QSettings, QUrl
from PySide6.QtGui import QGuiApplication, QIcon
from PySide6.QtQml import QQmlApplicationEngine
from PySide6.QtQuickControls2 import QQuickStyle

from . import blur
from .backend import Backend, IconProvider
from .theme import ThemeManager

HERE = os.path.dirname(os.path.abspath(__file__))


CORNER_RADIUS = 22  # Main.qml の角丸と合わせる


def setup_blur(win, backend, disabled=False):
    """ウィンドウの背面(デスクトップや他のウィンドウ)を KWin にぼかしてもらう。"""
    if disabled or not blur.is_supported():
        backend.setBlurActive(False)
        return

    def reapply(*_):
        maximized = win.visibility() in (win.Visibility.Maximized, win.Visibility.FullScreen)
        ok = blur.apply(win, 0 if maximized else CORNER_RADIUS)
        backend.setBlurActive(ok)

    win.widthChanged.connect(reapply)
    win.heightChanged.connect(reapply)
    win.visibilityChanged.connect(reapply)
    reapply()


def main():
    parser = argparse.ArgumentParser(prog="airskyos-welcome")
    parser.add_argument("--autostart", action="store_true",
                        help="ログイン時の自動起動として実行する")
    parser.add_argument("--screenshot", metavar="PNG", help=argparse.SUPPRESS)
    parser.add_argument("--no-blur", action="store_true",
                        help="KWinのブラーを使わない(不透明寄りの表示)")
    parser.add_argument("--page", type=int, default=0, help=argparse.SUPPRESS)
    args, qt_args = parser.parse_known_args()

    if args.autostart:
        s = QSettings("AirSkyOS", "welcome")
        if not s.value("showOnStartup", True, type=bool):
            return 0

    QQuickStyle.setStyle("Basic")
    app = QGuiApplication([sys.argv[0]] + qt_args)
    app.setApplicationName("airskyos-welcome")
    app.setApplicationDisplayName("AirSkyOS へようこそ")
    app.setOrganizationName("AirSkyOS")
    app.setDesktopFileName("airskyos-welcome")
    app.setWindowIcon(QIcon.fromTheme("airskyos-welcome",
                                      QIcon(os.path.join(HERE, "qml", "logo.svg"))))

    backend = Backend()
    engine = QQmlApplicationEngine()
    engine.addImageProvider("icon", IconProvider())
    theme = ThemeManager()
    engine.rootContext().setContextProperty("appBackend", backend)
    engine.rootContext().setContextProperty("appTheme", theme)
    engine.setInitialProperties({"startPage": args.page})
    engine.load(QUrl.fromLocalFile(os.path.join(HERE, "qml", "Main.qml")))
    if not engine.rootObjects():
        return 1
    win = engine.rootObjects()[0]
    setup_blur(win, backend, disabled=args.no_blur)

    if args.screenshot:
        from PySide6.QtCore import QTimer

        def grab():
            win.grabWindow().save(args.screenshot)
            app.quit()
        QTimer.singleShot(2500, grab)

    ret = app.exec()
    del engine  # バックエンドより先にQMLを破棄(終了時の警告防止)
    return ret


if __name__ == "__main__":
    sys.exit(main())
