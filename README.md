# AirSkyOS

[CachyOS](https://cachyos.org/)(Arch Linux ベース)と KDE Plasma 6 を元にした自作ディストリビューションです。
ClearSky テーマ、ガラス調のウィンドウ効果 Aozora Glass、Limine ブートローダー、AirSkyOS 仕様のインストーラーを備えています。

[AirSkyOS](https://archive.org/details/airskyos)

このリポジトリには、AirSkyOS を作るためのソースコード一式が入っています。

- CachyOS や Arch Linux の更新で OS 名・ロゴ・テーマが元に戻らないようにするパッケージ
- テーマファイル
- ようこそアプリ
- 配布用 ISO の作成キット

## 構成

```
AirSkyOS/
├── packages/
│   ├── airskyos-branding/    OS 名・ロゴ・起動画面・KDE の既定値・Aozora Glass (5 パッケージ)
│   ├── airskyos-kde-theme/   theme/ からテーマのパッケージを作る PKGBUILD
│   └── airskyos-welcome/     ようこそアプリ (PySide6 + QML)
├── theme/                    ClearSky、ウィンドウ装飾、Kvantum、Plasma スタイル、カーソル、壁紙、Konsole
├── scripts/
│   └── fetch-third-party.sh  他の作者のウィジェット (Material Clock、Panel Colorizer) を取得
├── iso-kit/                  今の AirSkyOS 環境から配布用 ISO を作るキット
├── LICENSES/                 ライセンスの全文
├── NOTICE.md                 使用している作品・ライセンスの一覧
└── LICENSE                   GPL-3.0 (Aozora が作成したコードの既定のライセンス)
```

## ビルド

CachyOS (KDE Plasma 版) の上で実行します。

```bash
git clone https://github.com/aozora9200/AirSkyOS
cd AirSkyOS
scripts/fetch-third-party.sh

(cd packages/airskyos-branding && makepkg -si)
(cd packages/airskyos-kde-theme && makepkg -si)
(cd packages/airskyos-welcome && makepkg -si)

airskyos-apply-theme      # 今すぐ適用 (しなくても次回ログイン時に適用される)
```

詳しくは [packages/README.md](packages/README.md) を参照してください。

## ISO の作成

```bash
cd iso-kit
./01-export-system.sh
./02-build-localrepo.sh ../packages
./03-prepare-profile.sh
./04-build-iso.sh
./06-source-manifest.sh   # ISO に入る全パッケージのソースの場所の一覧
```

詳しくは [iso-kit/README.md](iso-kit/README.md) を参照してください。

## ライセンス

| 対象 | ライセンス |
|---|---|
| Aozora が作成したコード (パッケージ、スクリプト、ISO キット、設定) | [GPL-3.0-or-later](LICENSES/GPL-3.0.txt) |
| ようこそアプリ | [MIT](LICENSES/MIT.txt) |
| ClearSky グローバルテーマ (KDE Breeze を元に作成) | [GPL-2.0-or-later](LICENSES/GPL-2.0.txt) |
| 壁紙 ClearSky、Limine 起動画面 | [CC-BY-SA-4.0](LICENSES/CC-BY-SA-4.0.txt) |
| AirSkyOS ロゴ、ランチャーアイコン | [All rights reserved](LICENSES/LicenseRef-AirSkyOS-Logo.txt) (AirSkyOS の一部として改変せずに再配布することは可) |
| 他の作者の作品 (改変版を含む) | 各作品のライセンス ([NOTICE.md](NOTICE.md) と各フォルダーの `LICENSE`) |

このリポジトリを元に派生ディストリビューションを作る場合は、AirSkyOS のロゴとアイコンを独自のものに置き換えてください。

### ISO を配布するとき

ISO には GPL のソフトウェアがバイナリで入っているため、配布する人は対応するソースコードも入手できるようにする必要があります。
`iso-kit/06-source-manifest.sh` が、ISO に入る全パッケージのソースの場所を一覧にします。ISO と一緒に公開してください (GitHub Releases の添付ファイルなど)。
AUR のパッケージや自分でビルドしたパッケージは、配布元が消えることもあるため、PKGBUILD とソースの控えも一緒に残しておくと確実です。

## 謝辞

AirSkyOS は多くの作品の上に成り立っています。作者の皆さんに感謝します。一覧は [NOTICE.md](NOTICE.md) にあります。
