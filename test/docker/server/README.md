<!-- Language: [English](README.md) | 日本語 (see below) -->

# RoamSwitch Server Edition — Docker Self-Check Suite

Reproduces the Server Edition's internal/external penetration test locally, using the
**official APT-distributed `roamswitch-server` package** (not source you have to trust us
about — the same `.deb` anyone can install).

## Why this looks different from `test/docker/` (the Client Edition suite)

The Client Edition's suite runs as a single `--privileged` container because its threat
model is about *this machine calling out* (egress, malware execution, ransomware) — every
check can be verified from inside that one container.

The Server Edition's core feature is the opposite direction: **inbound** Default-Deny.
Proving "an external attacker cannot reach a disallowed port" genuinely requires a second,
separate container acting as that external attacker — a single container has no outside
vantage point to demonstrate this from. So this suite launches three disposable containers
on Docker's default `bridge` network:

- **target** — installs `roamswitch-server` from the public APT repo, runs the real daemon.
- **attacker** — `nmap` / `curl` against the target, exactly like a real adversary would.
- **c2** — a *separate* decoy standing in for a "known-malicious" address for the egress-guard
  test. It must not be the same container as `attacker` — the egress guard blocks the
  target's outbound replies to whatever address is in the malicious-IP feed, and completing
  a TCP handshake with `attacker` needs those replies to go through, so the two roles would
  otherwise collide and make every other test "fail" for reasons that have nothing to do with
  RoamSwitch.

## Run it

```sh
git clone https://github.com/lafine1211/roamswitch-support.git
cd roamswitch-support/test/docker/server
./run.sh
```

No `--privileged` is used or needed for the target: `--cap-add=NET_ADMIN --cap-add=NET_RAW`
is enough for its own nftables rules. The one thing this suite genuinely cannot verify from
inside a container is host-wide kernel hardening (disabling unprivileged user namespaces,
raising Yama's `ptrace_scope`, ...): those sysctls are **not** namespaced per-container, so a
`--privileged` container's writes to them would land on *your real machine*, not a sandbox —
`run.sh` deliberately avoids that and instead confirms the daemon applies the setting
attempt cleanly (and doesn't crash) when the filesystem is read-only, which is what an
unprivileged container gives you. Verifying the sysctl actually lands needs a real VM or
bare-metal host, which is exactly how the product is meant to run.

Every container this script creates is prefixed `rs-pentest-server-` and is removed again
(success or failure) when the script exits.

## Results

See [`../../../audit/RESULTS-PENTEST-SERVER-2026-09-07.md`](../../../audit/RESULTS-PENTEST-SERVER-2026-09-07.md)
for the last published run of this exact suite.

---

## 日本語

RoamSwitch Server Edition のサーバー版に対する内部・外部ペネトレーションテストを、**公式 APT
配布パッケージ（`roamswitch-server`）** を使ってお手元で再現できます（弊社を信用してくださいと
いう話ではなく、誰でも入れられるのと同じ `.deb` です）。

### なぜクライアント版のスイート（`test/docker/`）と構成が違うのか

クライアント版のスイートは単一の `--privileged` コンテナで完結します。脅威モデルが「この端末
自身が外へ出ていく」（egress、マルウェア実行、ランサムウェア）ことに関するものだからで、その
コンテナの中だけで全項目を検証できます。

サーバー版の中核機能はその逆方向——**インバウンド**の既定拒否（Default Drop）です。「許可され
ていないポートに外部の攻撃者が到達できない」ことを証明するには、その「外部の攻撃者」役の別コン
テナが本当に必要です（単一コンテナには外部視点がありません）。そのためこのスイートは Docker の
既定 `bridge` ネットワーク上に使い捨てコンテナを3つ立てます：

- **target** — 公式 APT リポジトリから `roamswitch-server` を導入し、実際のデーモンを起動。
- **attacker** — `nmap` / `curl` で target を攻撃者と同じ手段で検査。
- **c2** — egress ガード検証専用の、**attacker とは別の**「既知の悪性アドレス」役のおとり。
  attacker と同一にしてはいけません — egress ガードは悪性IPフィードに載ったアドレス宛ての
  target からの outbound 応答を遮断するため、attacker との TCP ハンドシェイク完了に必要な
  応答パケットまで巻き込まれてしまい、RoamSwitch とは無関係の理由で他の全項目が「失敗」して
  見えてしまいます。

### 実行方法

```sh
git clone https://github.com/lafine1211/roamswitch-support.git
cd roamswitch-support/test/docker/server
./run.sh
```

target には `--privileged` を使用・使用する必要もありません。自前の nftables ルール適用には
`--cap-add=NET_ADMIN --cap-add=NET_RAW` で十分です。このスイートが「コンテナの中からは本質的
に検証できない」唯一の項目はホスト全体のカーネル堅牢化（非特権 User Namespace の無効化、Yama
の `ptrace_scope` 引き上げ等）です。これらの sysctl はコンテナ単位の名前空間を持たないため、
`--privileged` コンテナからの書き込みは（サンドボックスではなく）**実際にこのテストを実行して
いるマシン本体**に反映されてしまいます。`run.sh` はこれを意図的に避け、代わりに「（非特権コン
テナの読み取り専用ファイルシステムに対して）設定の適用試行がクラッシュせずきれいに完了するか」
のみを確認します。実際に sysctl 値が反映されることの検証には、本製品が本来動作する対象である
実machineまたはVMが必要です。

このスクリプトが作るコンテナはすべて `rs-pentest-server-` から始まる名前で、成功・失敗に関わ
らずスクリプト終了時に削除されます。

### 結果

このスイートの直近の公開実行結果は
[`../../../audit/RESULTS-PENTEST-SERVER-2026-09-07.md`](../../../audit/RESULTS-PENTEST-SERVER-2026-09-07.ja.md)
（日本語版）を参照してください。
