<!-- [English](FAQ.md) -->

# よくある質問

[English](FAQ.md) | **日本語**

### 無料版でできることは？

Wi‑Fi 自動検知とカーネルパケット遮断（`pf`）、3 段階のプロファイルセキュリティレベル、
SSH / SMB / 画面共有 / AirDrop の自動停止・復元、Mac セキュリティ 10 項目の手動診断、
XProtect の状態確認、Wi‑Fi 暗号化強度の警告、ARPスプーフィング検知、公開ポート / USB
監視（表示のみ）。

### Pro 永続版（¥2,980）で追加されるものは？

ランサムウェア様の暗号化活動検知と Air‑Gap 隔離、開発サーバーの LAN 露出隔離、ポート
異常の自動遮断、ARPスプーフィング自動対応、リアルタイム通知、不正 USB ストレージガード、
DNS 脅威保護、Web・メールダウンロード保護、リンク安全性診断、バックグラウンド自律巡回、
CSV / JSON エクスポート、2 台の Mac での利用。買い切りでアップデートは無償です。

### 対応 macOS は？

macOS 13 Ventura 以降。Apple silicon / Intel の両方に対応。

### Mac App Store にありますか？

いいえ。特権ヘルパー（`SMAppService.daemon`）と `pf` 制御が必要で App Store の
サンドボックスでは実現できないため、https://lafine.net/ から署名・公証済みの `.dmg`
として配布しています。

### ヘルパーが接続できない /「Operation not permitted」

**システム設定 → 一般 → ログイン項目と機能拡張** で RoamSwitch のヘルパーを承認し、
アプリを終了して再起動してください。アプリは `/Applications` に置く必要があります。

### 自分のデータがどこかに送信されますか？

いいえ。[プライバシーポリシー](PRIVACY.ja.md) を参照してください。Zero Telemetry です。

### 新しい Mac にライセンスを移すには？

Pro は 2 台まで対応です。旧 Mac で認証解除する（または https://lafine.net/ から
サポートへ連絡する）と、新しい Mac で認証できます。

### バグ報告・機能要望はどこから？

[Issue](../../issues) を作成してください。テンプレートがあります。日本語・英語どちらでも
構いません。

## RoamSwitch for Linux

### Linux 版はありますか？

あります。**RoamSwitch for Linux**（systemd + nftables）は同じゼロトラスト思想の別
エディションです。`nftables` プロファイルの自律切替、ランサムウェアの挙動検知と Air‑Gap
隔離、USB / BadUSB ガード、20 項目診断、MCP サーバーを備えます。ダウンロード・
ドキュメントは <https://lafine.net/linux>。

### Linux 版は無料ですか？

はい。**Community Edition** は無償・全機能開放・ライセンス認証不要です。プロプライエタリ・
フリーウェア（同梱 EULA）で、ソースは公開していません。組織向けには有償の
**RoamSwitch Business**（フリート集中管理・署名付きポリシー配布・署名済み社内 APT・SLA）を
準備中です: <https://lafine.net/business>。

### 対応ディストリビューションは？

Ubuntu 22.04 / 24.04、Debian 12+、Linux Mint、Pop!_OS、elementary、Zorin、
Raspberry Pi OS 64bit、Ubuntu for Raspberry Pi（x86_64 / aarch64）。導入は APT
（`lafine.net/apt`）、DNF / zypper（`lafine.net/rpm`）、AUR（`roamswitch-bin`）。
`systemd` と `nftables` が必要で、非 systemd 系（Alpine / Void / Devuan）は非対応です。
Fedora / Arch / openSUSE はソースビルドで動作します。

APT / RPM リポジトリは GPG（RSA-4096）で署名しています。AUR パッケージ
（`roamswitch-bin`）は同じ署名鍵でリリース tarball を `validpgpkeys` 検証します。
`makepkg` が鍵のインポートを聞いてきたら `Y`、または事前に
`gpg --recv-keys 9C12964366B8547511AAEAF5773A9A39ECBD1537` を実行してください。

### デスクトップなし（ヘッドレス）で動きますか？

動きます。トレイ UI には AppIndicator/StatusNotifierItem 対応デスクトップが必要ですが、
`roamswitch-daemon` ＋ CLI（`roamswitch`）＋ MCP サーバーはヘッドレスで動作します。

### Linux 版はデータを外部へ送りますか？

送りません。HTTP クライアントを一切使わず、自前の TCP/UDP ソケットも開きません
（すべて Unix ソケットのローカル IPC）。更新確認はローカルの apt キャッシュを読むだけです。
設計書の監査・セルフチェックを参照: <https://lafine.net/linux/whitepaper>。

### Linux のバグはどう報告すればよいですか？

[Issue](../../issues) をタイトルに `[Linux]` を付けて作成し、`journalctl -u roamswitch -b` と
`roamswitch status` の出力（MAC / SSID / IP は伏せる）を添付してください。
