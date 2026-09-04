# RoamSwitch for Linux — CLI / ヘッドレス運用ガイド

[English](LINUX_CLI.md) | **日本語**

GUI を使わずに（サーバー・SSH 越し・cron・監視スクリプトから）RoamSwitch for
Linux を運用するための資料です。対象は現行の **クライアント版**。サーバー版
（近日リリース予定）については <https://lafine.net/linux#editions> を参照して
ください。

---

## 1. 構成要素

| コンポーネント | 実行主体 | 役割 |
|---|---|---|
| `roamswitch-daemon` | root（systemd `Type=notify`） | 特権処理すべて。nftables 制御、ネットワーク判定、ランサム/マルウェア監視、fanotify、ARP/NDP 固定、DNS 適用など。TCP/UDP ソケットは開かない |
| `roamswitch`（CLI） | ログインユーザー | `roamswitch-daemon` の状態を読む薄いフロントエンド。Unix ドメインソケット `/run/roamswitch/roamswitch.sock` 越しの IPC のみ |
| `roamswitch-mcp` | AI クライアントが起動 | 読み取り専用の MCP サーバー（stdio / JSON-RPC）。プログラムからの状態取得向け。→ [MCP 連携設定](https://lafine.net/mcp-setup.html) |
| `roamswitch-app` | ログインユーザー | GTK GUI。ヘッドレスでは不要 |

**ヘッドレス構成では `roamswitch-daemon` + `roamswitch`（+ 必要なら
`roamswitch-mcp`）だけで運用できます。** `roamswitch-app` が無くても daemon の
自律防御はすべて動作します（承認ダイアログを要する操作は「フェイルオープン
（3 分）」または設定で無効化して回避）。

---

## 2. デーモン（systemd サービス）

```sh
sudo systemctl status  roamswitch.service      # 稼働状態
sudo systemctl enable  roamswitch.service      # 起動時に自動開始（インストール時に有効）
sudo systemctl restart roamswitch.service      # 再起動
journalctl -u roamswitch.service -f            # ログ追尾
journalctl -u roamswitch.service --since "1h ago"
```

デーモンが起動時・毎サイクル（3 秒間隔）に自律で行うこと:

- 接続中のゲートウェイ MAC を識別し、`trusted_networks` 設定に照らして
  nftables プロファイル（`open` / `balanced` / `lockdown`）を切り替え
- ランサムウェア挙動検知（fanotify + シャノンエントロピー + カナリア）
- マルウェアのオンアクセススキャン（fanotify、任意で ClamAV）
- ARP スプーフィング監視、未信頼ネットワークでのゲートウェイ ARP/NDP 予防固定
- カーネル堅牢化（sysctl / Yama / コアダンプ / `/tmp` noexec）を該当プロファイルで適用
- 脅威保護 DNS の適用/解除（`dns_enabled` + `dns_scope`）
- リンクガード（NFQUEUE）でフィッシング接続を警告/遮断
- ランタイム状態を `/run/roamswitch/state.json` に毎サイクル出力

---

## 3. CLI コマンドリファレンス

`roamswitch <コマンド> [オプション]`。引数なしは `status` と同義。出力言語は
OS ロケール（`LC_ALL` / `LC_MESSAGES` / `LANG`、`ja*` なら日本語、他は英語）。

| コマンド | 説明 |
|---|---|
| `status`（別名 `report`） | セキュリティ健全性診断 20 項目、スコア（0–100）、等級、各項目の改善アドバイス |
| `ports [-a\|--all]` | 0.0.0.0 で待ち受けるリスニングポート、未認証 DB、開発サーバー。`-a` でループバックのみのポートも含む |
| `guards` | 各自動防御ガード（ポート異常・ARP・USB ストレージ・ダウンロード・DNS 脅威・カナリア・Dev サーバー隔離・Bluetooth）の有効/無効 |
| `wifi` | 接続中 Wi-Fi の暗号化強度（Open / WEP / WPA / 有線）。SSID |
| `sharing [status\|on\|off]` | 共有サービス（SSH / Samba / RDP）の未信頼ネットワーク時 自動停止・復元。`on` にすると `config.json` の `sharing_service_control_enabled` を書き換え、daemon に即時適用を依頼 |
| `audit-url <URL>` | URL のフィッシング/危険度をローカルのフィード＋ヒューリスティックで診断（対象を取得しない） |
| `audit-secrets <text\|ファイルパス>` | テキストまたはファイル中の API キー・秘密鍵・トークンを検出（内容を送信しない） |
| `audit-logs [hours]` | 直近 N 時間（既定 24）の journald / 認証ログを集計・分類 |
| `canary` | ランサムウェア・カナリア（おとりファイル）の設置状況と整合性 |
| `quarantine [list]` | マルウェア隔離 Vault の中身（検体・元パス・脅威名・日時） |
| `knowledge [query]`（別名 `faq`） | 同梱のオフラインナレッジベースを検索 |
| `airgap [enable\|disable]` | Air-Gap 緊急遮断の発動 / 解除（`--help` には非表示）。`enable` は全外部通信を drop、`disable` で復旧 |
| `help`（`--help` / `-h`） | ヘルプ |

### 例

```sh
roamswitch status                      # 総合診断
roamswitch ports -a                    # 全リスニングポート
roamswitch guards                      # ガード稼働状態
roamswitch audit-url https://examp1e-login.com
roamswitch audit-secrets ./deploy.env
roamswitch audit-logs 72               # 直近 72 時間のログ分析
roamswitch sharing on                  # 未信頼ネットで SSH/Samba/RDP を自動停止
roamswitch airgap enable               # 緊急遮断
roamswitch airgap disable              # 解除
```

### 注意（現行の制限）

- サブコマンド個別の `--help` は未実装バージョンがあります（`roamswitch status
  --help` が診断を実行してしまう）。1.0.43 以降で修正。
- CLI は **`--json` 出力に未対応**。機械可読な取得は MCP（§6）か
  `/run/roamswitch/state.json`（§5）を使ってください。
- CLI から**プロファイルを直接切り替えるコマンドはありません**（daemon が
  自律判定）。強制したい場合は `config.json` の `manual_override` を設定するか、
  IPC の `set_security_level` を直接叩きます（§5）。
- `status` は診断結果に関わらず **exit code 0** を返します。監視で使う場合は
  出力のスコア行をパースしてください（例は §7）。

---

## 4. 設定ファイル

`~/.config/roamswitch/config.json`（JSON）。**デーモンは root で動作し、
`/home/*/.config/roamswitch/config.json` を走査して最初に見つかったものを
読みます**（ヘッドレスサーバーで root しかいない場合は
`/root/.config/roamswitch/config.json`）。編集後は反映のためデーモンへ通知される
操作（`roamswitch sharing …` 等）を行うか、`sudo systemctl restart
roamswitch.service`。

### 主なキー

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

### 例（ヘッドレスサーバー向けの保守的な設定）

```jsonc
{
  "language": "ja",
  "manual_override": "balanced",           // 常に balanced（自律切替を実質固定）
  "dns_enabled": true,
  "dns_scope": "always_on",
  "sharing_service_control_enabled": false, // SSH を切られると困るので OFF
  "system_wide_fanotify_enabled": true,
  "entropy_freeze_enabled": true,
  "mount_hardening_enabled": true,
  "link_guard": { "enabled": true, "mode": "block" },
  "scan_exclusions": ["/var/lib/myapp/cache", "/srv/backups"]
}
```

> ⚠️ `sharing_service_control_enabled: true` かつ未信頼ネットワークに接続すると
> **稼働中の SSH セッションが切断されます**。リモート運用では OFF 推奨。

---

## 5. ログ・ランタイム状態ファイル

| パス | 内容 |
|---|---|
| `journalctl -u roamswitch.service` | デーモンの全ログ（プロファイル切替、検知、エラー） |
| `/run/roamswitch/state.json` | 毎サイクル更新。`{active_level, network_trusted, fanotify_ready}` |
| `/run/roamswitch/alerts.json` | 直近の通知キュー（GUI が拾う。ヘッドレスでもここを見れば検知が分かる） |
| `/run/roamswitch/approvals.json` | 承認待ちキュー（マルウェア確認・BadUSB・link_block など） |
| `/run/roamswitch/fanotify.ready` | fanotify ガードが実際に稼働中なら存在（内容: `content` / `notify`） |
| `~/.local/share/roamswitch/quarantine/` | 隔離 Vault（`0700`、検体 `0400`）＋ `.metadata.json` |

### IPC を直接叩く（上級者向け）

デーモンは `/run/roamswitch/roamswitch.sock`（Unix ストリーム）で改行区切り
JSON を受けます。CLI に無い操作の例:

```sh
# プロファイルを強制切替
printf '{"id":1,"method":"set_security_level","params":{"level":"lockdown"}}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock

# ゲートウェイ ARP 固定を今すぐ照合
printf '{"id":1,"method":"reconcile_gateway_lock","params":null}\n' \
  | sudo socat - UNIX-CONNECT:/run/roamswitch/roamswitch.sock
```

---

## 6. プログラムからの状態取得（MCP）

`roamswitch-mcp` は stdio の JSON-RPC で読み取り専用ツールを提供します
（`get_security_report` / `get_exposed_ports` / `get_guard_status` /
`get_quarantine_status` / `get_canary_status` / `audit_url_safety` /
`audit_secrets` / `audit_security_logs` / `get_app_help`）。ネットワークは一切
使わず、デーモンの Unix ソケットか `roamswitch-core` を直接呼びます。設定は
[MCP 連携設定](https://lafine.net/mcp-setup.html)。

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
| `roamswitch` が「roamswitch-mcp がインストールされているか確認」で終了 | デーモンが動いていない → `sudo systemctl start roamswitch.service`。ソケット `/run/roamswitch/roamswitch.sock` の存在確認 |
| `roamswitch status` で fanotify 項目が 🔴「ガード停止中」 | `fs.fanotify.max_user_groups`（既定 128）枯渇の一時失敗。`sudo systemctl restart roamswitch.service`、`journalctl -u roamswitch \| grep "fanotify marks established"` で確認 |
| プロファイルが `balanced` のまま `open` にならない | そのゲートウェイ MAC が `trusted_networks` に `level: open` で登録されているか確認（`level` が `balanced` なら仕様どおり） |
| SSH が突然切れる | `sharing_service_control_enabled: true` かつ未信頼ネット判定。リモート運用では `roamswitch sharing off` |
| 設定を変えたのに効かない | デーモンは `/home/*/.config/…` の**最初の 1 つ**を読む。複数ユーザーがいる場合は意図したファイルか確認。反映は `systemctl restart roamswitch.service` |

---

## 9. 参考

- 製品ページ: <https://lafine.net/linux>
- セキュリティ設計書（ホワイトペーパー）: <https://lafine.net/linux/whitepaper>
- MCP 連携設定: <https://lafine.net/mcp-setup.html>
- FAQ: [FAQ.ja.md](FAQ.ja.md) ／ プライバシー: [PRIVACY.ja.md](PRIVACY.ja.md)
