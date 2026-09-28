"""KWin のブラー(背面ぼかし)をウィンドウに適用する。

KDE Frameworks の KWindowEffects(libKF6WindowSystem)を ctypes で直接呼び出す。
X11 / Wayland のどちらでも KWindowSystem 側が適切なプロトコルで KWin に伝えてくれる。
PySide6 と KF6 が同じシステムの Qt6 にリンクされている(Arch の pyside6 パッケージ)ことが前提。
"""
import ctypes
import ctypes.util

import shiboken6
from PySide6.QtCore import QRectF
from PySide6.QtGui import QPainterPath, QRegion

# namespace KWindowEffects の関数(Itanium C++ ABI のマングル名)
_SYM_ENABLE_BLUR = "_ZN14KWindowEffects16enableBlurBehindEP7QWindowbRK7QRegion"
_SYM_ENABLE_CONTRAST = "_ZN14KWindowEffects24enableBackgroundContrastEP7QWindowbdddRK7QRegion"
_SYM_IS_AVAILABLE = "_ZN14KWindowEffects17isEffectAvailableENS_6EffectE"
_EFFECT_BLUR_BEHIND = 7


def _load():
    for name in ("libKF6WindowSystem.so.6", ctypes.util.find_library("KF6WindowSystem")):
        if not name:
            continue
        try:
            return ctypes.CDLL(name)
        except OSError:
            continue
    return None


_lib = _load()


def _fn(sym, restype, argtypes):
    if _lib is None:
        return None
    try:
        f = getattr(_lib, sym)
    except AttributeError:
        return None
    f.restype = restype
    f.argtypes = argtypes
    return f


_enable_blur = _fn(_SYM_ENABLE_BLUR, None,
                   [ctypes.c_void_p, ctypes.c_bool, ctypes.c_void_p])
_enable_contrast = _fn(_SYM_ENABLE_CONTRAST, None,
                       [ctypes.c_void_p, ctypes.c_bool, ctypes.c_double,
                        ctypes.c_double, ctypes.c_double, ctypes.c_void_p])
_is_available = _fn(_SYM_IS_AVAILABLE, ctypes.c_bool, [ctypes.c_int])


def is_supported():
    """KWindowSystem が読み込めて、KWin のブラーが今有効か。"""
    if _enable_blur is None:
        return False
    if _is_available is None:
        return True
    try:
        return bool(_is_available(_EFFECT_BLUR_BEHIND))
    except Exception:
        return False


def rounded_region(width, height, radius):
    path = QPainterPath()
    if radius > 0:
        path.addRoundedRect(QRectF(0, 0, width, height), radius, radius)
    else:
        path.addRect(QRectF(0, 0, width, height))
    return QRegion(path.toFillPolygon().toPolygon())


def apply(window, radius=0, enable=True):
    """window(QWindow)の背面をぼかす。radius>0 なら角丸の領域だけ。"""
    if _enable_blur is None:
        return False
    region = rounded_region(window.width(), window.height(), radius)
    win_ptr = shiboken6.getCppPointer(window)[0]
    reg_ptr = shiboken6.getCppPointer(region)[0]
    _enable_blur(win_ptr, enable, reg_ptr)
    if _enable_contrast is not None:
        # Plasma のパネルと同じ「背景コントラスト」で、明るい壁紙の上でも文字を読みやすく
        _enable_contrast(win_ptr, enable, 1.0, 1.0, 1.7, reg_ptr)
    return True
