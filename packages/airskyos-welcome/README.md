# airskyos-welcome

AirSkyOS の初回起動ようこそアプリ(PySide6 + QML / ガラス調)。

## ページ
1. **ようこそ** — ロゴ・紹介文・このコンピューターの情報・特長カード
2. **テーマ** — ClearSky(ライト)/ ClearSky Dark(ダーク)を選び、次の3つから適用
   - **デフォルトに戻す**: デザイン+レイアウト(パネル・ウィジェット・壁紙)を既定に(`plasma-apply-lookandfeel --apply <ID> --resetLayout`)
   - **デザインだけ適用**: 配色・Plasma スタイル・ウィンドウ装飾・カーソル・アイコン・スプラッシュ + Kvantum(`plasma-apply-lookandfeel --apply <ID>`)
   - **レイアウトだけ適用**: パネル・ウィジェット・壁紙だけ(plasmashell の D-Bus `loadLookAndFeelDefaultLayout`)
   - レイアウトが変わる2つは確認ダイアログを表示。処理は `airskyos-session-defaults` と同じ方法で、適用後は「初回レイアウト適用済み」の印も書き込みます
3. **システム更新・アプリ導入** — `sudo pacman -Syu`、ミラー最適化(`cachyos-rate-mirrors` がある場合のみ)、おすすめアプリの一括インストール(`pacman -S --needed`)

コマンドは Konsole(無ければ kitty / alacritty / foot / xterm)で実行されます。

## ライブ環境(LiveCD / LiveUSB)
ライブ環境を検知すると、Calamares インストーラーを起動するボタンを表示します。
- 表示する場所: ようこそページのカードと、下部バー(「起動時に表示する」スイッチの代わり)
- 検知の条件(どれか1つ): カーネル引数に `archisobasedir=` / `archisolabel=` などがある、`/run/archiso` がある、`/` が airootfs
- 起動に使うもの(上から順に): `calamares_polkit` などのラッパー → `sudo -n -E calamares`(パスワード無し sudo のとき)→ `pkexec calamares`
- 起動するとようこそアプリは最小化されます
- ライブ環境では1ページ目だけを表示します(「次へ」ボタン・ページの点・矢印キーでの移動は無効)
- テスト・上書き用の環境変数:
  - `AIRSKYOS_LIVE=1` / `0` … 検知結果を強制
  - `AIRSKYOS_INSTALLER_CMD="sudo -E calamares -d"` … 起動コマンドを差し替え

## 起動時に表示するスイッチ
- `/etc/xdg/autostart/airskyos-welcome.desktop` が全ユーザーのログイン時に `airskyos-welcome --autostart` を実行
- 設定は `~/.config/AirSkyOS/welcome.conf` の `showOnStartup`。OFFなら `--autostart` は即終了
- 初期値は ON(=初回ログインで必ず表示)

## ビルド・インストール
```sh
makepkg -si        # このフォルダで実行
```
動作確認だけなら: `python -m airskyos_welcome`

必要: Qt 6.9 以上(`RectangularShadow` を使用)、pyside6

## カスタマイズ
- おすすめアプリ: `airskyos_welcome/apps.py`
- ロゴ: `airskyos_welcome/qml/logo.svg`(アプリアイコンとしてもインストールされます)
- ウィンドウ全体のガラスの色・濃さ: `qml/GlassBase.qml`
- パネルのガラス: `qml/GlassPanel.qml`(`tintOpacity`, `glossOpacity` など)

## 透け感(背面ブラー)の仕組み
- ウィンドウ自体は透明。背面のデスクトップや他のウィンドウは **KWin のブラー効果** でぼかされて透けて見えます
- `blur.py` が KDE Frameworks の `KWindowEffects::enableBlurBehind` / `enableBackgroundContrast` を ctypes で呼び出します(X11 / Wayland 両対応)
- ぼかしの強さは「システム設定 → ウィンドウの管理 → デスクトップ効果 → ブラー」で調整できます
- ブラーが無効な環境(コンポジタ無しなど)では自動で不透明寄りの表示に切り替わります。`--no-blur` で強制も可能
