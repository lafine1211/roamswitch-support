<!-- Language: [English](RESULTS-LINUX-2026-09-02.md) | **日本語** -->

# RoamSwitch for Linux — セルフペネトレーションテスト／防御検証レポート（v1.0.0）

**対象:** RoamSwitch for Linux v1.0.0（`roamswitch-daemon` / `roamswitch-app` / `roamswitch` / `roamswitch-mcp`）
**ホスト＝攻撃者＝標的:** 同一の Linux マシン（Ubuntu 26.04 プレビュー、カーネル 7.0.0、glibc 2.43）と、Debian 12（リリースの glibc 下限）でビルドした使い捨て `--privileged` Docker コンテナ
**監査日:** 2026-09-02
**手法:** ホワイトボックス（ソース検査）＋ ブラックボックス（稼働中デーモンに対するファイルシステム／ネットワーク／USB の実攻撃）

---

## 1. エグゼクティブサマリ

セルフペンテストで発見された不具合はすべて **修正・再検証済み**。破壊的セルフテストスイートは
**14 / 15 PASS**。唯一の非 PASS はコンテナの制約（overlayfs/tmpfs では fanotify の許可イベントが
配送されない）によるもので、実機（ext4）では PASS する。

| # | テスト領域 | 攻撃手法 | 結果 |
|---|---|---|:---:|
| **SP-1** | ランサムウェアおとり（カナリア）改ざん検知 | ユーザーの Documents 内のおとりを rename / 削除 / 切り詰め | **PASS** — 約 2 秒で検知 → Air-Gap |
| **SP-2** | ランサムウェア一括暗号化バースト | 単一プロセスが 3 秒以内に相異なる高エントロピーファイルを 6 個以上生成 | **PASS**（実機）— `SIGSTOP` でプロセス凍結 → Air-Gap |
| **SP-2b** | `shred` 誤検知の非発生 | 複数ファイルに `shred -n 3 -u` | **PASS** — 検知されない（許可リスト） |
| **SP-2c** | 重要プロセスの非凍結 | バースト時の凍結対象を確認 | **PASS** — `systemd` / `dockerd` / `NetworkManager` / `sshd` 等を凍結しない |
| **SP-3** | Air-Gap 有効化 → 遮断 | `enable_air_gap` IPC | **PASS** — output フックに `policy drop`、全 egress 遮断 |
| **SP-3b** | Air-Gap の自己修復 | 外部から `nft delete table inet roamswitch` | **PASS** — sentinel ループが 5 秒以内に再適用 |
| **SP-3c** | Air-Gap のフェイルクローズド | Air-Gap 中にデーモンを kill → 再起動 | **PASS** — 再起動後も遮断が維持 |
| **SP-3d** | Air-Gap 解除 → 復旧 | `disable_air_gap` IPC | **PASS** — drop 解除、全マーカーファイル削除、通信復旧、自動セキュリティレベル再適用 |
| **SP-4** | マルウェア隔離 | EICAR テスト文字列を Downloads に書き込み | **PASS** — 隔離 Vault へ退避 |
| **SP-4b** | 隔離 Vault の権限堅牢化 | Vault ディレクトリ＋検体のパーミッションを確認 | **PASS** — ディレクトリ `0700`、検体 `0400` |
| **SP-5** | MCP `get_guard_status` の整合性 | 手動オーバーライドを設定してラベルを確認 | **PASS** — 「手動適用中：〈レベル〉」と正しく表示 |
| **SP-6** | BadUSB | デーモン起動時に接続済みの未登録キーボード | **PASS** — 疑わしいと扱い、明示許可まで警告 |
| **CLI** | 全サブコマンド、日英両方 | `status` / `guards` / `wifi` / `ports` / `canary` / `quarantine` / `audit-url` / `audit-secrets` / `audit-logs` / `knowledge` / `sharing` | **PASS** — 日英で正しく出力、不明コマンドは exit 1 |

---

## 2. 監査中に修正した不具合

### F1 — カナリアガードが誤ったディレクトリを監視していた — 修正済み ✅
- **発見:** デーモンは `HOME=/root` で動作するため、`$HOME` 相対のカナリアパスが
  `/root/{Documents,…}`（存在しない）へ解決されていた。専用おとり 4 個しか監視されず、
  実ユーザーの散在するおとりは未監視。rename / 削除 / 切り詰めが 3 ラウンド未検知。
- **修正:** 共通ヘルパー `syspaths::user_homes()` が `/home/*` を列挙。カナリアは実在する
  全ユーザーの Documents / Desktop / Downloads / Pictures に展開し、ディレクトリ所有者へ
  chown。検証: 監視おとり 16 個、rename → 約 2 秒で Air-Gap。

### F2 — MCP のガード状態が常に「未信頼／balanced」だった — 修正済み ✅
- **発見:** MCP の `NetworkConfig` に `#[serde(rename_all = "camelCase")]` が付いており、
  設定の snake_case キー（`trusted_networks`、`away_protection_level`）が
  デシリアライズされず、全フィールドが既定値にフォールバックしていた。
- **修正:** camelCase 指定を削除、フィールドエイリアスを追加、`away_protection_level` を
  optional 化（アプリは `null` を書く）。検証: `get_guard_status` が実際の信頼ネットワーク
  状態と手動オーバーライドを反映するようになった。

### F3 — `disable_air_gap` が正しいプロファイルを再適用しなかった — 修正済み ✅
- **発見:** Air-Gap 中にデーモンを再起動すると、nft テーブルは新規（open）だが
  `/tmp/*airgap*` マーカーが残り、アプリは「Air-Gap 発動中」を表示し続ける一方で
  通信は実際には流れていた。
- **修正:** デーモン所有の調停 — `reconcile_air_gap()` が毎サイクル実行され、マーカーが
  あるのにルールが無ければ drop を再適用、600 秒で自動失効、`disable_air_gap` は
  **全**マーカーを削除して自動セキュリティレベルを再適用。検証: 外部からのクロバー →
  5 秒で再適用、再起動 → 遮断維持、解除 → クリーンに撤去。

### F4 — 隔離 Vault のパーミッションが過剰だった — 修正済み ✅
- **発見:** Vault ディレクトリが `0777`、退避された検体が `0666` — 隔離した検体が
  誰でも読める状態で、コピーや実行が可能だった。
- **修正:** Vault ディレクトリ `0700`、検体 `0400`（読み取り専用・実行不可）。復元時は
  `0644` に戻し、退避先の所有者へ chown。

### F5 — エントロピーガードで `shred` が誤検知された — 修正済み ✅
- **発見:** `shred` がファイルをランダムデータで 3 回上書きする動作が一括暗号化バーストに
  見え、凍結されていた。
- **修正:** 正当に高エントロピーデータを書き込む約 60 のツール（`shred`、`gpg`、`ffmpeg`、
  `tar`、`borg`、`restic`、コンテナ／VM ランタイム、`apt` 等）を許可リスト化。同一パスの
  複数回上書きは 1 件として数える。エントロピートラッカーは PID 単位で、3 秒以内に
  相異なる高エントロピーファイルを 6 個以上で初めて発動。

### F6 — ビルド中に Docker デーモンがエントロピーガードで凍結された — 修正済み ✅
- **発見:** ファイルシステム全体の fanotify マークが Docker の overlay 書き込み
  （圧縮イメージレイヤ＝高エントロピー）をコンテナ相対パスで検知し、ホストのパス接頭辞
  除外に一致しなかったため `dockerd` が `SIGSTOP` され、ホスト上の全コンテナがハングした。
- **修正:** `freeze_process()` がハードコードした NEVER_FREEZE リスト（`systemd`、
  `dockerd`、`containerd`、`NetworkManager`、`sshd`、`gnome-shell`、RoamSwitch の各
  バイナリ 等）と PID ≤ 1 を照合し、凍結を拒否。コンテナ／VM ランタイムはエントロピー
  許可リストにも追加。カナリアガードの SIGSTOP 経路も同じガードを通すよう変更。
  検証: フルイメージ再ビルド中に `dockerd` は凍結されない。

---

## 3. 「外部送信データゼロ」を自分で確かめる

インストール済みパッケージだけで実行できます（ソースは非公開）：

```sh
# 配布バイナリに HTTP / TLS ライブラリがリンクされていないこと
ldd "$(command -v roamswitch-daemon)" | grep -iE 'curl|ssl|crypto|nghttp|http'   # → 出力なし

# 稼働中のデーモンがインターネットソケットを開いていないこと
sudo lsof -p "$(pgrep -x roamswitch-daemon)" -a -i                               # → 出力なし
sudo lsof -p "$(pgrep -x roamswitch-daemon)" -a -U | grep roamswitch             # → roamswitch.sock のみ

# 実測: RoamSwitch 由来の外向き接続が現れないこと
watch -n 5 'sudo ss -tupn | grep roamswitch || echo "(no external sockets)"'

# syscall レベル: connect() 先が AF_UNIX のみであること
sudo strace -f -e trace=connect -p "$(pgrep -x roamswitch-daemon)" 2>&1 | grep -i connect
```

依存ツリー・ソースの全数監査（ソース非公開のため lafine が実施）は設計書 §9 を参照:
<https://lafine.net/linux/whitepaper>。

---

## 4. 既知の制約（不具合ではない）

| 制約 | 影響 | 対応 |
|---|---|---|
| 一部カーネルで tmpfs（`/tmp`）への `FAN_MARK_MOUNT` がイベントを配送しない | `/tmp` のファイル書き込みは fanotify で監視されない | `/tmp` は揮発性かつ監視対象ユーザーフォルダではない。ランサムウェアの標的は `~/`。マーク失敗はログに明示 |
| コンテナ overlayfs / tmpfs での fanotify 非配送 | コンテナ内でのエントロピーバースト検知（SP-2）が検証不可 | ハーネスがプローブで自動判定し SP-2 を SKIP。実機（ext4）で検証 |
| RoamSwitch の `nftables` 操作と Docker の `iptables-nft` バックエンドが同一 netfilter 空間を共有 | RoamSwitch のルール操作が Docker の NAT ルールと干渉し得る | 専用テーブル `inet roamswitch` で分離。`nft flush ruleset` 等の全体操作は避ける |

---

*正規の設計書: <https://lafine.net/linux/whitepaper>。ソース: `roamswitch-linux/docs/WHITEPAPER.ja.md`（§9・付録 C）。*
