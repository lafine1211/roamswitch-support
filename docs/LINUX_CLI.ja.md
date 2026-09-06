# RoamSwitch for Linux — CLI / ヘッドレス運用ガイド

[English](LINUX_CLI.md) | **日本語**

GUI を使わずに（サーバー・SSH 越し・cron・監視スクリプトから）RoamSwitch for Linux を運用するためのリファレンスです。

> [!TIP]
> **エディションの選択**:
> - **クライアント版 (`roamswitch`)**: ノートPC・ワークステーション・移動端末向け。接続先ネットワーク（Wi-Fi/有線）の信頼度に応じて自律でファイアウォールプロファイルを切り替えます。本ガイドは主にこのクライアント版のヘッドレス/CLI運用を解説します。
> - **サーバー版 (`roamswitch-server`)**: インターネットに常時露出するクラウド VPS（AWS, GCP, さくらのVPS等）やオンプレミスサーバー向け。インバウンド既定全拒否（Default Drop）、SSH 締め出し防止、ファイル整合性監視（FIM）、Falco / eBPF 連携、緊急通知（Telegram / LINE / Webhook）を装備した完全ヘッドレス設計です。サーバー版の詳細なセットアップと運用は **[RoamSwitch Server Edition 運用マニュアル](SERVER_MANUAL.ja.md)**（Web版: <https://lafine.net/linux/server-manual>）および [サーバー版セキュリティ設計書](https://lafine.net/linux/server-whitepaper) を参照してください。

---

## 1. 構成要素

| コンポーネント | 実行主体 | 役割 |
|---|---|---|
| `roamswitch-daemon`（クライアント版） | root（systemd `Type=notify`） | クライアント特権処理すべて。nftables 制御、ネットワーク判定、ランサム/マルウェア監視、fanotify、ARP/NDP 固定、DNS 適用など。TCP/UDP ソケットは開かない |
| `roamswitch-server-daemon`（サーバー版） | root（systemd `Type=notify`） | サーバー特権処理すべて。インバウンド既定全破棄、SSH/管理元IP例外保護、FIM（150+ バイナリ改ざん検知）、Falco eBPF UNIXソケット受信・プロセス凍結（`SIGSTOP`）、通知送信 |
| `roamswitch`（CLI） | ログインユーザー（一部操作は sudo） | デーモンの状態を読む薄いフロントエンド。クライアント版では `/run/roamswitch/roamswitch.sock` 越しの IPC。サーバー版では `--server` や `server` / `fim` / `emergency-restore` サブコマンドを提供 |
| `roamswitch-mcp` | AI クライアントが起動 | 読み取り専用の MCP サーバー（stdio / JSON-RPC）。プログラムや AI エージェントからの状態取得向け。→ [MCP 連携設定](https://lafine.net/mcp-setup.html) |
| `roamswitch-app` | ログインユーザー | GTK GUI（クライアント版のみ）。ヘッドレス環境では不要 |

**ヘッドレス構成ではデーモン + `roamswitch` CLI（+ 必要なら `roamswitch-mcp`）だけで運用できます。** GUI が無くても自律防御はすべて動作します。

> [!NOTE]
> クライアント版（`roamswitch`）とサーバー版（`roamswitch-server`）は排他パッケージ（`Conflicts`）です。サーバー環境では `roamswitch-server` を導入してください。

---

## 2. デーモン（systemd サービス）

### クライアント版
```sh
sudo systemctl status  roamswitch.service      # 稼働状態
sudo systemctl enable  roamswitch.service      # 起動時に自動開始（インストール時に有効）
sudo systemctl restart roamswitch.service      # 再起動
journalctl -u roamswitch.service -f            # ログ追尾
journalctl -u roamswitch.service --since "1h ago"
```

デーモンが起動時・毎サイクル（3 秒間隔）に自律で行うこと:
- 接続中のゲートウェイ MAC を識別し、`trusted_networks` 設定に照らして nftables プロファイル（`open` / `balanced` / `lockdown`）を切り替え
- ランサムウェア挙動検知（fanotify + シャノンエントロピー + カナリア）
- マルウェアのオンアクセススキャン（fanotify、任意で ClamAV）
- ARP スプーフィング監視、未信頼ネットワークでのゲートウェイ ARP/NDP 予防固定
- カーネル堅牢化（sysctl / Yama / コアダンプ / `/tmp` noexec）を該当プロファイルで適用
- 脅威保護 DNS の適用/解除（`dns_enabled` + `dns_scope`）
- リンクガード（NFQUEUE）でフィッシング接続を警告/遮断
- ランタイム状態を `/run/roamswitch/state.json` に毎サイクル出力

### サーバー版
```sh
sudo systemctl status  roamswitch-server.service      # 稼働状態
sudo systemctl restart roamswitch-server.service      # 再起動
sudo systemctl reload  roamswitch-server.service      # 設定ファイル再読込
journalctl -u roamswitch-server.service -f            # ログ追尾
```

---

## 3. CLI コマンドリファレンス

`roamswitch <コマンド> [オプション]`。引数なしは `status` と同義。出力言語は OS ロケール（`LC_ALL` / `LC_MESSAGES` / `LANG`、`ja*` なら日本語、他は英語）。

| コマンド | 権限 | 説明 |
|---|---|---|
| `status [--server]`（別名 `report` / `server-status`） | 一般 | セキュリティ健全性診断（通常20項目、`--server` 指定時はサーバー版25項目）、スコア（0–100）、等級、改善アドバイス |
| `server [config\|setup\|test-notify\|restart]` | 一般/root | Server Edition の設定表示・変更・対話ウィザード・通知テスト |
| `fim [verify\|update]` | 一般/root | クリティカルパス改ざん監視 (FIM) の検証 (`verify`) およびベースライン更新 (`update`) |
| `emergency-restore` | root | eBPF/ファイアウォール緊急遮断の全解除と初期ベースライン復旧 |
| `ports [-a\|--all]` | 一般 | 0.0.0.0 で待ち受けるリスニングポート、未認証 DB、開発サーバー。`-a` でループバックのみのポートも含む |
| `guards` | 一般 | 各自動防御ガード（ポート異常・ARP・USB ストレージ・ダウンロード・DNS 脅威・カナリア・Dev サーバー隔離・Bluetooth）の有効/無効 |
| `wifi` | 一般 | 接続中 Wi-Fi の暗号化強度（Open / WEP / WPA / 有線）。SSID |
| `sharing [status\|on\|off]` | 一般 | 共有サービス（SSH / Samba / RDP）の未信頼ネットワーク時 自動停止・復元。`on` で未信頼接続時に自動停止 |
| `audit-url <URL>` | 一般 | URL のフィッシング/危険度をローカルのフィード＋ヒューリスティックで診断（対象を取得しない） |
| `audit-secrets <text\|ファイルパス>` | 一般 | テキストまたはファイル中の API キー・秘密鍵・トークンを検出（内容を送信しない） |
| `audit-logs [hours]` | 一般 | 直近 N 時間（既定 24）の journald / 認証ログを集計・分類 |
| `canary` | 一般 | ランサムウェア・カナリア（おとりファイル）の設置状況と整合性 |
| `quarantine [list]` | 一般 | マルウェア隔離 Vault の中身（検体・元パス・脅威名・日時） |
| `knowledge [query]`（別名 `faq`） | 一般 | 同梱のオフラインナレッジベースを検索 |
| `airgap [enable\|disable]` | 一般/root | Air-Gap 緊急遮断の発動 / 解除。`enable` は全外部通信を drop、`disable` で復旧 |
| `help`（`--help` / `-h`） | 一般 | ヘルプ表示（`roamswitch <コマンド> --help` でサブコマンドヘルプ） |

### 例

```sh
roamswitch status                      # クライアント総合診断 (20項目)
roamswitch status --server             # サーバー版総合診断 (25項目)
roamswitch ports -a                    # 全リスニングポート
roamswitch guards                      # ガード稼働状態
roamswitch audit-url https://examp1e-login.com
roamswitch audit-secrets ./deploy.env
roamswitch audit-logs 72               # 直近 72 時間のログ分析
roamswitch sharing on                  # 未信頼ネットで SSH/Samba/RDP を自動停止
roamswitch fim verify                  # FIM ファイル整合性検証
sudo roamswitch fim update             # FIM ベースライン更新
sudo roamswitch emergency-restore      # 緊急遮断の全解除と復旧
roamswitch airgap enable               # 緊急遮断
roamswitch airgap disable              # 解除
```

### 注意（仕様と制限）

- サブコマンド個別の `--help`（例: `roamswitch ports --help`）に対応しています。
- 機械可読な取得は MCP（§6）または `/run/roamswitch/state.json`（§5）を使用してください。
- クライアント版において CLI からプロファイルを直接切り替えるコマンドはありません（デーモンが自律判定）。強制したい場合は `config.json` の `manual_override` を設定するか、IPC の `set_security_level` を直接呼び出します（§5）。
- `status` は診断結果に関わらず exit code 0 を返します。監視で使う場合は出力のスコア行をパースしてください（例は §7）。

---

## 4. 設定ファイル

### クライアント版 (`~/.config/roamswitch/config.json`)

デーモンは root で動作し、`/home/*/.config/roamswitch/config.json` を走査して最初に見つかったものを読みます（root しかいない場合は `/root/.config/roamswitch/config.json`）。

| キー | 型 / 既定 | 意味 |
|---|---|---|
| `language` | string / OS ロケール | 通知・CLI の言語（`ja` / `en` / `ko` / `zh-Hans` / `zh-Hant` / `de` / `fr` / `es` / `it` / `pt-PT`） |
| `trusted_networks` | `[{name, mac, level}]` | 信頼ネットワーク。`mac` はゲートウェイ MAC、`level` は `open` / `balanced` / `lockdown` |
| `away_protection_level` | string / `lockdown` | 未登録ネットワーク時のプロファイル |
| `manual_override` | string / null | `open` / `balanced` / `lockdown` を強制。null で自動 |
| `dns_enabled` | bool / `true` | 脅威保護 DNS |
| `dns_provider` | string / `quad9` | `quad9` / `cloudflare` / `adguard` / `cleanBrowsing` |
| `dns_scope` | string / `untrusted_only` | `untrusted_only`（未信頼のみ）/ `always_on`（常時） |
| `arp_spoof_guard_enabled` | bool / `true` | ARP スプーフィング監視 |
| `gateway_arp_lock_enabled` | bool / `true` | 未信頼ネットでのゲートウェイ ARP/NDP 予防固定 |
| `port_anomaly_guard_enabled` | bool / `true` | 新規の未知リスニングポート自動遮断 |
| `system_wide_fanotify_enabled` | bool / `true` | システム全体 fanotify マルウェアガード |
| `pre_exec_blocking_enabled` | bool / `true` | 実行前ブロック（FAN_DENY） |
| `entropy_freeze_enabled` | bool / `true` | ランサムウェア高速凍結（SIGSTOP） |
| `mount_hardening_enabled` | bool / `true` | `/tmp`・`/dev/shm` の noexec 化（`open` 以外で適用） |
| `yama_memory_protect_enabled` | bool / `true` | Yama ptrace 制限 |
| `usb_storage_guard_enabled` / `usb_keyboard_guard_enabled` | bool / `false` | USB ストレージ / BadUSB キーボードガード（既定 OFF） |
| `usb_zero_trust_enabled` | bool / `false` | USB バス authorized_default=0 |
| `bluetooth_guard_enabled` | bool / `false` | 未信頼ネットで Bluetooth を停波（既定 OFF） |
| `sharing_service_control_enabled` | bool / `true` | SSH / Samba / RDP の自動停止・復元 |
| `scan_exclusions` | `[string]` | YARA・ClamAV 両方から除外する絶対パス（配下含む） |
| `link_guard` | object | `{enabled, mode: "off"\|"warn"\|"block", allowlist, blocklist_extra, use_threat_dns}` |
| `vpn_on_untrusted_enabled` | bool / `false` | 未信頼ネットで VPN トンネルを自動起動 |
| `vpn_backend` | string / `wireguard` | `wireguard` / `tailscale` |

> ⚠️ `sharing_service_control_enabled: true` かつ未信頼ネットワークに接続すると **稼働中の SSH セッションが切断されます**。リモート運用では OFF 推奨。

### サーバー版 (`/etc/roamswitch/server.conf`)

サーバー版は INI 形式の設定ファイルを用い、パーミッション `0600`（root 専用）で保護されます。設定項目の詳細は **[SERVER_MANUAL.ja.md](SERVER_MANUAL.ja.md)** を参照してください。

---

## 5. ログ・ランタイム状態ファイル

| パス | 対象 | 内容 |
|---|---|---|
| `journalctl -u roamswitch.service` | クライアント | クライアントデーモンの全ログ（プロファイル切替、検知、エラー） |
| `journalctl -u roamswitch-server.service` | サーバー | サーバーデーモンの全ログ（FIM、Falcoイベント、隔離動作） |
| `/run/roamswitch/roamswitch.sock` | クライアント | クライアントデーモンの IPC Unix ドメインソケット |
| `/run/roamswitch/events.sock` | サーバー | Falco / Tetragon eBPF 連携ソケット（root:root、mode 0660。Falco も root で動くため追加権限設定不要で直接書き込み可能） |
| `/run/roamswitch/state.json` | クライアント | 毎サイクル更新。`{active_level, network_trusted, fanotify_ready}` |
| `/run/roamswitch/alerts.json` | クライアント | 直近の通知キュー |
| `/run/roamswitch/approvals.json` | クライアント | 承認待ちキュー |
| `/run/roamswitch/fanotify.ready` | クライアント | fanotify ガード稼働中フラグ |
| `/var/lib/roamswitch/fim_baseline.db` | サーバー | FIM の SHA-256 ベースラインハッシュデータベース |
| `~/.local/share/roamswitch/quarantine/` | 共通 | 隔離 Vault（`0700`、検体 `0400`）＋ `.metadata.json` |

### IPC を直接叩く（上級者向け）

デーモンは `/run/roamswitch/roamswitch.sock`（Unix ストリーム）で改行区切り JSON を受けます。

```sh
# プロファイルを強制切替（クライアント版）
printf '{"id":1,"method":"set_security_level","params":{"level":"lockdown"}}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock

# ゲートウェイ ARP 固定を今すぐ照合
printf '{"id":1,"method":"reconcile_gateway_lock","params":null}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock
```

---

## 6. プログラムからの状態取得（MCP）

`roamswitch-mcp` は stdio の JSON-RPC で読み取り専用ツールを提供します（`get_security_report` / `get_exposed_ports` / `get_guard_status` / `get_quarantine_status` / `get_canary_status` / `audit_url_safety` / `audit_secrets` / `audit_security_logs` / `get_app_help`）。ネットワークは一切使わず、デーモンの Unix ソケットか `roamswitch-core` を直接呼びます。設定は [MCP 連携設定](https://lafine.net/mcp-setup.html)。

---

## 7. 自動化レシピ

### cron で日次診断 → スコアが閾値未満ならメール

```sh
#!/usr/bin/env bash
# /etc/cron.daily/roamswitch-health
out=$(runuser -u "$SUDO_USER" -- roamswitch status 2>&1)
score=$(printf '%s\n' "$out" | grep -oE '[0-9]+/100' | head -1 | cut -d/ -f1)
if [ -n "$score" ] && [ "$score" -lt 80 ]; then
  printf '%s\n' "$out" | mail -s "RoamSwitch health: ${score}/100" root
fi
```

### 検知イベントを監視（alerts.json をポーリング）

```sh
#!/usr/bin/env bash
last=0
while :; do
  ts=$(jq -r 'max_by(.timestamp).timestamp // 0' /run/roamswitch/alerts.json 2>/dev/null || echo 0)
  if [ "$ts" -gt "$last" ]; then
    jq -c ".[] | select(.timestamp > $last)" /run/roamswitch/alerts.json | logger -t roamswitch-alert
    last=$ts
  fi
  sleep 10
done
```

### state.json で「ガードが落ちていないか」を確認

```sh
jq -e '.fanotify_ready == true' /run/roamswitch/state.json >/dev/null \
  || echo "WARNING: fanotify guard is not running" >&2
```

---

## 8. トラブルシューティング

| 症状 | 対処 |
|---|---|
| `roamswitch` が「roamswitch-mcp がインストールされているか確認」で終了 | デーモンが動いていない → `sudo systemctl start roamswitch.service`（サーバー版は `roamswitch-server.service`）。ソケットの存在確認 |
| `roamswitch status` で fanotify 項目が 🔴「ガード停止中」 | `fs.fanotify.max_user_groups`（既定 128）枯渇の一時失敗。`sudo systemctl restart roamswitch.service`、`journalctl -u roamswitch \| grep "fanotify marks established"` で確認 |
| プロファイルが `balanced` のまま `open` にならない | そのゲートウェイ MAC が `trusted_networks` に `level: open` で登録されているか確認（`level` が `balanced` なら仕様どおり） |
| SSH が突然切れる | クライアント版で `sharing_service_control_enabled: true` かつ未信頼ネット判定。リモート運用では `roamswitch sharing off` |
| 設定を変えたのに効かない | クライアント版デーモンは `/home/*/.config/…` の**最初の 1 つ**を読む。反映は `systemctl restart roamswitch.service`。サーバー版は `/etc/roamswitch/server.conf` を編集後に `sudo systemctl reload roamswitch-server` |
| サーバー版で誤って通信を遮断してしまった | クラウド事業者のコンソールから `sudo roamswitch emergency-restore` を実行し初期復帰 |

---

## 9. 参考

- 製品ページ: <https://lafine.net/linux>
- クライアント版 セキュリティ設計書（ホワイトペーパー）: <https://lafine.net/linux/whitepaper>
- サーバー版 セキュリティ設計書（ホワイトペーパー）: <https://lafine.net/linux/server-whitepaper>
- サーバー版 運用マニュアル: [SERVER_MANUAL.ja.md](SERVER_MANUAL.ja.md)（Web版: <https://lafine.net/linux/server-manual>）
- MCP 連携設定: <https://lafine.net/mcp-setup.html>
- FAQ: [FAQ.ja.md](FAQ.ja.md) ／ プライバシー: [PRIVACY.ja.md](PRIVACY.ja.md)
