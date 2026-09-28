# AirSkyOS NOTICE

AirSkyOS は [CachyOS](https://cachyos.org/)(Arch Linux ベース)と KDE Plasma 6 の上に、以下の作品を組み合わせて作られています。
各作品の著作権は、それぞれの作者に帰属します。ライセンスの全文は [`LICENSES/`](LICENSES/) と、各フォルダーの `LICENSE` / `NOTICE` にあります。

インストール後は `/usr/share/doc/airskyos/NOTICE.md` から参照できます。

---

## 1. Aozora が作成したもの

| 対象 | リポジトリ内の場所 | ライセンス |
|---|---|---|
| パッケージ (PKGBUILD)、スクリプト、pacman フック、設定ファイル (`/etc/xdg`、fontconfig ほか) | `packages/airskyos-branding/`、`packages/airskyos-kde-theme/` | GPL-3.0-or-later |
| ISO 作成キット (インストーラーの AirSkyOS 化を含む) | `iso-kit/` | GPL-3.0-or-later |
| ようこそアプリ airskyos-welcome | `packages/airskyos-welcome/` | MIT (ロゴを除く) |
| グローバルテーマ ClearSky / ClearSky Dark | `theme/ClearSky/`、`theme/ClearSky Dark/` | GPL-2.0-or-later ※1 |
| Konsole プロファイル Galanos / 配色 ClearSky | `theme/Konsole/` | GPL-3.0-or-later |
| 壁紙 ClearSky、Limine 起動画面 (壁紙から作成) | `theme/wallpapers/ClearSky/`、`packages/airskyos-branding/assets/limine/` | CC-BY-SA-4.0 |
| AirSkyOS ロゴ、ランチャーアイコン (`aozora.png` / `aozora1.png`)、ようこそアプリのロゴ | `packages/airskyos-branding/assets/`、`packages/airskyos-welcome/airskyos_welcome/qml/logo.svg` | All rights reserved ([条件](LICENSES/LicenseRef-AirSkyOS-Logo.txt)) ※2 |
| ターミナルのロゴ (fastfetch 用。FIGlet の "standard" フォントで生成) | `packages/airskyos-branding/files/fastfetch/` | GPL-3.0-or-later |

※1 KDE Breeze の Look-and-Feel (GPL-2.0-or-later) を元にしているため、同じライセンスとしています。
※2 AirSkyOS の一部として改変せずに再配布することはできます。派生ディストリビューションでは独自のロゴに置き換えてください。

## 2. 他の作者の作品を改変して同梱しているもの

| コンポーネント | 作者 | ライセンス | 元の作品 | AirSkyOS での変更 | リポジトリ内の場所 |
|---|---|---|---|---|---|
| KWin エフェクト Aozora Glass | Lester Cordero Murillo (Acrylic Glass エフェクト)。元は KWin blur effect (Fredrik Höglund, Philipp Knechtges, Alex Nemeth ほか) | GPL-3.0 | [macos-tahoe-liquid-kde](https://github.com/lestercorderomurillo/macos-tahoe-liquid-kde) / [KWin](https://invent.kde.org/plasma/kwin) | 名称変更、ウィンドウの角を丸く切り抜く処理を追加 (差分: `AIRSKYOS-CHANGES.patch`) | `packages/airskyos-branding/assets/acrylic-glass/` |
| Kvantum テーマ aozora-glass-kde | Lester Cordero Murillo | GPL-3.0 | [macos-tahoe-liquid-kde](https://github.com/lestercorderomurillo/macos-tahoe-liquid-kde) | 名称変更、説明文の変更 | `theme/kvantum/aozora-glass-kde/` |
| Plasma スタイル Galanos-Light / Galanos-Dark (6.2.0) | Lester Cordero Murillo | GPL-3.0 | [macos-tahoe-liquid-kde](https://github.com/lestercorderomurillo/macos-tahoe-liquid-kde) | 説明文とリンクの変更 (ビルド時)。このバージョンは配布元に残っていないため、ファイルごと同梱 | `theme/Plasma Style/` |
| ウィンドウ装飾 AirSkyOS-light / AirSkyOS-dark (Aurorae) | Vince Liuice。元は Alexey Varfolomeev (materia-kde) | GPL-3.0 | [ChromeOS-kde](https://github.com/vinceliuice/ChromeOS-kde) / [materia-kde](https://github.com/PapirusDevelopmentTeam/materia-kde) | ボタンの背景を白/黒の円に変更、ボタンとタイトルを右へ 10px、ダーク版のタイトルを白に (ビルド時) | `theme/aurorae/` |
| スプラッシュ画面 (Splash.qml) | Marco Martin / KDE | GPL-2.0-or-later | [plasma-workspace](https://invent.kde.org/plasma/plasma-workspace) (Breeze) | 表示のフェードインなど。画像のうち `kde.svgz` / `plasma.svgz` は KDE のもの、`aozora.png` は AirSkyOS ロゴ (※2)、`clearsky.png` は壁紙 (CC-BY-SA-4.0) | `theme/ClearSky*/contents/splash/` |
| ブートアニメーション airsky-bootanimation (Plymouth) | CachyOS | GPL ※3 | [CachyOS/plymouth-theme](https://github.com/CachyOS/plymouth-theme) | 名称変更、AirSkyOS 向けの設定 | `packages/airskyos-branding/assets/plymouth/` |
| インストーラーのスライド (Calamares) | Calamares (Teo Mrnjavac, Adriaan de Groot ほか) の例を元に作成 | GPL-3.0-or-later | [Calamares](https://calamares.io/) / [cachyos-calamares](https://github.com/CachyOS/cachyos-calamares) | AirSkyOS の内容に置き換え | `iso-kit/calamares/show.qml` |

※3 配布元のリポジトリにライセンスファイルはなく、CachyOS のパッケージ (`cachyos-plymouth-bootanimation`) の記載が "GPL" です。

## 3. 改変せずに同梱しているもの

| コンポーネント | 作者 | ライセンス | 配布元 | リポジトリでの扱い |
|---|---|---|---|---|
| カーソル AOSP Cursors | The Android Open Source Project | Apache-2.0 | [AOSP](https://source.android.com/) | `theme/aosp-cursors/` に同梱 (`NOTICE` 付き)。`index.theme` に Breeze カーソルでの補完を追加 |
| ウィジェット Material Clock (V0.0.4) | Carlo Esposito | GPL-3.0-or-later | [Material-Clock](https://github.com/cesp99/Material-Clock) | 同梱せず、`scripts/fetch-third-party.sh` で取得 |
| ウィジェット Panel Colorizer (v7.0.1) | Luis Bocanegra | GPL-3.0 | [plasma-panel-colorizer](https://github.com/luisbocanegra/plasma-panel-colorizer) | 同梱せず、`scripts/fetch-third-party.sh` で取得 |

## 4. AirSkyOS 化に使っている外部のソフトウェア (同梱していない)

| ソフトウェア | 作者 | ライセンス | 用途 |
|---|---|---|---|
| [CachyOS](https://cachyos.org/) と [CachyOS-Live-ISO](https://github.com/CachyOS/CachyOS-Live-ISO) | CachyOS team | GPL-3.0 ほか | ベースのディストリビューション。ISO キットが CachyOS の archiso プロファイルを取得して書き換える |
| [cachyos-calamares](https://github.com/CachyOS/cachyos-calamares) / [CachyOS-PKGBUILDS](https://github.com/CachyOS/CachyOS-PKGBUILDS) | CachyOS team、Calamares 開発者 | GPL-3.0-or-later | インストーラー。ISO キットが設定を書き換える。必要な場合は `02b` が無改変でビルドし直す |
| [cachyos-hooks](https://github.com/CachyOS/cachyos-hooks) | CachyOS team | 配布元を参照 | OS 名を書き換える仕組みを参考にし、AirSkyOS 用のフックで上書き |
| [archiso](https://gitlab.archlinux.org/archlinux/archiso) | Arch Linux | GPL-3.0-or-later | ISO の作成 |
| [Limine](https://github.com/limine-bootloader/limine) / limine-entry-tool / limine-mkinitcpio-hook | Limine 開発者ほか | BSD-2-Clause ほか (各配布元を参照) | ブートローダー。AirSkyOS の名前と見た目を `airskyos-limine` で設定 |
| [Plymouth](https://gitlab.freedesktop.org/plymouth/plymouth) | freedesktop.org | GPL-2.0-or-later | 起動アニメーション |
| [KDE Plasma / KWin / Konsole](https://kde.org/) | KDE | GPL-2.0-or-later ほか | デスクトップ環境。Aozora Glass は KWin の非公開 API を使うため、KWin の更新ごとにビルドし直す |
| Breeze アイコン / 配色 / カーソル | KDE Visual Design Group | LGPL-3.0 / GPL-2.0-or-later | 既定のアイコンテーマ、足りないカーソルの補完 |
| [Kvantum](https://github.com/tsujan/Kvantum) | Pedram Pourang (Tsu Jan) | GPL-3.0 | ウィジェットスタイルのエンジン |
| [Noto Sans / Noto Sans CJK](https://github.com/notofonts/noto-cjk) | Google / Adobe | SIL Open Font License 1.1 | 日本語表示 (fontconfig で優先) |
| [fastfetch](https://github.com/fastfetch-cli/fastfetch) | fastfetch contributors | MIT | ターミナル起動時のシステム情報表示 |
| [PySide6](https://doc.qt.io/qtforpython-6/) / Qt 6 | The Qt Company | LGPL-3.0 ほか | ようこそアプリ |
| [FIGlet](http://www.figlet.org/) | Frank Sheeran ほか | BSD-3-Clause | ターミナルのロゴの生成 |
| Arch Linux | Arch Linux contributors | 各パッケージによる | CachyOS のベース |

ISO に入る全パッケージのソースの場所は、`iso-kit/06-source-manifest.sh` で一覧にできます。

---

記載に誤りや漏れがあれば <https://github.com/aozora9200/AirSkyOS> の Issues までご連絡ください。
