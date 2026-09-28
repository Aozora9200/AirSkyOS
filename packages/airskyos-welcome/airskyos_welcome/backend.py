import os
import platform
import shlex
import shutil
import subprocess

from PySide6.QtCore import (Qt, QObject, Property, Signal, Slot, QSettings,
                            QProcess, QUrl, QSize, QTimer)
from PySide6.QtGui import QDesktopServices, QIcon, QPixmap
from PySide6.QtQuick import QQuickImageProvider

from .apps import RECOMMENDED_APPS
from . import installer

# (コマンド, 引数) — 最後に bash -c "<script>" が付く。終了待ちはスクリプト側のreadで行う
TERMINALS = [
    ("konsole", ["--separate", "-e"]),
    ("kitty", []),
    ("alacritty", ["-e"]),
    ("foot", []),
    ("xterm", ["-e"]),
]


def _read_os_release():
    info = {}
    for path in ("/etc/os-release", "/usr/lib/os-release"):
        try:
            with open(path, encoding="utf-8") as f:
                for line in f:
                    if "=" in line:
                        k, v = line.rstrip("\n").split("=", 1)
                        info[k] = v.strip('"')
            break
        except OSError:
            continue
    return info


def _cpu_name():
    try:
        with open("/proc/cpuinfo", encoding="utf-8") as f:
            for line in f:
                if line.startswith("model name"):
                    return line.split(":", 1)[1].strip()
    except OSError:
        pass
    return platform.processor() or "不明"


def _memory_gib():
    try:
        with open("/proc/meminfo", encoding="utf-8") as f:
            for line in f:
                if line.startswith("MemTotal"):
                    kib = int(line.split()[1])
                    return f"{kib / 1024 / 1024:.1f} GiB"
    except (OSError, ValueError):
        pass
    return "不明"


class IconProvider(QQuickImageProvider):
    """image://icon/<name> でアイコンテーマのアイコンをQMLへ渡す。"""

    def __init__(self):
        super().__init__(QQuickImageProvider.ImageType.Pixmap)

    def requestPixmap(self, icon_id, size, requested_size):
        s = requested_size.width() if requested_size.width() > 0 else 64
        icon = QIcon.fromTheme(icon_id)
        if icon.isNull():
            icon = QIcon.fromTheme("package-x-generic",
                                   QIcon.fromTheme("application-x-executable"))
        pm = icon.pixmap(QSize(s, s))
        if pm.isNull():
            pm = QPixmap(s, s)
            pm.fill(Qt.GlobalColor.transparent)
        size.setWidth(pm.width())
        size.setHeight(pm.height())
        return pm


class Backend(QObject):
    showOnStartupChanged = Signal()
    installedChanged = Signal()
    busyChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        # ~/.config/AirSkyOS/welcome.conf
        self._settings = QSettings("AirSkyOS", "welcome")
        self._installed = set()
        self._busy = False
        self._proc = None
        self._os = _read_os_release()
        self._blur_active = True
        self._live = installer.detect_live()
        self._installer_starting = False
        self._installer_message = ""
        self.refreshInstalled()

    # ---------- 起動時に表示 ----------
    def _get_show(self):
        return self._settings.value("showOnStartup", True, type=bool)

    def _set_show(self, value):
        if value == self._get_show():
            return
        self._settings.setValue("showOnStartup", bool(value))
        self._settings.sync()
        self.showOnStartupChanged.emit()

    showOnStartup = Property(bool, _get_show, _set_show, notify=showOnStartupChanged)

    # ---------- システム情報 ----------
    @Property(str, constant=True)
    def osName(self):
        return self._os.get("PRETTY_NAME") or self._os.get("NAME") or "AirSkyOS"

    @Property(str, constant=True)
    def kernel(self):
        return platform.release()

    @Property(str, constant=True)
    def cpu(self):
        return _cpu_name()

    @Property(str, constant=True)
    def memory(self):
        return _memory_gib()

    @Property(str, constant=True)
    def desktop(self):
        de = os.environ.get("XDG_CURRENT_DESKTOP", "KDE")
        ver = os.environ.get("KDE_SESSION_VERSION")
        session = os.environ.get("XDG_SESSION_TYPE", "")
        name = "KDE Plasma" if "KDE" in de.upper() else de
        if ver:
            name += f" {ver}"
        if session:
            name += f" ({session.capitalize()})"
        return name

    @Property(str, constant=True)
    def userName(self):
        return os.environ.get("USER", "")

    # KWin の背面ブラーが効いているか(Falseならガラスを不透明寄りにする)
    blurActiveChanged = Signal()

    def _get_blur_active(self):
        return self._blur_active

    def setBlurActive(self, value):
        if value != self._blur_active:
            self._blur_active = value
            self.blurActiveChanged.emit()

    blurActive = Property(bool, _get_blur_active, notify=blurActiveChanged)

    @Property(bool, constant=True)
    def hasRateMirrors(self):
        return shutil.which("cachyos-rate-mirrors") is not None

    # ---------- アプリ ----------
    @Property("QVariantList", constant=True)
    def apps(self):
        return RECOMMENDED_APPS

    def _get_installed(self):
        return sorted(self._installed)

    installed = Property("QVariantList", _get_installed, notify=installedChanged)

    @Slot()
    def refreshInstalled(self):
        try:
            out = subprocess.run(["pacman", "-Qq"], capture_output=True,
                                 text=True, timeout=10).stdout
            self._installed = set(out.split())
        except (OSError, subprocess.SubprocessError):
            self._installed = set()
        self.installedChanged.emit()

    @Slot(str, result=bool)
    def hasIcon(self, name):
        return QIcon.hasThemeIcon(name)

    @Slot(str, result=bool)
    def isInstalled(self, pkg):
        parts = pkg.split()
        return bool(parts) and all(p in self._installed for p in parts)

    def _get_busy(self):
        return self._busy

    busy = Property(bool, _get_busy, notify=busyChanged)

    # ---------- コマンド実行 ----------
    def _run_in_terminal(self, title, command):
        if self._busy:
            return
        script = (
            f"echo -e '\\e[1;36m== {title} ==\\e[0m'; echo; "
            f"{command}; echo; "
            "read -rp '完了しました。Enterキーで閉じます…' _"
        )
        for term, args in TERMINALS:
            exe = shutil.which(term)
            if not exe:
                continue
            self._proc = QProcess(self)
            self._proc.finished.connect(self._on_finished)
            self._proc.errorOccurred.connect(lambda *_: self._on_finished())
            self._proc.start(exe, args + ["bash", "-c", script])
            self._busy = True
            self.busyChanged.emit()
            return

    def _on_finished(self, *_):
        if not self._busy:
            return
        self._busy = False
        self.busyChanged.emit()
        self.refreshInstalled()

    @Slot()
    def updateSystem(self):
        self._run_in_terminal("システムを更新しています", "sudo pacman -Syu")

    @Slot()
    def rateMirrors(self):
        self._run_in_terminal("ミラーを最適化しています", "sudo cachyos-rate-mirrors")

    @Slot("QVariantList")
    def installPackages(self, pkgs):
        names = []
        for p in pkgs:
            names.extend(str(p).split())
        if not names:
            return
        cmd = "sudo pacman -S --needed " + " ".join(shlex.quote(n) for n in names)
        self._run_in_terminal("アプリをインストールしています", cmd)

    # ---------- ライブ環境 / インストーラー ----------
    installerChanged = Signal()

    @Property(bool, constant=True)
    def isLive(self):
        return self._live

    @Property(bool, constant=True)
    def installerAvailable(self):
        return installer.calamares_available()

    def _get_installer_starting(self):
        return self._installer_starting

    installerStarting = Property(bool, _get_installer_starting, notify=installerChanged)

    def _get_installer_message(self):
        return self._installer_message

    installerMessage = Property(str, _get_installer_message, notify=installerChanged)

    def _set_installer(self, starting, message):
        self._installer_starting = starting
        self._installer_message = message
        self.installerChanged.emit()

    @Slot(result=bool)
    def launchInstaller(self):
        """Calamares を起動する。起動できたら True(QML側でウィンドウを最小化する)"""
        if self._installer_starting:
            return False
        cmd = installer.installer_command()
        if not cmd:
            self._set_installer(False, "Calamares を起動する方法が見つかりません(calamares / sudo / pkexec)")
            return False
        # 起動前にライブラリ不足をチェック(起動に失敗してもエラーが見えないため)
        if not os.environ.get("AIRSKYOS_INSTALLER_CMD"):
            missing = installer.missing_libraries()
            if missing:
                self._set_installer(False, "Calamares を起動できません。ライブラリがありません: "
                                    + ", ".join(missing))
                return False
        # ようこそアプリを閉じてもインストーラーが終了しないよう、切り離して起動する
        ok, _pid = QProcess.startDetached(cmd[0], cmd[1:])
        if not ok:
            self._set_installer(False, "インストーラーを起動できませんでした: " + " ".join(cmd))
            return False
        self._set_installer(True, "インストーラーを起動しています…")
        # 連打で二重に起動しないよう、少しの間ボタンを押せなくする
        QTimer.singleShot(8000, lambda: self._set_installer(False, ""))
        return True

    @Slot(str)
    def openUrl(self, url):
        QDesktopServices.openUrl(QUrl(url))
