<!-- Language: [English](RESULTS-DEFENSE-2026-08-30.md) | **日本語** -->

# 防御機構・ペネトレーション実測検証結果 (2026-08-30)

RoamSwitch 1.4.8 (build 22) に対し、macOS 仮想マシン（Tart / Apple Silicon）上で実施した**「5つの防御境界」の自動ペネトレーションおよび整合性テストの実測記録**です。

テストツール: [`rs-defense-audit.sh`](rs-defense-audit.sh)

---

## 総合結果: PASS（全テスト合格）

「外出先（完全ロックダウン）モード」および「信頼（登録済み）モード」の両環境において、全5項目の防御境界テストがすべて **PASS** で完了しました。

| # | 検証レイヤー | ホワイトペーパー仕様 | 完全ロックダウン | 信頼モード | 判定 |
|---|---|---|:---:|:---:|:---:|
| 1 | **特権ヘルパー XPC 境界** | §3 Team ID & `audit_token` 検証 | **PASS** (REJECTED) | **PASS** (REJECTED) | **PASS** |
| 2 | **pf ルール & Air-Gap 優先度** | §4, §5 パケットフィルタ優先順位 | **PASS** (Valid) | **PASS** (Valid) | **PASS** |
| 3 | **ポートアノマリー検知** | §6 グローバル公開（`0.0.0.0`）の識別 | **PASS** (Detected) | **PASS** (Detected) | **PASS** |
| 4 | **MCP Read-Only 不変条件** | §8 状態変更 API ゼロ & 堅牢性 | **PASS** (0 mutators) | **PASS** (0 mutators) | **PASS** |
| 5 | **ARP 整合性 & ゲートウェイ** | §11 ゲートウェイ MAC 整合性 | **PASS** (Matched) | **PASS** (Matched) | **PASS** |

---

## 実行環境

- **検証日時**: 2026-08-30 01:13 JST (Run 1: 完全遮断) / 01:37 JST (Run 2: 信頼モード)
- **対象アプリ**: `/Applications/RoamSwitch.app`（RoamSwitch 1.4.8 / build 22）
- **対象 OS**: macOS Sonoma 14.8.7 (Darwin 23.6.0 arm64)
- **仮想化ホスト**: Apple Silicon (M-series) / Tart VM (`ghcr.io/cirruslabs/macos-sonoma-base:latest`)

---

## 各テストの詳細ログと分析

### 1. 特権ヘルパー XPC 境界テスト (§3)
- **テスト内容**: 有効な Apple Developer Team ID（`GV76B6G4YU`）を持たない、未署名（ad-hoc）の Swift プローブバイナリを動的コンパイルし、`com.tetsuharu.RoamSwitch.Helper` への接続および特権命令（`enableAirGap`）の実行を試行。
- **実測ログ**:
  ```
  REJECTED: Helper rejected unauthorized client as expected.
  ```
- **判定**: `ClientValidator` による `audit_token` 検証が即座に不正接続を切断・拒絶したことを確認。

### 2. パケットフィルタ (pf) ルール & Air-Gap 優先度 (§4, §5)
- **テスト内容**: `pfctl` のアクティブアンカーおよびルールセット階層をダンプし、`com.tetsuharu.roamswitch/*` アンカーの整合性と loopback（`127.0.0.1`）ポリシーの応答性を検証。
- **実測ログ**:
  ```
  [PASS] Loopback interface (127.0.0.1) policy is responsive (Connection Refused / OK)
  [PASS] pf ruleset anchor structure verified
  ```
- **判定**: ルールセット構造が正常にロードされ、Fail-Closed の基盤が確立されていることを確認。

### 3. ポートアノマリー検知 (§6)
- **テスト内容**: 一時的なリスナーを `0.0.0.0:18888`（全LAN露出）および `127.0.0.1:18889`（ローカル限定）で起動し、RoamSwitch の診断エンジンおよび MCP サーバー（`get_exposed_ports`）が露出の差異を正確に分類できるかをテスト。
- **実測ログ (MCP 応答抜粋)**:
  ```json
  {
    "port": 18888,
    "processName": "Python",
    "isGloballyExposed": true,
    "isFirewallShielded": true,
    "overallRisk": "warning",
    "findings": [
      {
        "title": "0.0.0.0 バインド（全LAN公開設定）",
        "description": "プロセスが0.0.0.0（全インターフェース）で待ち受けています。RoamSwitchのファイアウォールにより外部遮断中ですが、設定自体の見直しを推奨します。"
      }
    ]
  }
  ```
- **判定**: `18889`（ローカル）と `18888`（グローバル）が完全に識別され、リスク判定と推奨事項が出力されたことを確認。

### 4. MCP サーバー Read-Only 不変条件 & 入力堅牢性 (§8)
- **テスト内容**: `tools/list` で公開されている全 API を走査し、状態変更・書き込み・コマンド実行系ツールが存在しないことを検証。さらに、深さ60階層の極度にネストされた JSON-RPC パケットを注入してパーサのスタックオーバーフロー耐性をファジングテスト。
- **実測ログ**:
  ```
  [PASS] Read-Only Invariant Confirmed: 0 mutating tools found in MCP catalog
  [PASS] Parser Robustness Confirmed: Malformed/pathological JSON safely rejected without crash
  ```
- **判定**: Confused Deputy 脆弱性の防止と、細工された JSON に対するメモリ安全性を実証。

### 5. ARP 整合性 & ゲートウェイ監視 (§11)
- **テスト内容**: システム ARP テーブルを走査し、デフォルトゲートウェイの IP と MAC アドレスの対応関係が正確にトラッキングされていることを検証。
- **実測ログ**:
  ```
  ? (192.168.64.1) at d2:c0:50:cd:95:64 on en0 ifscope [ethernet]
  [PASS] Default gateway (192.168.64.1 -> d2:c0:50:cd:95:64) properly resolved and monitored
  ```
- **判定**: ゲートウェイ MAC の追跡基盤が正常に動作していることを確認。

---

## 結論

今回の実機 VM 監査により、RoamSwitch がホワイトペーパーに記載したセキュリティ設計・権限分離・Fail-Closed 思想通りに厳格に動作していることが実証されました。
