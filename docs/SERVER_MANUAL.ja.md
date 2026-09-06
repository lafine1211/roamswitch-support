# RoamSwitch Server Edition — 運用マニュアル

[English](SERVER_MANUAL.md) | **日本語**

本ドキュメントは、クラウド VPS（AWS, GCP, Azure, さくらのVPS, ConoHa, Linode 等）やオンプレミスデータセンター、コンテナホストで稼働する **RoamSwitch Server Edition** のインストールから初期設定、日常運用、セキュリティ監視、トラブルシューティングまでを網羅した公式運用マニュアルです。

---

## 1. 概要とシステム要件

RoamSwitch Server Edition は、インターネットに常時露出する Linux サーバのために設計された**完全ヘッドレス（GUI 依存ゼロ）の自律型セキュリティ＆整合性防護スイート**です。

### 1.1 主な特徴
- **Zero Telemetry（完全ローカル完結）**: 外部クラウドやベンダーサーバーへの診断データ・ログ送信は一切行いません。
- **インバウンド既定拒否（Default Drop）**: 管理者が明示許可した公開ポート（22, 80, 443 等）以外は `nftables` で無条件破棄（ステルス化）。
- **SSH 締め出し防止フェイルセーフ**: 管理用 SSH セッションおよび保守元 IP（踏み台）宛の通信は例外として常に維持され、リモートロックアウト事故を防ぎます。
- **クリティカルパス改ざん監視 (FIM)**: 150 以上の重要システムバイナリ・設定ファイルを SHA-256 でリアルタイム監視。パッケージ更新時は APT/DNF フックで自動ベースライン同期。
- **eBPF ランタイムガード & Falco 連携**: UNIX ドメインソケット直接連携によりディスク I/O 負荷とログ肥大化をゼロに抑え、カーネル LPE（Frag Gap: CVE-2026-53362）や不正侵入をミリ秒で検知・プロセス凍結（`SIGSTOP`）。
- **Docker / Podman コンテナ保護**: `DOCKER-USER` チェーン連携により、コンテナ公開時のポート迂回（ホストファイアウォール貫通）を防止。
- **緊急通知**: Telegram, LINE Messaging API, 汎用 Webhook (Slack / Discord 等) への即時日英バイリンガル通知。
- **AI / MCP ネイティブ**: AI 運用エージェント向けに読み取り専用（Read-Only）の Model Context Protocol サーバーを標準内蔵。

### 1.2 システム要件
- **対応 OS**:
  - Ubuntu 22.04 / 24.04 LTS
  - Debian 12 (Bookworm) 以降
  - AlmaLinux / Rocky Linux / RHEL 9 以降
  - Fedora 39 以降
  - openSUSE Leap 15.5+ / Tumbleweed
  - Raspberry Pi OS（64-bit）
- **アーキテクチャ**: `x86_64` (amd64) または `aarch64` (arm64)
- **カーネル要件**: Linux 5.10 以降（`nftables`、`cgroups v2`、eBPF BTF 推奨）
- **リソース消費**: メモリ常駐 20〜30MB、CPU 負荷平常時 0.1% 未満

---

## 2. インストール手順

### 2.1 APT（Ubuntu / Debian / Raspberry Pi OS）

```bash
# 1. リポジトリ署名鍵の登録
curl -fsSL https://lafine.net/apt/roamswitch-archive-keyring.asc \
  | sudo gpg --dearmor -o /usr/share/keyrings/roamswitch-archive-keyring.gpg

# 2. リポジトリの追加
echo "deb [arch=amd64,arm64 signed-by=/usr/share/keyrings/roamswitch-archive-keyring.gpg] https://lafine.net/apt stable main" \
  | sudo tee /etc/apt/sources.list.d/roamswitch.list

# 3. パッケージの更新とインストール
sudo apt update
sudo apt install roamswitch-server
```

### 2.2 DNF / RPM（Fedora / RHEL / AlmaLinux / Rocky Linux）

```bash
# 1. GPG 鍵のインポート
sudo rpm --import https://lafine.net/rpm/RPM-GPG-KEY-roamswitch

# 2. リポジトリ定義ファイルの追加
sudo curl -fsSL -o /etc/yum.repos.d/roamswitch.repo https://lafine.net/rpm/fedora/roamswitch.repo

# 3. インストール
sudo dnf install roamswitch-server
```

### 2.3 openSUSE（zypper）

```bash
sudo rpm --import https://lafine.net/rpm/RPM-GPG-KEY-roamswitch
sudo zypper addrepo https://lafine.net/rpm/opensuse/roamswitch.repo
sudo zypper refresh
sudo zypper install roamswitch-server
```

> [!NOTE]
> クライアント版（`roamswitch`）とサーバー版（`roamswitch-server`）は排他パッケージ（`Conflicts`）です。サーバー環境では必ず `roamswitch-server` を選択してください。

---

## 3. 初期設定とサービス確認

### 3.1 サービス状態の確認

インストール完了と同時に `roamswitch-server.service` が自動起動し、システム起動時の自動開始が有効化されます。

```bash
sudo systemctl status roamswitch-server.service
```

### 3.2 対話型セットアップウィザード

初回起動後、以下のコマンドで対話型セットアップを実行し、開放ポートや通知先を設定できます。

```bash
sudo roamswitch setup --server
```

ウィザードでは以下を順次設定します：
1. **公開ポートの指定**: 例: `22, 80, 443`
2. **保守元 IP（SSH 踏み台 IP）の指定**: 例: `203.0.113.50/32`（空白で任意接続許可）
3. **緊急通知チャネルの選択**: Telegram / LINE / 汎用 Webhook
4. **FIM ベースラインの初期スナップショット生成**: SHA-256 データベースの作成

### 3.3 25項目 サーバーセキュリティ診断の実行

```bash
roamswitch status --server
```

ホストのファイアウォール設定、Frag Gap 緩和、ファイルパーミッション、Docker ポート露出、SSH 設定など 25 項目を一括監査し、0〜100 のスコアと改善アドバイスを表示します。

---

## 4. 設定ファイル仕様 (`/etc/roamswitch/server.conf`)

設定ファイルはセキュリティ保持のため、パーミッション `0600`（root のみ読み書き可能）が強制されます。

```ini
[network]
# インバウンドで開放する TCP/UDP ポートリスト（カンマ区切り）
allowed_ports = 22, 80, 443

# 保守用 SSH 踏み台 IP（CIDR 表記、カンマ区切り）。指定時はこれ以外の IP からの SSH を遮断
admin_source_ips = 203.0.113.10/32, 198.51.100.0/24

# Docker ポートバイパス抑止 (DOCKER-USER チェーンへのフィルタルール挿入)
protect_docker_ports = true

# 緊急隔離 (Air-Gap) 発動時でも SSH 管理セッションを維持するか
preserve_ssh_on_isolation = true

[fim]
# ファイル整合性監視の有効化
enabled = true
# 周期ハッシュ検証の間隔（秒）
scan_interval = 300
# 監視対象外とする一時パス
exclude_paths = /var/log, /tmp, /run

[ebpf]
# Falco / Tetragon 連携ソケット
socket_path = /run/roamswitch/events.sock
# 重篤な攻撃検知時の自律アクション: "isolate" (Air-Gap) | "freeze" (SIGSTOP) | "alert_only"
action_on_critical = isolate

[notifications]
# 通知言語: "ja" | "en"
language = ja
# Telegram Bot
telegram_bot_token = 
telegram_chat_id = 
# LINE Messaging API
line_channel_access_token = 
line_user_id = 
# 汎用 Webhook (Slack, Discord, 監視システム)
webhook_url = https://hooks.slack.com/services/XXXXX/YYYYY/ZZZZZ
```

設定ファイルを直接編集した場合は、デーモンを再読込してください：
```bash
sudo systemctl reload roamswitch-server
```

---

## 5. ファイル整合性監視 (Critical Path FIM)

OS の最重要バイナリ（`/bin/login`, `/usr/bin/sudo` 等）、認証設定（`/etc/shadow`, `/etc/pam.d/` 等）、systemd ユニットのハッシュ値を照合します。

### 5.1 手動整合性検証
```bash
roamswitch fim verify
```
改ざんが検知された場合、変更・削除されたファイルの差分リストと改ざん検知アラートが出力されます。

### 5.2 OS 更新時のベースライン自動更新
Debian / Ubuntu 環境では、`/etc/apt/apt.conf.d/99roamswitch-fim` のフックにより、`apt upgrade` 実行後に自動で FIM ベースラインが更新されます。

手動でパッケージを導入・更新した場合は、以下のコマンドでベースラインを再生成してください：
```bash
sudo roamswitch fim update
```

---

## 6. eBPF ランタイムガード & Falco 連携

eBPF を用いてカーネルレベルでシステムコールやコンテナ脱出、Frag Gap（CVE-2026-53362）特権昇格の試みを検知します。

### 6.1 ログ肥大化防止チューニング
パッケージには Falco 用の最適化設定ファイルが同梱されています：
- `/etc/falco/config.d/99-roamswitch-optimized.yaml`:
  - ログ出力を標準 syslog ではなく UNIX ソケット `/run/roamswitch/events.sock` に直接転送
  - ディスク I/O ゼロ、テキストログ肥大化を根本防止
- `/etc/logrotate.d/roamswitch-falco`:
  - 万が一のファイル出力時も日次ローテーション＋3世代圧縮保持

### 6.2 異常検知時の動作
Falco が重大インシデント（C2 通信、Frag Gap 昇格コード実行等）を検知すると：
1. **ピンポイント停止**: 攻撃対象プロセスの PID に対し即座に `SIGSTOP` を発行して凍結
2. **ネットワーク隔離**: nftables により該当ソケットまたはホスト全体の外部通信を Drop
3. **緊急通知**: 管理者へ Telegram/LINE/Webhook 経由で発生ホスト・プロセス・IP を通報

---

## 7. AI エージェント / MCP 連携 (Model Context Protocol)

RoamSwitch Server Edition は、Claude や Gemini、Cursor 等の AI エージェントからホスト状態を把握できる `roamswitch-mcp` を同梱しています。

### 7.1 セーフティ設計（Read-Only 原則）
MCP インターフェース経由での操作は**完全読み取り専用**に制限されています。プロンプトインジェクション攻撃によって AI エージェントがファイアウォールを開放したり遮断を解除したりすることは原理的にできません。

### 7.2 設定例（Claude Desktop / AI クライアント）

```json
{
  "mcpServers": {
    "roamswitch": {
      "command": "/usr/bin/roamswitch-mcp",
      "args": []
    }
  }
}
```

---

## 8. CLI コマンド早見表

| コマンド | 権限 | 説明 |
|---|---|---|
| `roamswitch status --server` | 一般 | サーバー版 25 項目診断スコアとステータス表示 |
| `roamswitch ports` | 一般 | 開放中ポートとバインドプロセスの監査 |
| `roamswitch fim verify` | 一般 | クリティカルパス FIM の整合性検証 |
| `sudo roamswitch setup --server` | root | 対話型初期セットアップウィザード |
| `sudo roamswitch fim update` | root | FIM ベースラインハッシュの更新 |
| `sudo roamswitch emergency-allow` | root | トラブルシューティング用の一時的通信全開（15分間） |
| `sudo roamswitch isolate` | root | 手動での即時 Air-Gap 緊急隔離 |
| `sudo roamswitch un-isolate` | root | 緊急隔離の解除と通常防護ポリシーへの復帰 |

---

## 9. トラブルシューティング

### Q1. SSH 接続が途切れるのが心配です
A. RoamSwitch は既存の ESTABLISHED/RELATED な SSH コネクションおよび `allowed_ports`（デフォルト 22）を常に許可します。また、緊急遮断モード発動時でも `preserve_ssh_on_isolation = true` により管理経路は温存されます。

### Q2. 誤って自分自身を締め出してしまった場合
A. クラウド事業者の Web 管理コンソール（VNC / シリアルコンソール）からログインし、`sudo roamswitch emergency-allow` または `sudo systemctl stop roamswitch-server` を実行してください。

### Q3. Web サーバー（Nginx / Apache）を新しく追加した場合
A. `/etc/roamswitch/server.conf` の `allowed_ports` に `80, 443` を追記し、`sudo systemctl reload roamswitch-server` を実行してください。
