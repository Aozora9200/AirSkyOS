"""おすすめアプリ一覧。

pkg はpacmanのパッケージ名、icon はアイコンテーマ(Breeze等)のアイコン名。
項目を増減したいときはこのリストを編集するだけでOK。
"""

RECOMMENDED_APPS = [
    {"pkg": "firefox",          "name": "Firefox",        "desc": "Webブラウザ",             "icon": "firefox"},
    {"pkg": "chromium",         "name": "Chromium",       "desc": "Webブラウザ",             "icon": "chromium"},
    {"pkg": "thunderbird",      "name": "Thunderbird",    "desc": "メールクライアント",       "icon": "thunderbird"},
    {"pkg": "libreoffice-fresh", "name": "LibreOffice",   "desc": "オフィススイート",         "icon": "libreoffice-startcenter"},
    {"pkg": "fcitx5-im fcitx5-mozc", "name": "Mozc",      "desc": "日本語入力 (fcitx5)",      "icon": "fcitx"},
    {"pkg": "vlc",              "name": "VLC",            "desc": "メディアプレーヤー",       "icon": "vlc"},
    {"pkg": "gimp",             "name": "GIMP",           "desc": "画像編集",                 "icon": "gimp"},
    {"pkg": "krita",            "name": "Krita",          "desc": "デジタルペイント",         "icon": "krita"},
    {"pkg": "kdenlive",         "name": "Kdenlive",       "desc": "動画編集",                 "icon": "kdenlive"},
    {"pkg": "obs-studio",       "name": "OBS Studio",     "desc": "録画・配信",               "icon": "com.obsproject.Studio"},
    {"pkg": "steam",            "name": "Steam",          "desc": "ゲームプラットフォーム",   "icon": "steam"},
    {"pkg": "discord",          "name": "Discord",        "desc": "チャット・通話",           "icon": "discord"},
    {"pkg": "telegram-desktop", "name": "Telegram",       "desc": "メッセンジャー",           "icon": "telegram"},
    {"pkg": "code",             "name": "Code - OSS",     "desc": "コードエディタ",           "icon": "com.visualstudio.code.oss"},
    {"pkg": "flatpak",          "name": "Flatpak",        "desc": "Flathubのアプリに対応",    "icon": "flatpak-discover"},
]
