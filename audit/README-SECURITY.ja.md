<!-- Language: [English](README-SECURITY.md) | **日本語** -->

# RoamSwitch 防御機構・ペネトレーション検証ガイド（macOS VM）

このドキュメントとスクリプト（`rs-defense-audit.sh`）は、RoamSwitch の設計思想（Security by Design / Fail-Closed）に基づき、**「核心的な5つの防御境界が正しく機能しているか」**を実機または macOS 仮想マシン（VM）上で検証・ペネトレーションテストするためのツール一式です。

ホワイトペーパー（[`docs/WHITEPAPER.ja.md`](../docs/WHITEPAPER.ja.md)）で定義した信頼境界・権限モデルを、客観的なスクリプトでテストします。

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

## 推奨環境（macOS VM のセットアップ）

テストによりネットワーク遮断やシステム設定の検証を行うため、**Tart** または **UTM** を用いた macOS 仮想マシン上での実行を推奨します。

### Tart を使用する場合（Apple Silicon 推奨）

```sh
# 1. Tart のインストールと設定
brew trust cirruslabs/cli
brew install cirruslabs/cli/tart

# 2. テスト用 macOS VM の作成と起動
tart clone ghcr.io/cirruslabs/macos-sonoma-base:latest rs-test-vm
tart run rs-test-vm

# 3. テスト完了後の初期化（スナップショット破棄・再作成）
tart delete rs-test-vm
```

---

## 監査スクリプトの実行方法

```sh
# スクリプトをテスト環境にコピー
cp audit/rs-defense-audit.sh ~/
chmod +x ~/rs-defense-audit.sh

# 全項目を一括自動テスト（レポート生成）
./rs-defense-audit.sh all

# 特定のレイヤーのみ個別に検証する場合
./rs-defense-audit.sh xpc      # XPC 境界テストのみ
./rs-defense-audit.sh pf       # パケットフィルタ & Air-Gap 検証のみ
./rs-defense-audit.sh port     # ポートアノマリー検知テストのみ
./rs-defense-audit.sh mcp      # MCP サーバー Read-Only & ファジングのみ
./rs-defense-audit.sh arp      # ARP 監視検証のみ
```

---

## 出力結果（`~/rs-defense-audit/run-<日時>/`）

- **`report.md`** — 各検証項目の成否表（PASS / FAIL）とシステム環境サマリ
- **`FINDINGS-DEFENSE.md`** — 公開・共有用の検証結果サマリ
- **`test_xpc.log`** / **`test_pf.log`** / **`test_port.log`** / **`test_mcp.log`** — 生の実行ログ

---

## 関連ドキュメント

- [ホワイトペーパー（日本語）](../docs/WHITEPAPER.ja.md)
- [Zero Telemetry 外向き通信の監査](README.ja.md)
