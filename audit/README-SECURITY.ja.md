<!-- Language: [English](README-SECURITY.md) | **日本語** -->

# RoamSwitch 防御機構・ペネトレーション検証ガイド（macOS VM）

このドキュメントとスクリプト（`rs-defense-audit.sh`）は、RoamSwitch の設計思想（Security by Design / Fail-Closed）に基づき、**「核心的な5つの防御境界が正しく機能しているか」**を macOS 仮想マシン（VM: 標的環境）上で検証・ペネトレーションテストするためのツール一式です。

ホワイトペーパー（[`docs/WHITEPAPER.ja.md`](../docs/WHITEPAPER.ja.md)）で定義した信頼境界・権限モデルを、客観的なスクリプトでテストします。

---

## 役割分担（ホスト Mac ⇄ 標的 VM）

テスト環境は **「ホスト Mac（操作・外部攻撃側）」** と **「macOS VM（標的・防御側）」** に分かれます。

```
+------------------------------------+          +-----------------------------------------+
|        ホスト Mac (Host)           |          |         macOS VM (Target Guest)         |
|  - Tart / UTM で VM を起動         |  ----->  |  - RoamSwitch.app をインストール・起動  |
|  - スクリプトを VM に転送 (scp)    |   SSH    |  - rs-defense-audit.sh を内部で実行     |
|  - (任意) 外部から nmap / arpspoof |          |  - 5つの防御境界を自動検証してレポート  |
+------------------------------------+          +-----------------------------------------+
```

---

## 5つの検証項目と設計根拠

| # | 検証レイヤー | 攻撃・テストシナリオ | ホワイトペーパー根拠 | 期待される動作 |
|---|---|---|---|---|
| 1 | **特権ヘルパー XPC 境界** | 偽装プロセス・未承認クライアントからの XPC 呼び出し | §3 特権ヘルパーの設計 | Team ID / `audit_token` 検証により即時切断・要求拒絶 |
| 2 | **パケットフィルタ (pf) 優先度** | Air-Gap 隔離発動時の全パケット drop 検証 | §4, §5 pf 処理・隔離 | 個別許可ルールに優先して全外向き通信が drop されること |
| 3 | **ポートアノマリー検知** | `0.0.0.0` バインドの新規外部公開ポート検知 | §6 未信頼ネットワーク保護 | グローバル公開とローカル限定（`127.0.0.1`）が識別されること |
| 4 | **MCP Read-Only 不変条件** | 状態変更ツールの不在 & 不正入力ファジング | §8 MCP セキュリティモデル | 変更 API ゼロ、巨大/ネスト JSON による DoS が起きないこと |
| 5 | **ARP / ゲートウェイ整合性** | ゲートウェイ MAC の急変・重複監視 | §11 脅威モデル | ARP キャッシュを監視し、整合性の破綻時に隔離が発動すること |

---

## ステップ・バイ・ステップ実行手順

### Step 1: 【ホスト側】VM（Tart）の作成と起動

```sh
# Tart のインストール
brew trust cirruslabs/cli
brew install cirruslabs/cli/tart

# テスト用 macOS VM の作成と起動
tart clone ghcr.io/cirruslabs/macos-sonoma-base:latest test-mac
tart run test-mac
```

---

### Step 2: 【VM 内部】RoamSwitch のインストールと準備

VM 内の GUI または SSH（`ssh admin@$(tart ip test-mac)`、パスワード: `admin`）で以下を実行します：

```sh
# 1. Swift コマンドラインツールの確認
xcode-select --install

# 2. RoamSwitch のダウンロードとインストール
curl -sSL -o /tmp/RoamSwitch.dmg "https://lafine.net/downloads/RoamSwitch.dmg"
hdiutil attach /tmp/RoamSwitch.dmg
cp -R /Volumes/RoamSwitch/RoamSwitch.app /Applications/
hdiutil detach /Volumes/RoamSwitch

# 3. RoamSwitch を起動し、特権ヘルパーを承認（パスワード入力）
open /Applications/RoamSwitch.app
```

---

### Step 3: 【ホスト側 ➔ VM】スクリプトの転送

ホスト側のターミナルから、VM 内部へ `rs-defense-audit.sh` をコピーします：

```sh
# VM の IP アドレスを取得
VM_IP=$(tart ip test-mac)

# ホストから VM のホームディレクトリへ転送
scp /Users/tetsuharu/Dev/roamswitch-support/audit/rs-defense-audit.sh admin@$VM_IP:~/
```

---

### Step 4: 【VM 内部】監査スクリプトの実行

VM 内部のターミナル（または SSH セッション内）で実行します：

```sh
chmod +x ~/rs-defense-audit.sh

# 全項目を一括自動テスト（レポート生成）
~/rs-defense-audit.sh all

# 特定レイヤーのみ個別に検証する場合
~/rs-defense-audit.sh xpc      # XPC 境界テストのみ
~/rs-defense-audit.sh pf       # パケットフィルタ & Air-Gap 検証のみ
~/rs-defense-audit.sh port     # ポートアノマリー検知テストのみ
~/rs-defense-audit.sh mcp      # MCP サーバー Read-Only & ファジングのみ
~/rs-defense-audit.sh arp      # ARP 監視検証のみ
```

---

## 出力結果（VM 内の `~/rs-defense-audit/run-<日時>/`）

- **`report.md`** — 各検証項目の成否表（PASS / FAIL）とシステム環境サマリ
- **`FINDINGS-DEFENSE.md`** — 公開・共有用の検証結果サマリ
- **`test_xpc.log`** / **`test_pf.log`** / **`test_port.log`** / **`test_mcp.log`** — 生の実行ログ

テスト完了後、VM を破棄して完全に初期状態へ戻す場合：
```sh
# ホスト側で実行
tart delete test-mac
```

---

## 関連ドキュメント

- [ホワイトペーパー（日本語）](../docs/WHITEPAPER.ja.md)
- [Zero Telemetry 外向き通信の監査](README.ja.md)
