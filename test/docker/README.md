# RoamSwitch for Linux — セキュリティ検証 & 再現テスト環境 (Docker)

本ディレクトリは、**RoamSwitch for Linux のホワイトペーパー（付録 C.2）に記載された防衛機構のうち、公開スイートに含まれる PENT-1〜7 を、手元の環境で再現して確かめるためのテストスイート** です。

ネットワークの操作とファイルの書き換えは、独立した `--privileged` Docker コンテナの、独自のネットワーク名前空間とマウント名前空間の中で行い、Air-Gap 遮断、ランサムウェアおとり検知、ファイアウォール強制消去に対する自己修復などを確かめます。ただし、カーネル全体で共有される設定はホストにも反映されます（下の「安全性について」を参照）。使い捨ての環境で実行してください。

---

## 🚀 クイックスタート

### 1. 前提条件
- Docker（Docker Desktop, Docker Engine 等）がインストールされていること
- 権限: `--privileged` フラグ付きでコンテナを実行できる権限（カーネル空間の `nftables` やマウント名前空間の操作を行うため必須）

### 2. テストイメージのビルド
公式 APT リポジトリ（`https://lafine.net/apt`）から最新の配布パッケージを自動取得してコンテナを構築します：

```bash
docker build -t roamswitch-test .
```

### 3. 検証テストの実行

#### A. 侵入シミュレーション & 防衛検証スイート（推奨）
ホワイトペーパー C.2 (6) の PENT-1〜7 にあたる 7 つの攻撃シナリオ（Air-Gap と自己修復、`noexec`、Yama とコアダンプ、カナリア、IP スプーフィングと SYN Flood、ホモグラフ、秘密情報の漏洩検知）に対する自律防御を自動検証します。個々の判定（`DEFENDED` か `BREACH` の行）は、カーネル設定がすべて未設定の環境で最大 17 件です。実行前から目標値だったカーネル設定は、RoamSwitch の効果とは言えないため数えず、Yama が無いカーネル（Docker Desktop の VM など）では PENT-3 の判定が `BREACH` になります。2026-10-08 に Docker Desktop（macOS）で実行したときは、判定が 14 件で、そのうち 13 件が `DEFENDED`、1 件（Yama）が `BREACH` でした：

```bash
docker run --rm --privileged roamswitch-test
```

#### B. コアデーモン破壊的セルフテスト
Air-Gap のフェイルクローズド、nftables 自己修復、カナリア検知、fanotify プローブ、エントロピー暗号化バースト検知等を詳細に検証します：

```bash
docker run --rm --privileged --entrypoint /usr/local/bin/selftest roamswitch-test
```

---

## 📋 検証スクリプトの内容

| スクリプト | 概要 | 主な検証項目 |
|---|---|---|
| `pentest.sh` | 網羅的侵入・防衛検証スイート | ・C2 通信遮断 (PENT-1)<br>・FW 強制消去に対する自己修復 (PENT-1b)<br>・`/tmp`, `/dev/shm` の `noexec` 実行拒否 (PENT-2)<br>・Yama LSM によるメモリ盗聴阻止 (PENT-3)<br>・コアダンプ抑止 (PENT-3b)<br>・カナリア改ざん・削除検知 (PENT-4)<br>・IP スプーフィング & SYN Flood 対策 (PENT-5)<br>・キリル文字同形異字 (ホモグラフ) 遮断 (PENT-6)<br>・API キー・秘密情報漏洩検知 (PENT-7) |
| `selftest.sh` | デーモン基本防衛・自己修復テスト | ・Air-Gap 有効化・外部通信切断・解除<br>・外部プロセスによる `nft delete table` 後の自動復旧<br>・デーモン強制終了（SIGKILL）後のフェイルクローズド維持<br>・fanotify イベント配送確認<br>・短時間での高エントロピー暗号化バーストのプロセス凍結 |

---

## 🔒 安全性について
- **ホストの通信**: `--network host` を付けない限り、テストコンテナは独自のネットワーク名前空間（netns）で動作します。コンテナ内で Air-Gap が発動しても、ホストのインターネット接続が切れることはありません。
- **ホストのファイル**: カナリアや高エントロピーファイルの生成・暗号化シミュレーションは、コンテナ内の `tmpfs` とコンテナのファイルシステムの上で行います。スイートがホスト上のファイルを書き換えることはありません。
- **ホストへ反映されるもの**: コンテナを `--privileged` で動かすため、Yama の `kernel.yama.ptrace_scope` や `fs.suid_dumpable` のように、カーネル全体で共有される設定は、ホスト（Docker Desktop では Docker の VM）にも反映され、コンテナを消しても戻りません。「ホストを一切変更しない」とは言えないため、使い捨ての VM やホストで実行してください。
