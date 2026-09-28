# AirSkyOS ISO キット

完成した AirSkyOS の PC から、配布用のインストール ISO を作るためのスクリプト一式です。
土台には CachyOS 公式の archiso プロファイル ([CachyOS-Live-ISO](https://github.com/CachyOS/CachyOS-Live-ISO)) を使います。

## 考え方: 「ディスクの丸ごとコピー」ではなく「同じ中身を組み立て直す」

今の PC のディスクを丸ごと ISO にすると、次のようなものまで入ってしまいます。

- ホームフォルダ、ブラウザの履歴、SSH 鍵
- マシン固有の ID (`/etc/machine-id`)、ネットワークの接続情報、pacman のキャッシュ

そこでこのキットでは、次の順に作ります。

1. PC からは「何が入っているか (パッケージ名の一覧)」だけを書き出す。
2. その一覧から、archiso でまっさらなシステムを組み立て直す。

```
あなたの AirSkyOS PC                          ISO
─────────────────────                        ─────────────────────────────
pacman -Qqen (公式/CachyOS リポジトリ) ─┐      CachyOS のライブ環境
pacman -Qqem (AUR・airskyos-*)   ───┐   ├──▶  + あなたのアプリ一式
      │ パッケージファイルを集める     │   │     + AirSkyOS テーマ
      ▼                             │   │     + インストーラー (Calamares)
ローカルリポジトリ (airskyos-local) ─┘   │
変更した /etc の設定 → airootfs-overlay/ ┘
```

- **個人情報:** ユーザーデータは一切入りません。ISO に入るユーザーは、ライブ起動用の `liveuser` だけです。このユーザーはインストール時に削除されます。
- **インストーラー:** オフライン方式にしています。ISO の中身がそのままディスクにコピーされるので、インターネットがなくても、ライブ環境と同じアプリ・テーマ入りでインストールできます。

## 必要なもの

- 完成した AirSkyOS の PC (ビルドもこの PC で行います)
- 空き容量 20 GB 以上
- ネット接続 (CachyOS のリポジトリからパッケージを取得します)
- テスト用: `qemu-desktop` と `edk2-ovmf`

## 手順

```bash
tar xf airskyos-iso-kit.tar.gz && cd airskyos-iso-kit
```

### 1. 今の環境を書き出す (一般ユーザーで実行)

```bash
./01-export-system.sh
```

`~/airskyos-iso/export/` に次のファイルができます。

| ファイル | 内容 | やること |
|---|---|---|
| `pkgs-repo.txt` | リポジトリから入れたアプリ | 不要なものがあれば `exclude-packages.txt` に追記 |
| `pkgs-foreign.txt` | AUR や自作のパッケージ (airskyos-* など) | 次の手順でパッケージファイルを集める |
| `etc-modified.txt` / `etc-unowned.txt` | 自分で変更した /etc の設定 | 配布したいものだけ `airootfs-overlay/` に同じパスでコピー |
| `services-enabled.txt` | 有効にしているサービス | 配布版でも有効にしたいものを `extra-services.txt` に書く |

### 2. AUR・自作パッケージをローカルリポジトリにまとめる

```bash
./02-build-localrepo.sh ../packages
```

- 次の場所から `.pkg.tar.zst` を探して、`~/airskyos-iso/localrepo` に集めます。
  - `~/airskyos-iso/localrepo` 自体 (ファイルを直接コピーしておいても使われます)
  - pacman・paru・yay のキャッシュ
  - 引数で渡したフォルダ (サブフォルダも含む)
- ファイル名ではなく、パッケージ内部の名前で照合します。インストール済みと同じバージョンがなければ、見つかった中で最新のものを使い、その旨を表示します。
- 見つからないものは一覧で表示されます。次のどちらかで対応し、もう一度実行してください。
  - パッケージをビルドする (AUR: `paru -G 名前 && cd 名前 && makepkg -s`)
  - ISO に入れない場合は `exclude-packages.txt` に書く
- **airskyos-kde-theme について:** `airskyos-kde-theme/` で `makepkg -sf` を実行してできたファイルが必要です。

### 2b. (必要なときだけ) インストーラーをビルドし直す

```bash
./02b-rebuild-calamares.sh
```

CachyOS のインストーラー (cachyos-calamares-next) を、今のリポジトリのライブラリに合わせてビルドし直します。できたパッケージはローカルリポジトリに入り、リポジトリ版の代わりに ISO へ入ります。

- **いつ使うか:** `04` が「installer ... cannot find」と警告したとき、またはライブ環境でインストーラーが起動しなかったとき。
- **やめどき:** CachyOS 側で修正版が出たら、`~/airskyos-iso/localrepo` の `cachyos-calamares-next-*.pkg.tar.zst` を削除して `02` をやり直してください。ローカル版が残っていると、ずっとそちらが使われます。

### 3. ISO の設計図 (プロファイル) を作る

```bash
./03-prepare-profile.sh
```

CachyOS のプロファイルを取得し、次の変更を自動で行います。何度実行しても、毎回まっさらな状態から作り直します。

- **パッケージ一覧:** CachyOS のライブ環境に、手順1のアプリ一覧を足します。CachyOS Hello は外します。
- **ローカルリポジトリ:** ビルド時だけ使います。ISO の中には入りません。
- **名前:** os-release、ブートメニュー、ISO ラベル、ISO のファイル名を AirSkyOS にします。
- **インストーラー:** オフライン方式に切り替え、AirSkyOS 用の見た目 (ロゴ、配色、スライド) にします。インストールログを CachyOS のサーバーへ送る設定は削除します。
- **サービス:** `extra-services.txt` に書いたサービスを有効にします。
- **独自の設定:** `airootfs-overlay/` の中身を ISO にコピーします。

### 4. ISO をビルドする

```bash
./04-build-iso.sh
```

- sudo のパスワードを聞かれます。所要時間は 20〜60 分です。
- 途中で、`airskyos-kwin-glass` のフックがガラス効果をビルドします。
- 完成すると `~/airskyos-iso/cachyos-live-iso/out/desktop/airskyos-desktop-linux-YYMMDD.iso` ができます (sha256 なども同じ場所に作られます)。ビルド後に自動で自分の所有に戻すので、普通に移動・削除できます。
- `03` をやり直すと、それまでの ISO は `~/airskyos-iso/iso-out/` に移されます。

### 5. 仮想マシンで確認する

```bash
./05-test-iso.sh
```

次の点を確認してください。

- [ ] ブートメニューに「AirSkyOS」と表示される
- [ ] ライブ環境で ClearSky のデザインとレイアウトになっている
- [ ] デスクトップの「Install」からインストールできる
  - [ ] インストーラーの見た目が AirSkyOS になっている
- [ ] インストール後に再起動し、新しく作ったユーザーでログインすると、ClearSky のレイアウトと壁紙になる
- [ ] 追加したアプリが入っている
- [ ] `/home` に新しいユーザー以外のフォルダがない
- [ ] `hostnamectl` で「AirSkyOS」と表示される

### 6. 配布する

`.iso` と `.sha256` を一緒に公開します。書き込みには `dd`、Ventoy、Rufus (DD モード) などが使えます。

ISO に入っているパッケージのソースの場所の一覧も作って、一緒に公開してください (GPL のソフトウェアを配布するため)。

```bash
./06-source-manifest.sh            # 最新の *.pkgs.txt から作る
# -> airskyos-….sources.md / .sources.tsv
```

AUR や自分でビルドしたパッケージは、配布元が消えることもあるため、PKGBUILD とソースの控えも残しておくと確実です。

## 配布前に知っておくこと

- **インストール後のアップデート:** ローカルリポジトリは ISO に入りません。そのため、`airskyos-*` や AUR のアプリは、インストール後の `pacman -Syu` では更新されません (公式/CachyOS のパッケージは通常どおり更新されます)。
  - 更新も配りたい場合は、`localrepo/` の中身を Web サーバーや GitHub Releases などで公開し、`airootfs-overlay/etc/pacman.conf` に次の設定を追加します。
    ```
    [airskyos]
    SigLevel = Optional TrustAll
    Server = https://あなたのサーバー/airskyos/$arch
    ```
    本格的に運用する場合は、パッケージへの署名 (GPG) をおすすめします。
- **ライセンス:** ISO には GPL のソフトウェアが含まれます。求められたときにソースを提供できるようにしておいてください。
  - 自作部分: PKGBUILD 一式と `AIRSKYOS-CHANGES.patch`
  - 同梱物の作者一覧: `/usr/share/doc/airskyos/NOTICE.md`
- **CachyOS の名前:** 「CachyOS ベース」と書くのは問題ありません。ただし、CachyOS 公式の配布物に見えるような表示は避けてください。ブートメニュー・インストーラー・os-release は、このキットが AirSkyOS に置き換えます。
- **セキュアブート:** CachyOS の ISO と同じく未対応です。起動できない場合は、BIOS でセキュアブートを無効にしてもらう必要があります。

## インストーラー (AirSkyOS 仕様)

CachyOS のインストーラー (Calamares) を、ISO のビルド時に AirSkyOS 用へ書き換えます。

| 項目 | 内容 |
|---|---|
| インストール方法 | ライブ環境をそのままコピーする方式だけ (どこから起動しても同じ)。CachyOS の「ネットから入れる」方式は無効化 |
| デスクトップ | Plasma のみ (デスクトップ選択画面なし) |
| ブートローダー | Limine のみ (選択画面なし)。インストール後に rEFInd と GRUB は削除 |
| 見た目 | AirSkyOS のロゴ・配色・スライド。サポートリンクなど CachyOS 向けの表示は非表示 |
| ホスト名の既定 | `airskyos-<CPU名>` |
| カーネル | ISO に入っているカーネルはすべてコピー (CachyOS 標準では `linux-cachyos` だけ) |
| 起動方法 | ライブ環境にログインすると AirSkyOS のようこそ画面が開き、「AirSkyOS をインストール」ボタンから起動。デスクトップとアプリメニューにも「AirSkyOS をインストール」 (ようこそアプリ 1.3.0 以降。入っていない場合はインストーラーが直接開く) |

- CachyOS のコマンドライン版インストーラー (`cachyos-cli-installer-new`) は、プレーンな CachyOS を入れてしまうため ISO から外しています。
- インストール後の片付け (`removeun`) は AirSkyOS 版に置き換えています。
  - CachyOS 版は依存するパッケージごと消す方式 (`pacman -Rsnc`) で、`cmake` の巻き添えで `airskyos-kwin-glass` まで消えていました。AirSkyOS 版は、ほかに必要とされているパッケージは残す方式 (`pacman -Rns`) です。
  - 元の PC で自分で入れていたパッケージ (gparted など) は削除リストから外します。
  - インストーラー本体 (Calamares) は、後の手順がその中のスクリプト (`dmcheck` など) を使うため、最後の手順 (`airskyos-finish`) でまとめて削除します。

### インストーラーが CachyOS のままにならないための仕組み

`live/airskyos-installer-setup` が、インストーラーを AirSkyOS 仕様に書き換えます。このスクリプトは次の2回実行されます。

1. ISO のビルド中 (パッケージを入れ終わった直後)
2. ライブ環境で「AirSkyOS をインストール」を押すたび (ようこそ画面のボタンも同じ)。Calamares が起動する直前に実行されます

`04` は、ビルドログにこのスクリプトの成功表示 (`AIRSKYOS-INSTALLER-OK`) がないと、ISO を「配布不可」として止まります。ライブ環境で確認するには `sudo airskyos-installer-setup` を実行し、`AIRSKYOS-INSTALLER-OK` と表示されれば AirSkyOS 仕様です。

## Limine について

CachyOS のインストーラーは、既定で Limine を起動ローダーとして設定します。オフライン方式でもそのまま使えるよう、Limine と `limine-mkinitcpio-hook` は必ず ISO に入れています。

- **ISO のビルド中:** EFI パーティションがないため、Limine のフックは失敗します (`FAT32 boot partition not found` と表示されますが、問題ありません)。代わりに、キットの `iso-hooks/` が通常の mkinitcpio でライブ用の起動イメージを作ります。
- **インストール時:** インストーラーの Limine 設定を AirSkyOS 用に書き換えます。
  - EFI の名前: `airskyos`
  - ブートメニューの見出し: `AirSkyOS`
  - 背景: AirSkyOS のスプラッシュ
  - 配色: AirSkyOS テーマ
- **インストール後:** `airskyos-release` の `zz-airskyos-limine.hook` が働きます。Limine・CachyOS の設定パッケージ・カーネルが更新されるたびに、ブートメニューの名前・配色・背景を AirSkyOS に戻します。
- `iso-hooks/` のファイルはビルドの最後に自動で削除され、インストール後のシステムには残りません。

## うまくいかないとき

| 症状 | 対処 |
|---|---|
| ライブ環境でインストーラーが起動しない (`calamares: error while loading shared libraries: libboost_python….so.1.91.0` など) | リポジトリのインストーラーが古いライブラリ向けにビルドされたまま (Arch の boost 更新に CachyOS の再ビルドが追いついていない)。`./02b-rebuild-calamares.sh` で今のライブラリに合わせてビルドし直し、`03` → `04` をやり直す。`04` はこの問題を検出すると警告を出す |
| `02` で NOT FOUND が出る | そのパッケージをビルドするか、`exclude-packages.txt` に追加 |
| インストール後、日本語が明朝体 (細い筆書き風) になる | 日本語用のゴシック体を指定する設定がなく、別の CJK フォントが選ばれていた。airskyos-branding 2026.09.24-10 以降の `airskyos-kde-settings` が Noto Sans CJK JP を優先する設定を入れる。パッケージをビルドし直して 02 からやり直す |
| インストール後のアップデートで「公開キーリングが見つかりません」「キー … は不明です」 | ライブ環境の pacman キーリングはメモリー上にあり、コピーされない。キット 2026.09.28-3 以降はインストール中に作成する。入れてしまった PC では `sudo pacman-key --init && sudo pacman-key --populate` |
| インストール時に「コマンド /etc/calamares/scripts/dmcheck が終了コード 127 で終了しました」 | インストーラーの削除が早すぎて、後の手順で使うスクリプトが消えていた。キット 2026.09.28-2 以降は最後の手順で削除する。ISO を作り直す |
| インストール時に「不適切な unpackfs の設定 / ソースファイルシステム … airootfs.sfs は存在しません」 | ライブ起動時に ISO の中身がメモリーにコピーされ (copytoram)、起動メディアが外されている。キット 2026.09.28-1 以降は、インストーラー起動のたびに実際の場所 (`/run/archiso/copytoram/airootfs.sfs` や `/run/archiso/airootfs`) を探して設定し直す。ISO を作り直す |
| `04` で「conflicting packages」と出る | 同時に入れられない2つのパッケージが一覧にある。片方を `exclude-packages.txt` へ |
| `04` で「exists in filesystem」と出る | `airootfs-overlay/` に、パッケージが持っているファイルを置いている。そのファイルを削除 |
| ガラス効果がない | ISO 内の `/var/log/airskyos-kwin-glass-build.log` を確認。インストール後なら `sudo airskyos-kwin-glass-build --force` |
| インストーラーが起動しない | ライブ環境で `/home/liveuser/cachy-install.log` を確認 |

### 無視してよいメッセージ

ビルドログに次のメッセージが出ても、ビルドの成否には関係ありません (CachyOS 公式の ISO でも出ます)。

- `... installed as ....pacnew` (ISO 用の設定ファイルが優先されている)
- `grep: command not found` / `vercmp: command not found` (パッケージを入れる順番の都合で一時的に出る)
- `Unit /etc/systemd/system/cachyos-rate-mirrors.timer is masked` (ISO では意図的に止めている)
- `Public keyring not found` / `key ... is unknown` / `keyring is not writable` (パッケージ一覧を作る段階のもの)
- `There are 2 providers available ... Enter a number (default=1)` (既定の1番が自動で選ばれる)
