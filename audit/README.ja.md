<!-- Language: [English](README.md) | **日本語** -->

# Zero Telemetry 外向き通信の監査

RoamSwitch の外向き通信が、ホワイトペーパー
（[`docs/WHITEPAPER.ja.md`](../docs/WHITEPAPER.ja.md) §7）に記載した4経路だけであることを、
**主張ではなく実測で**確かめるためのツール一式です。

| # | 宛先 | プロセス | 発生条件 |
|---|---|---|---|
| 1 | `lafine.net /api/v1/license/*` | RoamSwitch | ライセンス認証／解除のときだけ |
| 2 | `lafine.net /updates/appcast.xml` | RoamSwitch | Sparkle（起動時＋24時間ごと） |
| 3 | ClamAV のミラー | `freshclam`（アプリ本体ではない） | ClamAV を導入している場合のみ |
| 4 | 対象 URL への `HEAD` | RoamSwitch | アプリ内「リンク安全性診断」を使ったときだけ |

[`../verify.sh`](../verify.sh) より重い処理です（パケットキャプチャ、MCP サーバーの実行、
`--tier-b` でマシンの一時的な静穏化）。手早い読み取り専用チェックには `verify.sh`、
共有用の `FINDINGS.md` を作りたい／第三者に追試を頼みたいときはこちらを使います。

## ファイル

- **`rs-zerotel-audit.sh`** — 監査本体。大部分は自動。人手が要る箇所（ヘルパー承認、
  実ネットワーク遷移、アプリ内メニュー操作、GUI 必須のプライバシー設定3項目）で一時停止します。
- **`CHECKLIST.txt`** / **`CHECKLIST.ja.txt`** — プレーンテキストの手順書（英 / 日）。
  テスト機で `less` で読めます（テスト機でブラウザは開かないこと）。

## 必要なもの

- macOS 13 以降、Apple Silicon、**管理者**アカウント（スクリプトは `sudo` します）
- `tcpdump`（標準）、`tshark` — `brew install wireshark`
- 任意：[LuLu](https://objective-see.org/products/lulu.html) — 入れておくと、
  プロセス別の外向きイベントを統一ログから記録し（`lulu.log`）、記事にはスクショではなく
  ログ抜粋を貼れます。

## 実行

```sh
cd ~/rs-audit                       # 作業用ディレクトリ。run-<日時>/ がここに作られる
cp /path/to/rs-zerotel-audit.sh .
chmod +x rs-zerotel-audit.sh

./rs-zerotel-audit.sh all --tier-b --idle 2h    # 環境準備＋キャプチャ＋解析
./rs-zerotel-audit.sh all --idle 2h             # 環境準備は自分でやる場合
./rs-zerotel-audit.sh all --tier-b --idle 8h    # アイドルを一晩に延ばす（任意）
./rs-zerotel-audit.sh prep-restore --outdir ~/rs-audit/run-XXXX   # prep で変えた設定を戻す
./rs-zerotel-audit.sh analyze --outdir ~/rs-audit/run-XXXX        # 解析＋FINDINGS.md だけ再実行
```

サブコマンド：`all`, `prep`, `prep-restore`, `baseline`, `monitors`, `stop`,
`sparkle`, `mcp`, `analyze`, `findings`。

在席する実作業は1回で完結します（約3〜4時間）。アイドルキャプチャの既定は2時間。
一晩に延ばすのは任意で、wall-clock の「1日1回」型ビーコンを潰す目的だけです。

## 出力（`run-<日時>/`）

- `report.md` — 判定（PASS/FAIL）＋プロセス帰属の突き合わせ表
- `FINDINGS.md` — 共有用まとめ（方法・結果・「この監査で確認できないこと」）
- `entitlements-helper.txt` / `entitlements-mcp.txt`
- `lulu.log` / `lulu-roamswitch.txt` — LuLu を入れていた場合のイベント
- 生の `cap-*.pcap`、`lsof.log`、`timeline.txt` など

## この監査で確認できないこと

- 「通信を一切しない」ではありません。上の4経路は実在します。Zero Telemetry は
  「利用状況・診断結果を収集して送信するテレメトリをしない」という意味です。
- 「絶対に無い」でもありません。結論は観測したウィンドウの範囲に限定されます。
- RoamSwitch は App Sandbox を使っていないため、entitlements は egress を
  技術的に**強制しません**。挙動で示すしかなく、それがこのツールの役割です。
- ペイロードは検査していません（宛先と TLS SNI のみ）。MCP サーバーと検知ロジックは
  OSS 公開のため、「LLM に何を渡しているか」はコードで確認できます：
  <https://github.com/lafine1211/roamswitch-mcp>

---

## 防御機構・ペネトレーション検証（macOS VM）

Zero Telemetry 監査に加えて、特権ヘルパーの XPC 境界、パケットフィルタの Air-Gap 優先度、ポートアノマリー検知などの「核心的な5つの防御機構」を実機・VM上で自動検証するためのツール一式も提供しています。

- **[防御機構・ペネトレーション検証ガイド（日本語）](README-SECURITY.ja.md)** (`rs-defense-audit.sh`)
- **[検証チェックリスト（日本語）](CHECKLIST-SECURITY.ja.txt)**
