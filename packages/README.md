# AirSkyOS ブランディングパッケージ

CachyOS (Arch Linux / KDE Plasma 6) ベースの AirSkyOS 用パッケージです。

```
packages/
├── airskyos-branding/     ← 5つのパッケージ (下の表) の元
│   ├── PKGBUILD
│   ├── assets/            os-release, ロゴ, Plymouth テーマ, Limine 起動画面, Aozora Glass のソース
│   └── files/             フック・スクリプト・設定
├── airskyos-kde-theme/    ← リポジトリの theme/ からテーマのパッケージを作る
│   ├── PKGBUILD
│   └── aurorae-buttons.py
└── airskyos-welcome/      ← ようこそアプリ
```

| パッケージ | 内容 |
|---|---|
| `airskyos-branding` | メタパッケージ (下の4つをまとめて入れる) |
| `airskyos-release` | os-release, ロゴ, lsb-release / issue, 更新後に書き戻す pacman フック, `/etc/airskyos/branding.conf`, NOTICE.md。**CachyOS Hello と競合するため、インストール時に CachyOS Hello を削除** |
| `airskyos-plymouth-theme` | ブートアニメーション `airsky-bootanimation` |
| `airskyos-kde-settings` | システム全体の既定値 (`/etc/xdg`): グローバルテーマ ClearSky、KWin、Glass ルール、ロック画面、カーソル、Konsole、fastfetch |
| `airskyos-kwin-glass` | Aozora Glass エフェクト。**インストール時と kwin の更新時に自動でビルド** |
| `airskyos-kde-theme` | ClearSky / Galanos / Aurorae / Kvantum / カーソル / 壁紙 / ウィジェット (Material Clock, Panel Colorizer) / Konsole プロファイル (リポジトリの `theme/` からビルド) |

## ビルドとインストール

```bash
# 1. ブランディング (Aozora Glass はインストール時に自動でビルドされる)
cd packages/airskyos-branding
makepkg -sf
sudo pacman -U airskyos-branding-*.pkg.tar.zst airskyos-release-*.pkg.tar.zst \
               airskyos-plymouth-theme-*.pkg.tar.zst airskyos-kde-settings-*.pkg.tar.zst \
               airskyos-kwin-glass-*.pkg.tar.zst

# 2. テーマ (先に他の作者のウィジェットを取得する)
../../scripts/fetch-third-party.sh
cd ../airskyos-kde-theme
makepkg -sf
sudo pacman -U airskyos-kde-theme-*.pkg.tar.zst

# 3. ようこそアプリ
cd ../airskyos-welcome
makepkg -sf
sudo pacman -U airskyos-welcome-*.pkg.tar.zst

# 4. 一般ユーザーで今すぐ適用 (しなくても次回ログイン時に適用される)
airskyos-apply-theme
```

テーマは既定でリポジトリの `theme/` フォルダーから作ります。別のフォルダーを使うときは `AIRSKY_SRC=/path/to/folder makepkg -sf` です。無いフォルダーは警告を出してスキップします。必須なのは `ClearSky` だけです。

ビルド時には次の処理を自動で行います。
- `splashscreen/org.kde.breeze.desktop/contents/splash` を ClearSky と ClearSky Dark の中にコピー (Breeze 本体には触れません)。Splash.qml から参照されている画像だけを入れます。
- Splash.qml の中で、存在しない `busyIndicator` への参照を `content` に変更
- レイアウト JS の `SlidePaths` に入っている `/home/…` を削除
- aosp-cursors に `Inherits=breeze_cursors` を追加

テーマを差し替えたときは、`airskyos-kde-theme/PKGBUILD` の `pkgrel` を上げてから、もう一度 `makepkg -sf` を実行してください。

## システム側の既定値 (`/etc/xdg`)

| ファイル | 内容 |
|---|---|
| `kdeglobals` | 既定のグローバルテーマ = ClearSky (ライト)、ClearSky Dark (ダーク)。「システム設定 → クイック設定」の「デフォルト」もこの値になる |
| `kwinrc`, `kwinrulesrc` | Aozora Glass エフェクトの設定、ボタンの配置、Aurorae、ウィンドウルール "Glass" |
| `kscreenlockerrc` | ロック画面の背景 = ClearSky |
| `kcminputrc` | カーソル = aosp-cursors |
| `plasmarc`, `ksplashrc` | Plasma スタイル = Galanos-Light、スプラッシュ = ClearSky |
| `konsolerc` | Konsole の既定プロファイル = Galanos (配色 ClearSky) |
| `fastfetch/config.jsonc` | ターミナル起動時の表示を AirSkyOS のロゴに変更 (CachyOS の fish は起動時に fastfetch を実行する) |

ユーザーが自分で設定した値 (`~/.config`) があれば、そちらが優先されます。

## acrylic-glass の自動ビルド

DKMS と同じ仕組みです。

- ソースは `/usr/src/airskyos-kwin-glass` に置かれます。
- `kwin`, `kwin-x11`, `kdecoration`, `qt6-base`, またはこのパッケージ自体がインストール・更新されると、pacman フックがビルドしてインストールします。
- kwin のバージョンが前回ビルド時と同じなら、ビルドは省略されます。
- 失敗したときは古いバイナリを削除します。古い kwin 向けのバイナリは新しい kwin をクラッシュさせるおそれがあるためです。pacman の処理自体は止めません。
  - ログ: `/var/log/airskyos-kwin-glass-build.log`
  - 手動で再ビルド: `sudo airskyos-kwin-glass-build --force`
- 反映するには、ログアウトして再ログインしてください。
- パッケージを削除すると、ビルドされたファイルも削除されます。
- 自動ビルドのため、cmake・gcc などのビルドツールが依存関係として入ります。

## 更新で元に戻らない仕組み

| 対象 | 戻っていた原因 | 対策 |
|---|---|---|
| OS名・ロゴ | CachyOS の `cachyos-branding` フックが `filesystem` / `cachyos-hooks` の更新後に書き戻す | `zz-airskyos-release.hook` が CachyOS のフックの後に AirSkyOS の内容で上書き |
| スプラッシュ | Breeze 本体 (plasma-workspace の所有物) を書き換えていた | ClearSky の中に同梱 |
| Plymouth | テーマの選択が外れる、initramfs が再生成されない | `zz-airskyos-plymouth.hook` がテーマ選択を確認し、必要なときだけ initramfs を再生成 |
| テーマ全般 | パッケージ管理外のファイルだった | すべて専用パッケージの専用パスに配置 |

`/etc/airskyos/branding.conf` で、項目ごとに自動上書きを止められます。このファイルは pacman の backup 対象なので、更新しても編集内容は保持されます。

## 注意

- Aurorae の設定ファイル名が `ChromeOS-*rc` のため、今は読み込まれていません (見た目を変えないよう、そのままにしています)。
- パッケージを削除すると、os-release と Plymouth は CachyOS のものに戻ります。

## ウィジェットの位置

デスクトップのウィジェット (Material Clock、明るさ) は左上に配置されます。位置は `airskyos-kde-theme/PKGBUILD` の `_widgets` で変更できます (単位はピクセル: x,y,幅,高さ)。
レイアウトが適用されるのは、新しいユーザーを作ったときと「デスクトップとパネルのレイアウトを適用」を選んだときです。

## ウィンドウのボタンと角

- **ボタン**: テーマのビルド時に `aurorae-buttons.py` が、閉じる・最大化・最小化などのボタンに円形の背景を付けます。ライトテーマは白い円に黒のアイコン、ダークテーマは黒い円に白のアイコンです(ホバー・押下・非アクティブの状態も含む)。
- **角**: Aurorae テーマは角の丸みを KWin に伝えられないため、ウィンドウ本体が四角いまま、丸いガラスの外に角がはみ出していました。airskyos-kwin-glass が、ウィンドウ自体を `WindowCornerRadius` (既定 22) で丸く切り抜きます。
  - KWin 6.7 以降: タイトルバーと中身をまとめて4隅を丸めます。
  - KWin 6.6: 中身の下の2隅だけを丸めます。
  - 最大化・全画面のウィンドウ、クライアント側で装飾を描くアプリ (GTK など)、自分で角を丸める装飾 (Breeze) には適用しません。
  - 無効にするには `~/.config/kwinrc` の `[Effect-aozoraglass]` に `ClipWindowContent=false` を書きます。

## デザインとレイアウトの扱い

| 項目 | いつ適用されるか | ユーザーが変更したら |
|---|---|---|
| デザイン (配色、Plasma スタイル、ウィンドウ装飾、ボタン、カーソル、スプラッシュ) | 初回ログイン時と、AirSkyOS の更新で `kde-defaults-revision` が上がったとき | 更新時に AirSkyOS の版へ戻る (ClearSky / ClearSky Dark を使っているユーザーのみ。ライト/ダークの選択は保持) |
| レイアウト (パネル、ウィジェット、配置) と壁紙 | **新しいユーザーの初回ログイン時に1回だけ** | 以後は自動で戻さない |
| 別のグローバルテーマを選んだユーザー | — | 何もしない |

- `airskyos-apply-theme`: デザインだけを今すぐ適用します (レイアウトと壁紙はそのまま)。
- `airskyos-apply-theme --layout`: レイアウトと壁紙も AirSkyOS の既定に戻します。
- 新しいユーザーにレイアウトを適用しない場合は、`/etc/airskyos/branding.conf` で `APPLY_LAYOUT_ON_FIRST_LOGIN=0` にします。

## タイトルバーの位置

ボタンとウィンドウ名は、左端から `_title_shift` (既定 10) だけ右にずらしています (`airskyos-kde-theme/PKGBUILD`)。
ダーク用の装飾 (AirSkyOS-dark) では、ウィンドウ名を白 (非アクティブ時は半透明の白) にしています。色は `_dark_title_active` / `_dark_title_inactive` で変えられます。
