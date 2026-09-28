"""ライブ環境(LiveCD / LiveUSB)の検知と Calamares インストーラーの起動。

検知(どれか1つでも当てはまればライブ環境):
  - カーネルコマンドラインに archiso の引数がある(archisobasedir= / archisolabel= など)
    CachyOS / AirSkyOS の ISO は archiso で作られている
  - /run/archiso がある(archiso がブートメディアをマウントする場所)
  - / が airootfs(archiso のルート)
  - 環境変数 AIRSKYOS_LIVE=1(テスト用。0 なら常に「ライブではない」)

起動方法(上から順に使えるものを使う):
  - 環境変数 AIRSKYOS_INSTALLER_CMD(自分のコマンドに差し替えたいとき)
  - calamares_polkit などディストリ側のラッパー
  - sudo -n -E calamares(ライブユーザーはパスワード無し sudo のことが多い。
    -E で WAYLAND_DISPLAY などを引き継ぐので Wayland でも表示できる)
  - pkexec calamares(Calamares 同梱の polkit ポリシーを使う)
"""
import os
import shlex
import shutil
import subprocess

ARCHISO_CMDLINE_KEYS = ("archisobasedir=", "archisolabel=", "archisosearchuuid=",
                        "archisodevice=", "archiso_")
WRAPPERS = ("calamares_polkit", "calamares-launcher", "airskyos-installer")


def _cmdline():
    try:
        with open("/proc/cmdline", encoding="utf-8") as f:
            return f.read()
    except OSError:
        return ""


def _root_is_airootfs():
    try:
        with open("/proc/mounts", encoding="utf-8") as f:
            for line in f:
                parts = line.split()
                if len(parts) >= 3 and parts[1] == "/":
                    return parts[0] == "airootfs" or "airootfs" in line
    except OSError:
        pass
    return False


def detect_live():
    env = os.environ.get("AIRSKYOS_LIVE")
    if env is not None:
        return env.strip() not in ("", "0", "false", "no")
    cmd = _cmdline()
    if any(k in cmd for k in ARCHISO_CMDLINE_KEYS):
        return True
    if os.path.isdir("/run/archiso"):
        return True
    return _root_is_airootfs()


def calamares_available():
    return bool(os.environ.get("AIRSKYOS_INSTALLER_CMD")) or \
        shutil.which("calamares") is not None or \
        any(shutil.which(w) for w in WRAPPERS)


def _sudo_nopasswd():
    if not shutil.which("sudo"):
        return False
    try:
        return subprocess.run(["sudo", "-n", "true"], capture_output=True,
                              timeout=5).returncode == 0
    except (OSError, subprocess.SubprocessError):
        return False


def installer_command():
    """実行するコマンド(リスト)。見つからなければ None。"""
    custom = os.environ.get("AIRSKYOS_INSTALLER_CMD")
    if custom:
        return shlex.split(custom)
    for w in WRAPPERS:
        exe = shutil.which(w)
        if exe:
            return [exe]
    cal = shutil.which("calamares")
    if not cal:
        return None
    if os.geteuid() == 0:
        return [cal]
    if _sudo_nopasswd():
        return ["sudo", "-n", "-E", cal]
    if shutil.which("pkexec"):
        return ["pkexec", cal]
    return None


def missing_libraries():
    """calamares 本体が読み込めない共有ライブラリ(ldd で "not found")の一覧。"""
    cal = shutil.which("calamares")
    if not cal or not shutil.which("ldd"):
        return []
    try:
        out = subprocess.run(["ldd", cal], capture_output=True, text=True, timeout=10).stdout
    except (OSError, subprocess.SubprocessError):
        return []
    return [line.split("=>")[0].strip() for line in out.splitlines() if "not found" in line]
