"""AirSkyOS のグローバルテーマ(ClearSky / ClearSky Dark)を適用する。

airskyos-session-defaults(airskyos-release パッケージ)と同じ方法で適用する:
  デザイン    plasma-apply-lookandfeel --apply <ID>
              配色・Plasma スタイル・ウィンドウ装飾・カーソル・アイコン・スプラッシュ
              + Kvantum テーマ(ユーザー設定にしか書けないのでここで設定)
  レイアウト  plasmashell の D-Bus loadLookAndFeelDefaultLayout(<ID>)
              パネル・ウィジェット・壁紙(テーマのレイアウト JS)だけ
  デフォルト  plasma-apply-lookandfeel --apply <ID> --resetLayout
              上の両方
"""
import os
import re
import shutil
import subprocess
from datetime import datetime

from PySide6.QtCore import QObject, Property, Signal, Slot, QProcess, QUrl

LNF_DIR = os.environ.get("AIRSKYOS_LNF_DIR", "/usr/share/plasma/look-and-feel")
BRANDING_CONF = "/etc/airskyos/branding.conf"
KVANTUM_THEME = "aozora-glass-kde"

THEMES = [
    {"id": "ClearSky", "label": "ライト"},
    {"id": "ClearSky Dark", "label": "ダーク"},
]

MODE_LABELS = {
    "default": "デフォルトに戻しました",
    "design": "デザインを適用しました",
    "layout": "レイアウトを適用しました",
}


def _config_home():
    return os.environ.get("XDG_CONFIG_HOME") or os.path.expanduser("~/.config")


def _state_dir():
    base = os.environ.get("XDG_STATE_HOME") or os.path.expanduser("~/.local/state")
    return os.path.join(base, "airskyos")


def _branding_default():
    try:
        with open(BRANDING_CONF, encoding="utf-8") as f:
            for line in f:
                m = re.match(r'\s*LOOKANDFEEL\s*=\s*"?([^"#\n]+?)"?\s*(#.*)?$', line)
                if m:
                    return m.group(1).strip()
    except OSError:
        pass
    return "ClearSky"


def _read_current_lnf():
    exe = shutil.which("kreadconfig6") or shutil.which("kreadconfig5")
    if not exe:
        return ""
    try:
        return subprocess.run(
            [exe, "--file", "kdeglobals", "--group", "KDE", "--key", "LookAndFeelPackage"],
            capture_output=True, text=True, timeout=5).stdout.strip()
    except (OSError, subprocess.SubprocessError):
        return ""


def _set_kvantum_theme():
    """airskyos-session-defaults と同じく Kvantum のテーマを AirSkyOS のものにする。
    (ダーク側は widgetStyle=kvantum-dark により自動で Dark 版が使われる)"""
    path = os.path.join(_config_home(), "Kvantum", "kvantum.kvconfig")
    os.makedirs(os.path.dirname(path), exist_ok=True)
    try:
        with open(path, encoding="utf-8") as f:
            text = f.read()
    except OSError:
        text = ""
    if re.search(r"^theme=", text, re.M):
        text = re.sub(r"^theme=.*$", f"theme={KVANTUM_THEME}", text, flags=re.M)
    elif re.search(r"^\[General\]", text, re.M):
        text = re.sub(r"^\[General\]\s*$", f"[General]\ntheme={KVANTUM_THEME}", text,
                      count=1, flags=re.M)
    else:
        text = text + ("" if text.endswith("\n") or not text else "\n") + \
            f"[General]\ntheme={KVANTUM_THEME}\n"
    with open(path, "w", encoding="utf-8") as f:
        f.write(text)


def _stamp_layout():
    # airskyos-session-defaults が「初回レイアウト適用済み」と判断できるように
    d = _state_dir()
    os.makedirs(d, exist_ok=True)
    with open(os.path.join(d, "layout-applied"), "w", encoding="utf-8") as f:
        f.write(datetime.now().astimezone().isoformat(timespec="seconds") + "\n")


class ThemeManager(QObject):
    busyChanged = Signal()
    statusChanged = Signal()
    currentChanged = Signal()

    def __init__(self, parent=None):
        super().__init__(parent)
        self._busy = False
        self._status = ""
        self._status_ok = True
        self._proc = None
        self._mode = ""
        self._target = ""
        self._current = _read_current_lnf()

    # ---------- プロパティ ----------
    @Property("QVariantList", constant=True)
    def themes(self):
        out = []
        for t in THEMES:
            root = os.path.join(LNF_DIR, t["id"])
            preview = os.path.join(root, "contents", "previews", "preview.png")
            out.append({
                "id": t["id"],
                "label": t["label"],
                "installed": os.path.isdir(root),
                "preview": QUrl.fromLocalFile(preview).toString() if os.path.isfile(preview) else "",
            })
        return out

    @Property(str, constant=True)
    def defaultTheme(self):
        return _branding_default()

    def _get_current(self):
        return self._current

    current = Property(str, _get_current, notify=currentChanged)

    def _get_busy(self):
        return self._busy

    busy = Property(bool, _get_busy, notify=busyChanged)

    def _get_status(self):
        return self._status

    status = Property(str, _get_status, notify=statusChanged)

    def _get_status_ok(self):
        return self._status_ok

    statusOk = Property(bool, _get_status_ok, notify=statusChanged)

    @Property(bool, constant=True)
    def available(self):
        return shutil.which("plasma-apply-lookandfeel") is not None

    # ---------- 適用 ----------
    def _set_status(self, text, ok=True):
        self._status = text
        self._status_ok = ok
        self.statusChanged.emit()

    def _set_busy(self, v):
        self._busy = v
        self.busyChanged.emit()

    @Slot(str, str)
    def apply(self, mode, lnf):
        """mode: "default" | "design" | "layout" """
        if self._busy or mode not in MODE_LABELS:
            return
        if not os.path.isdir(os.path.join(LNF_DIR, lnf)):
            self._set_status(f"「{lnf}」がインストールされていません(airskyos-kde-theme)", False)
            return

        if mode == "layout":
            prog = shutil.which("dbus-send") or "dbus-send"
            args = ["--session", "--print-reply", "--dest=org.kde.plasmashell",
                    "--type=method_call", "/PlasmaShell",
                    "org.kde.PlasmaShell.loadLookAndFeelDefaultLayout", f"string:{lnf}"]
        else:
            prog = shutil.which("plasma-apply-lookandfeel")
            if not prog:
                self._set_status("plasma-apply-lookandfeel が見つかりません", False)
                return
            args = ["--apply", lnf]
            if mode == "default":
                args.append("--resetLayout")

        self._mode, self._target = mode, lnf
        self._set_status("適用しています…")
        self._set_busy(True)
        self._proc = QProcess(self)
        self._proc.setProcessChannelMode(QProcess.ProcessChannelMode.MergedChannels)
        self._proc.finished.connect(self._on_finished)
        self._proc.errorOccurred.connect(self._on_error)
        self._proc.start(prog, args)

    def _on_error(self, _err):
        if not self._busy:
            return
        self._set_busy(False)
        self._set_status("コマンドを実行できませんでした", False)

    def _on_finished(self, code, _status):
        if not self._busy:
            return
        output = bytes(self._proc.readAll()).decode(errors="replace").strip()
        ok = code == 0
        if ok:
            try:
                if self._mode in ("default", "design"):
                    _set_kvantum_theme()
                if self._mode in ("default", "layout"):
                    _stamp_layout()
            except OSError as e:
                output = str(e)
            subprocess.run(["dbus-send", "--session", "--type=signal", "/KWin",
                            "org.kde.KWin.reloadConfig"],
                           capture_output=True, timeout=5)
            msg = f"{MODE_LABELS[self._mode]}({self._target})"
            if self._mode in ("default", "design"):
                msg += "。一部のアプリは再起動すると反映されます"
            self._set_status(msg, True)
        else:
            last = output.splitlines()[-1] if output else f"終了コード {code}"
            self._set_status(f"失敗しました: {last}", False)
        self._current = _read_current_lnf()
        self.currentChanged.emit()
        self._set_busy(False)
