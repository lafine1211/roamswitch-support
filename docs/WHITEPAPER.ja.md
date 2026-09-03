# RoamSwitch アーキテクチャ／セキュリティホワイトペーパー

> RoamSwitch がどのような権限で動作し、その境界で何を行っているのかを説明する技術文書です。 宣伝的な表現は使わず、記載した内容はすべて、配布中のアプリのバイナリと実際の動作から確認できるようにしています。

**版** v1.3 · **対象** RoamSwitch 1.8.0 · **要件** macOS 13.0+ / Apple Silicon · **発行** 2026-09-03 · **Team ID** GV76B6G4YU

*v1.3: リンク保護の強制ポイントに **NEFilterDataProvider システム拡張**を追加（§3・§5・§7）——名前解決後の TCP フローを直接見るため DoH／DoT を使うブラウザも遮断でき、`/etc/hosts` を書き換えない。VPN バックエンドを **WireGuard／Tailscale から選択可能**に（§4・§5・§7）。ヘルパー 1.8.0。*
*v1.2: VPN トンネル + キルスイッチ（§4・§5・§7、1.7.6）、予防的ゲートウェイ ARP/NDP 固定（§5、1.7.5）、USB ストレージの承認プロンプト（§11、1.7.4）を追記。ヘルパー 1.6.0。*
*v1.1: リンク保護（§5、フィッシング接続の `/etc/hosts` 遮断）と、その脅威フィード（§7・§11、受信専用の日次取得、フィード専用署名鍵）を追記。*

*正規版（整形済み）: <https://lafine.net/security.html>。この Markdown はその Git 履歴のためのミラーで、内容は同一です。*

> **RoamSwitch for Linux** には、`nftables` ベースのアーキテクチャと「外部送信データゼロ」の
> コードレベル監査を扱う専用の設計書があります: <https://lafine.net/linux/whitepaper>。

## §1. この文書について

RoamSwitch は、メニューバーに常駐する Mac 向けのアプリです。いま接続しているネットワークをどの程度 信頼しているかに応じて、macOS のファイアウォール、共有サービス、AirDrop、DNS を自動的に切り替えます。 あわせて、ARP スプーフィング、外部に開いたポート、USB ストレージ、ランサムウェアのような暗号化の動きを 監視しており、危険を検知した場合には、パケットフィルタ（`pf`）で通信を遮断する緊急隔離 （Air-Gap）まで行います。

つまり RoamSwitch は、root 権限のデーモンを常駐させ、その気になれば Mac の通信をすべて止められる、 ということになります。開発元は個人であり、「信頼してください」という言葉だけでこの権限を正当化することは できません。そこで本書では、その代わりに、設計の内容を検証できる形で説明していきます。

### 対象となる読者

- 導入するかどうかを技術的に判断したいエンジニアの方
- レビューや記事化の前に、内部の作りを確認しておきたいセキュリティ研究者・ジャーナリストの方
- 自社導入や OEM 同梱を検討している、パートナー企業のセキュリティ担当の方

### この文書が扱わないこと

検知ロジックのしきい値調整や誤検知の統計、画面の操作手順については触れません。本書で説明するのは、 **権限、プロセスの境界、データの流れ、暗号**の 4 つです。機能そのものの仕様は、同梱の MCP リソース `roamswitch://docs/features` と、アプリ内のヘルプに記載しています。

### 何をどこまで書くか（開示方針）

本書は、攻撃者がすでに配布バイナリを入手している、という前提で書いています。ここに登場するエンドポイント の URL、識別子、ファイルパス、XPC プロトコル、埋め込みの公開鍵は、いずれも出荷済みの `RoamSwitch.app` から `strings` や `codesign -d`、通信プロキシを使えば、 数分で取り出せるものです。ですから、これらを記載しても、攻撃者にとっての手がかりが増えることはありません。 増えるのは、レビューする側の理解だけです。

一方で、バイナリからは分からないサーバー側の実装 ── レート制限のしきい値、鍵、管理用のエンドポイント、 DB スキーマ、Firebase プロジェクトの構成 ── は記載しません。OEM・パートナー連携の設計も本書の範囲外とし、 別の内部文書で扱います。「クライアントを観察すれば分かる範囲」が、本書の開示の線引きです。

> **補足**
>
> 本書の内容は、冒頭に記載したバージョンのソースに対応しています。以降のバージョンで挙動が変わった箇所に ついては、改版のうえ版番号と対象ビルドを更新します。記述とコードの食い違いに気づかれた場合は、 `lafine.net/contact.html` からお知らせください。

## §2. コンポーネントと信頼境界

`RoamSwitch.app` は、3 つの実行体で構成されています。このうち特権を持つのは 1 つだけで、 残りの 2 つはログインユーザーの権限で動作します。3 つとも Hardened Runtime を有効にし、Developer ID で 署名して公証を受けた状態で配布しています。

_図：RoamSwitch のコンポーネントと信頼境界（MCP クライアント → MCPServer / RoamSwitch.app ⇄ Helper(root) → システムバイナリ）。_

_* MCPServer はアプリ本体には接続せず、共有の設定ドメインと監視モジュールを直接読み取ります（§8）。_

**コンポーネント別の権限と役割**

| 実行体 | 権限 | できること | できないこと |
| --- | --- | --- | --- |
| RoamSwitch .app | ログインユーザー | ネットワーク状態の監視、各種診断、UI 表示、ヘルパーへの XPC 呼び出し、AirDrop の `defaults` 変更、ClamAV（任意）の起動 | ファイアウォール・pf・システムデーモンの直接操作（すべてヘルパー経由で行います） |
| RoamSwitch Helper | **root** | `HelperProtocol` に列挙された操作だけ（§3 の表）。ファイアウォール／ステルス、共有デーモンの load / unload、pf ルールセットの適用、DNS の変更、プロセスへのシグナル送出 | それ以外。任意コマンドを実行するためのインターフェースはありません。ネットワーク送信の entitlement もありません |
| RoamSwitch MCPServer | ログインユーザー | 診断値の読み取りと整形、ローカルのナレッジベース検索。結果は stdio 経由でクライアントに返します | 設定変更、ロックダウン切替、ポート隔離、デバイス取り出し。ソケットは開きません。ネットワーク送信もありません |

### Entitlements と署名

- 3 つのターゲットは、いずれも `ENABLE_HARDENED_RUNTIME = true` です。
- App Sandbox は無効にしています（`com.apple.security.app-sandbox = false`）。ヘルパーと MCPServer の entitlements は、空の辞書です。
- 配布用のビルドには、Developer ID Application 署名、Apple の公証、staple を行っています（§10）。

> **設計上のトレードオフ**
>
> App Sandbox は使っていません。RoamSwitch は、IOKit からのハードウェア UUID の取得、CoreWLAN、 DiskArbitration、他プロセスの待ち受けソケットの列挙（`lsof`）、LaunchDaemon への XPC 接続、 システムバイナリの起動を必要とします。これらはいずれもサンドボックスの中では実現できないため、 有効にしていません。
>
> その代わりに、次の 4 つで補っています。1 つ目は Hardened Runtime、2 つ目は Developer ID 署名と公証です。 3 つ目は、root で動く実行体をヘルパー 1 つに限定し、そのヘルパーが実行できる操作を固定して一覧化して いること（§3 の表）。4 つ目は、ヘルパーへの接続をコード署名で制限していること（§3）です。

## §3. 特権ヘルパーの設計

### 登録のされ方

ヘルパーは、`SMAppService.daemon(plistName:)` を使って LaunchDaemon として登録します。 アプリに埋め込んだ plist（`Contents/Library/LaunchDaemons/com.tetsuharu.RoamSwitch.Helper.plist`） で宣言しているのは、`Label`、`BundleProgram`、`MachServices` の 1 エントリ、 `AssociatedBundleIdentifiers` だけです。`SMAppService` の仕様上、アプリが `/Applications` に置かれていないと、そもそも登録できません。初回の登録時には、ユーザーが システム設定でヘルパーを手動で承認しないと有効になりません。

### 誰の接続を受けるか（`ClientValidator`）

ヘルパーは、`NSXPCListener` の `shouldAcceptNewConnection` で接続元を検査し、これを 通過したものにだけ `HelperProtocol` を渡します。検査には、PID ではなく **`audit_token`** を使っています。PID の使い回しや TOCTOU を避けるためです。

```sh
# Release ビルドで接続元に要求するコード署名要件
identifier "com.tetsuharu.RoamSwitch"
  and anchor apple generic
  and certificate leaf[subject.OU] = "GV76B6G4YU"
```

この要件を `SecCodeCopyGuestWithAttributes` と `SecStaticCodeCheckValidity` で 照合し、通らなければ接続を切ります。チーム ID の固定を外しているのは DEBUG ビルドだけで、これは開発中の 都合によるものです。実際に配布されるのは、常に Release ビルドです。

> **境界の要点**
>
> ヘルパーの安全性は、このコード署名要件 1 つに懸かっています。要件を満たす相手（正規に署名された `RoamSwitch.app`）であれば、下の表にある操作をすべて呼び出せます。任意のコマンドを流し込む 口はありませんが、表に並んでいる操作そのものは、決して弱いものではありません。`RoamSwitch.app` 本体が乗っ取られた場合、これらの操作は攻撃者の手に渡ります。

### ヘルパーができること（全リスト）

`Shared/HelperProtocol.swift` が定義している特権操作は、以下がすべてです。ここに載っていない 特権 API はありません。

**HelperProtocol — root で実行される操作の全て**

| メソッド | 行うこと | 起動されるバイナリ / API |
| --- | --- | --- |
| setBlockAll(_:) | アプリケーションファイアウォールとステルスモードの ON / OFF | /usr/libexec/ApplicationFirewall/socketfilterfw --setblockall / --setstealthmode |
| getBlockAllStatus(...) | 上記の現在値の読み取り | socketfilterfw --getblockall |
| setSharingServicesEnabled(_:) | SSH / SMB / 画面共有デーモンの unload / load。停止時に「元々起動していたもの」だけを記録し、復帰時にそれだけを戻します | /bin/launchctl list / unload -w / load -w （対象は `ssh.plist` / `com.apple.smbd.plist` / `com.apple.screensharing.plist` の 3 つに固定） |
| enableNetworkAirGap(...) disableNetworkAirGap(...) | 緊急時の全遮断（`block drop all`）の適用・解除。`PFRulesetCoordinator` を経由します（§4） | /sbin/pfctl -f / -e / -sr |
| setGuardedDevServerPorts(_:) | 指定した開発サーバーポートへの**外部からの**接続だけを pf で遮断します（localhost は素通し）。空配列を渡すと全解除します | /sbin/pfctl（同じく Coordinator 経由） |
| setSecureDNSServers(_:) restoreOriginalDNSServers(...) getCurrentDNSServers(...) | アクティブなネットワークサービスの DNS を、マルウェア遮断 DNS（Quad9 `9.9.9.9` / Cloudflare `1.1.1.2`）へ切り替え、元の設定をバックアップして復元します | /usr/sbin/networksetup -listallnetworkservices / -getdnsservers / -setdnsservers |
| setLinkGuardSinkhole(_:) | リンク保護（§5）のフォールバック経路。渡されたフィッシング／詐欺ドメインを `/etc/hosts` の区切り付き管理セクションに `0.0.0.0` で書き込み、DNS キャッシュをフラッシュします。空配列でセクションを削除。ドメインは正規化・重複排除し、IP や不正な文字列は捨て、上限 6 万件でキャップします。書き込みは一時ファイル + アトミック置換 | /etc/hosts の書き換え（`FileManager.replaceItemAt`）／ /usr/bin/dscacheutil -flushcache ／ /usr/bin/killall -HUP mDNSResponder |
| publishLinkFilterState(feedPath:extra:allowlist:mode:sinkhole:) | リンク保護（§5、1.8.0〜）。コンテンツフィルタ システム拡張の作業セットを `/Library/Application Support/RoamSwitch/linkfilter/`（`0755`、ファイル `0644`）へ配信します。`feedPath` は `/Users/*/Library/Application Support/RoamSwitch/` 配下であることを検証してからコピー（XPC に本文を流さない）。`sinkhole` true なら同じ作業セットから `/etc/hosts` フォールバックも再構築します（70 万件規模のフィード全走査をアプリのメインアクターから外すため） | ファイルコピー・書き込み／ /etc/hosts 再構築（上記と同じ経路） |
| tailscaleReconcile(exitNode:tunnelInterface:engage:) | VPN トンネルの Tailscale バックエンド（§5、1.8.0〜）。`engage` true でキルスイッチ設置 → `tailscale set --exit-node=<ノード>`。false で Exit Node クリア + キルスイッチ撤去（`tailscale down` はしません）。`exit-node` 引数は英数・`.`・`-`・`:` のみ許可 | `tailscale set`（CLI）／ /sbin/pfctl（`PFRulesetCoordinator` 経由、§4） |
| lockGatewayARP(_:) unlockGatewayARP(...) getGatewayARPLockStatus(...) | 予防的ゲートウェイ ARP/NDP 固定（§5）。渡された `IP → MAC` の対応（IPv4 ゲートウェイ・IPv6 デフォルトルーター・同一リンク上の DNS リゾルバ）を `permanent` エントリとして近隣キャッシュに固定します。IP・MAC の形式を検証し、要求に無いピンは解除する reconcile 方式。ピン集合は `gateway_arp_lock.json` に永続化し XPC 再接続をまたいで解除できます | /usr/sbin/arp -s / -d ／ /usr/sbin/ndp -s / -d |
| wireGuardImport(_:) wireGuardForget(...) | VPN トンネル（§5）。WireGuard の `.conf` テキストをヘルパーが `0600` で保存 / 削除します | ファイル書き込みのみ |
| wireGuardUp(endpointIPv4:endpointIPv6:port:) wireGuardDown(...) wireGuardStatus(...) | トンネルの起動 / 停止 / 状態取得。エンドポイントのホスト名は**アプリ側で解決**して IP をヘルパーに渡します（ヘルパーの DNS はキルスイッチで切れ得るため） | Homebrew の `wg-quick up/down` ／ `wg show`（`wireguard-tools`。未導入時は無効） |
| terminateProcess(pid:forceKill:) | プロセスの一時停止（SIGSTOP）または強制終了（SIGKILL）。ランサムウェア様プロセスの封じ込めに使います。`pid > 1` のみ | kill(2) システムコール（サブプロセスではありません） |
| tailscaleKillSwitchActive(...) | Tailscale キルスイッチ（`pf`）が現在ロードされているかを返します | — |
| getHelperVersion(...) | ヘルパーのバージョン文字列を返します（アプリとの互換性確認に使います。現行 1.8.0） | — |

> **設計上のトレードオフ**
>
> `terminateProcess` は、`pid > 1` でさえあれば、どのプロセスにも `SIGKILL` を送れます。`setSecureDNSServers` には、任意の DNS サーバー文字列を 渡せます。機能を成立させるうえで必要な広さではありますが、狭いとは言えません。手前にあるコード署名 チェック（`ClientValidator`）が唯一の関門です。この点を踏まえて判断してください。

### ヘルパー内部の状態

- `HelperTool.shared` は、接続をまたいで共有する 1 つのインスタンスにしています。以前は接続ごとに別インスタンスを渡していたため、緊急封じ込めが新しい接続を開くと、「どのサービスを元に戻せばよいか」という記録を取りこぼすレースが発生していました。
- 共有サービスと DNS のバックアップは、直列キュー（`stateQueue`）の上でのみ書き換わります。

## §4. パケットフィルタ（pf）の扱い

pf を操作する機能は 4 つあります。緊急 Air-Gap、開発サーバーのポートガード、VPN トンネルの WireGuard キルスイッチ（§5、1.7.6 以降）、VPN トンネルの Tailscale キルスイッチ（§5、1.8.0 以降）です。いずれも **`PFRulesetCoordinator` という 1 つの窓口**を必ず経由し、自分で `pfctl -f` を実行することはありません。WireGuard と Tailscale のキルスイッチは同時には立ちません（選ばれたバックエンドの分だけ）。

### なぜ窓口を 1 つにしたか

以前は、2 つの機能がそれぞれ独自に `pfctl -f` でルールを読み込んでおり、pf に 1 つしかない メインルールセットを奪い合っていました。ポートガードの狭いルール `block ... port {…}` が、 Air-Gap の `block drop all` よりあとに読み込まれると、画面には「隔離中」と表示されているのに Mac には到達できてしまう、という状態が発生していました。この不具合は、別のマシンから実際に攻撃を試して 発見し、1.4.3 で修正しています（経緯は `docs/marketing/zenn/03_lan_side_attack_test.md` に まとめています）。

### いまの作り

- **毎回、丸ごと組み直します。**現在の状態から、必要なルールセット全体を作り直し、一括で適用します。差分での適用は行いません。
- **直列キューは 1 本です。**pf を変更する処理はすべて同じ `DispatchQueue` に乗るため、どの XPC 接続から来ても、ヘルパーの起動処理でも、フェイルセーフタイマーでも、順番に処理されます。
- **優先順位は次のとおりです（上にあるものが優先されます）。** 緊急 Air-Gap → `set skip on lo0` と `block drop all`（ほかは考慮しません）
- VPN キルスイッチ（WireGuard）→ `block drop all` ＋ 「`lo` / トンネル インターフェース（`utunN`）／ 固定したエンドポイント IP への UDP ハンドシェイク ／ DHCP ／ ICMP」だけを `pass quick` で通す
- VPN キルスイッチ（Tailscale）→ `block drop all` ＋ 「`lo` / Tailscale の `utunN` / CGNAT `100.64.0.0/10`・`fd7a:115c:a1e0::/48` / DNS（`udp`/`tcp` port 53） / STUN `udp/3478` / `udp/41641` / DERP `tcp/443` / DHCP / ICMP」だけを `pass quick` で通す（WireGuard より広め、理由は §5）
- 開発サーバーガード → `block drop in quick proto tcp ... port { … }`
- どれもない場合 → `/etc/pf.conf` を読み直し、pf を元の状態に戻します
- **適用したあとに読み返します。**`pfctl -sr` でルールを読み戻し、`block drop all` や各ポートのルールが実際に載っているかを確認します。`pfctl -f` が黙って無視された場合を「成功」とは扱いません。
- **一時ファイルは `UUID` を含むパスに書き込み、適用が終わったら削除します**（v1.4.5 で固定パスをやめ、推測しにくいパスに変更しました）。状態を保存するディレクトリは `/Library/Application Support/RoamSwitch` です。

> **API の挙動**
>
> `enableNetworkAirGap` と `setGuardedDevServerPorts` の XPC 応答 `(Bool, String?)` は、読み返しまで通過したかどうかを返します。呼び出し側 （`ARPSpoofContainmentManager` など）は、失敗した場合はやり直し、それでも駄目な場合は 「まだ通信は止まっていません。すぐに Wi-Fi を切ってください」という内容を、そのまま画面に表示します。

## §5. 遮断のかかり方と、戻り方

### 遮断は、それぞれ別物です

**遮断の種類**

| 種類 | 範囲 | 発動条件 | loopback |
| --- | --- | --- | --- |
| 緊急 Air-Gap | 入る通信も出る通信も、すべて止めます | ランサムウェアのような暗号化の動きを検知したとき。ARP スプーフィング検知時はロックダウン中のみ即時発動し、バランス／信頼済みネットワークでは通知のみ（ユーザーが手動で発動）。**ふだんの外出先保護では使いません** | `set skip on lo0` で通します |
| VPN キルスイッチ | トンネルとハンドシェイク・DHCP・ICMP 以外の全通信 | VPN トンネル（§5、Pro・既定オフ）が有効で、未信頼ネットワークに接続したとき。トンネル確立まで（および切断時）継続 | `set skip on lo0` で通します |
| 開発サーバーポートガード | 指定ポートへの、**外からの** TCP 接続だけ | ボタン 1 つでの手動隔離、または、見慣れない待ち受けポートを検知したときの自動遮断（Pro） | localhost からは、今までどおりです |
| ふだんの未信頼ネットワーク保護 | ファイアウォールとステルス、共有の停止（§6）。pf は使いません | 登録していないネットワークに接続したとき | — |
| リンク保護（拡張、1.8.0〜） | フィッシング／詐欺ドメインへの外向き TCP フローだけ（`NEFilterDataProvider` が `.drop()`）。名前は OS 解決名または TLS SNI から得るため DoH／DoT も対象。`block` 時は QUIC も遮断。pf は使いません | 脅威フィード掲載またはブランド ホモグラフ偽装に該当する接続先。既定でオン（Pro） | 影響しません |
| リンク保護（`/etc/hosts` フォールバック） | 拡張が未承認・拒否のときだけ。名前解決だけ（`/etc/hosts` で `0.0.0.0`）。pf は使いません | 同上。上限 6 万件 | 影響しません |
| 予防的 ARP/NDP 固定 | ゲートウェイ・IPv6 ルーター・同一リンク上 DNS の MAC のみ（近隣キャッシュ）。pf は使いません | 未信頼ネットワークに接続したとき（Pro・既定オフ）。ネットワーク変更ごとに再固定 | 影響しません |

### Air-Gap を居座らせない仕組み

- **最長でも 10 分で解除されます。**ヘルパーは、起動直後と 60 秒ごとのタイマーで `releaseAirGapIfExpired()` を実行し、`/Library/Application Support/RoamSwitch/pf_airgap_since` のタイムスタンプが 10 分を超えていれば、強制的に解除します。アプリがクラッシュしたり強制終了されたりして、解除ボタンに到達しなかった場合でも、通信は自動的に元に戻ります。
- **再起動やデーモンの再生成のあとに、当て直します。**ヘルパーは起動時に `reapplyFromDisk()` でディスク上の状態を読み込み、Air-Gap、ポートガード、システム既定の順に、自分で復元します（このときも 10 分ルールは適用されます）。
- **解除に失敗した場合は、失敗として扱います。**`block drop all` を実際に外せなかったときは、タイムスタンプを書き戻し、フェイルセーフタイマーと再試行が向かう先を残します。画面が「解除済み」と誤って表示することはありません。
- ユーザーは、モーダルの解除ボタンからでも、単に Wi-Fi を切ることでも、いつでも操作の主導権を取り戻せます。

### ポートガードの誤検知からの戻し方

未知ポートの自動遮断（Pro、Pro 有効化時に既定でオン）が、正規の LAN 受信アプリ（LocalSend や Syncthing など、ガードを有効にしたあとに起動したもの）を止めてしまうことがあります。そのときは、通知バナーの「許可する」ボタン、または「外部公開ポート」画面の該当項目から解除できます。一度許可した実行体は既知として記録され、以降は再び遮断されません（`PortAnomalyGuard.allowPort(_:)`）。`anchor apple` を満たす macOS 標準のシステムデーモン（Handoff の `rapportd` など）は、そもそも監視対象に入りません。なお、Python や Node.js、Netcat などの汎用インタプリタは、Living-off-the-land 攻撃を防止するためバイナリ単体ではなく「実行パス＋ポート番号」で厳格に識別されます。

### ランサムウェアおとり（カナリア）の自律復元と隔離中制御

カナリアファイル（おとり）が改ざん・リネームされて緊急 Air-Gap が発動した場合、安全を確認して隔離を解除すると、破損・消失したカナリアファイルは自動的にアプリ内の正規テンプレートから再生成・ハッシュ修復され、kqueue リアルタイム監視が途切れることなく即座に再開されます（攻撃者による改変データが新ベースラインとして誤認されることはありません）。また、緊急隔離発動中（モーダル表示中）は定期整合性ポーリングからの多重発火および重複通知を自動抑止し、ユーザーの確認・対処を妨げない設計としています。

### ClamAV 検疫の完全性と衝突回避（フォールバック隔離）

ダウンロードフォルダやデスクトップ、書類フォルダに新規配置されたファイルは、`.tmp` 拡張子や `com.apple.quarantine` 属性の有無（ターミナル経由のコピー等）に関わらず即座に ClamAV スキャン対象となります。また、隔離先フォルダ（`Quarantine`）に過去に隔離された同名ファイルが既に存在する場合でも、ClamAV の移動スキップを自動検知してタイムスタンプ付きのユニーク名で隔離フォルダへ確実に退避・強制移動し、脅威が元の場所に残存する検疫漏れを完全に排除します。

### リンク保護（フィッシング接続の遮断） — 1.7.2 以降、1.8.0 で強化

メニューバー →「マルウェア対策」→「リンク保護」（Pro）。フィッシング／詐欺サイトへの接続を、ブラウザやアプリを問わず端末側で遮断します。

**強制ポイントは 2 つあり、優先順に併用します。**

1. **コンテンツフィルタ システム拡張（`RoamSwitchLinkFilter`、1.8.0〜、承認後に優先）。**`NEFilterDataProvider` の system extension です。**Apple の申請は不要**——コンテンツフィルタ プロバイダは 2016 年からセルフサービスで、審査キューはありません（監視対象デバイス限定という制約は iOS 側だけの話）。Developer ID 署名 + notarization 済みで、一般の Mac で動きます。初回のみシステム設定での承認が要ります。
   - 名前解決の**後**に、実際の外向き TCP フローを見ます。宛先の名前は (a) OS が解決した `remoteHostname`、無ければ (b) 外向き最初のバイト列から **TLS ClientHello の SNI** をパースして得ます。(b) があるので、ブラウザが自前で DoH／DoT 解決して生 IP に繋ぐケースも遮断できます。
   - `block` 時はフローを `.drop()`。`warn` 時は通します（下記）。QUIC（UDP/443）は ClientHello が暗号化されていて SNI を読めないため、`block` モードでは drop してブラウザを HTTP/2（TCP）にフォールバックさせます。
   - `/etc/hosts` は書き換えません。プロセス単位の帰属が取れます。
   - フィルタの作業セット（フィード／ユーザー追加ブロック／許可リスト／モード）は、ヘルパーが `/Library/Application Support/RoamSwitch/linkfilter/` に配信します（root 所有・誰でも読める。拡張は root で動き `~/Library` を読めないため）。フィード本文は XPC で流さず、パスを渡してヘルパーがコピーします（本文は 70 万件規模になり得るため）。
2. **`/etc/hosts` シンクホール（フォールバック、拡張が未承認・拒否のとき）。**特権ヘルパーが `/etc/hosts` の区切り付き管理セクションに対象ドメインを `0.0.0.0` で書き込み、`dscacheutil -flushcache` と `killall -HUP mDNSResponder` でキャッシュを流します。名前解決の段階で落ちます。区切りマーカーの外にある行には触れません。上限 6 万件（フィードはそれより大きい場合があり、先頭 6 万件が入ります）。

拡張が有効になると `/etc/hosts` の管理セクションは撤去され、以降は拡張が担当します。判定エンジン（フィード照合 + ホモグラフ検知）と署名付きフィードは両経路・Linux 版と共通です。

- **3 モード。**「オフ」＝無効。「警告のみ（遮断しない）」＝フィードは読み込み、該当接続は**通す**が通知する（下記）。「明らかな詐欺サイトは自動でブロック（推奨）」＝遮断。**1.7.2 以降の既定はブロック**。
- **実 `warn`（1.8.0〜）。**拡張は `block`／`warn` の判定を `/Library/Application Support/RoamSwitch/linkfilter/events.log` に追記し（ホスト単位 1 時間デデュープ）、アプリがこれを追尾して通知を出します——`warn` は「〜はブランド偽装／詐欺サイトの疑い（接続は許可）」＋「常にブロック」ボタン、`block` は「〜をブロックしました」＋「今回は許可（5 分）」ボタン。
- **遮断は明確なケースだけ。**「脅威フィード掲載」または「ブランド名の Unicode ホモグラフ偽装」に該当するときだけブロックし、それ以外（高リスク TLD、サブドメイン偽装など）は警告に留めます。判定エンジンは Linux 版と共通で、URL をどこにも送りません。
- **誤遮断からの戻し方。**通知またはメニューからドメインを「許可」（5 分間 or 恒久）。許可リストはセクション再生成時に差し引かれます。
- **Pro ゲート。**遮断の適用（`applyMode()`）は Pro ライセンスが有効なときだけ行われます。非 Pro ではモード設定は保存されますが `/etc/hosts` は一切変更されません。ライセンスの有効化・失効はセッション中でも反映されます。
- **フィードと同梱シード。**ブロック対象の一覧は署名付きの脅威フィード（§7、フィード専用鍵で検証）由来です。未取得でもアプリ同梱のシード（約 6 万件）で動作し、「自動更新」をオフにすると外部通信は発生しません。

### 予防的ゲートウェイ ARP/NDP 固定 — 1.7.5 以降

メニューバー →「ポート・デバイス監視」→「未信頼ネットワークでゲートウェイの ARP/NDP を固定（予防）」（Pro・既定オフ）。

- **仕組み。**未信頼ネットワークに接続した時点で、`route` / `scutil --dns` / `arp -n` / `ndp -an` から IPv4 ゲートウェイ・IPv6 デフォルトルーター・同一リンク上の DNS リゾルバの現在の MAC を収集し、ヘルパーが `arp -s` / `ndp -s` で `permanent` エントリとして固定します（TOFU＝最初に観測した MAC を信頼）。以降その IP に対する ARP/NDP スプーフィング応答は無視され、中間者攻撃を**未然に**防ぎます。
- **範囲。**固定するのは上記 3 種のエントリだけです。信頼済み（オープン）ネットワークでは固定しません。ネットワークが変わるたびに一度解除して再固定します。off-link のパブリック リゾルバ（8.8.8.8 等）は同一リンクに ARP エントリが無いため自動的に対象外になります。
- **`arp -s` は予防、Air-Gap は事後。**この固定は「なりすましを成立させない」ための予防策で、ARP スプーフィング検知（`ARPSpoofContainmentManager`）と緊急 Air-Gap は「検知したら人間より速く切る」ための事後策です。両者は独立して動きます。
- **永続化。**ピン集合は `/Library/Application Support/RoamSwitch/gateway_arp_lock.json` に保存され、XPC 再接続やヘルパー再起動をまたいで解除できます。

### VPN トンネル（WireGuard／Tailscale）とキルスイッチ — 1.7.6 以降、1.8.0 でバックエンド選択

メニューバー →「ポート・デバイス監視」→「VPN トンネル」（Pro・既定オフ）。L2（ARP/NDP）の完全性に依存しない、中間者攻撃対策の**本命**です。**バックエンドは「WireGuard（設定ファイル）」または「Tailscale（Exit Node）」から選べます**（サブメニュー →「バックエンド」）。RoamSwitch 自身は暗号処理を実装せず、既存の VPN／tailnet に相乗りします。選ばれた方だけを arm し、他方は stand down します。

**共通の動き。**未信頼ネットワーク（保護レベルが「信頼（オープン）」以外）に接続するとトンネル／Exit Node を起動し、信頼済みネットワークに戻すと停止します。Pro ライセンスが失効すると解除されます。

**(A) WireGuard バックエンド。**Apple の Network Extension エンタイトルメントは使わず、Homebrew の `wireguard-tools`（`wg-quick` + `wireguard-go`）を呼び出します（`blueutil` と同じ「Homebrew 経由の任意 CLI」モデル。未導入なら機能は無効）。ユーザーが自分の WireGuard 設定（`.conf`）を読み込むと、ヘルパーが `0600` で保存します。

- **キルスイッチ。**トンネルが確立するまで（および切断時）、pf の `block drop all` に「`lo` ／ トンネル インターフェース ／ 固定したエンドポイント IP への UDP ハンドシェイク ／ DHCP ／ ICMP」だけの `pass quick` を足した状態にします。ARP/NDP スプーフィングやパケット盗聴があっても平文は漏れません。エンドポイントのホスト名は**アプリ側で解決**して IP をヘルパーに渡します（キルスイッチ中はヘルパーの DNS が通らないため）。
- **スプリット トンネル警告。**`AllowedIPs` が `0.0.0.0/0, ::/0` でない設定を読み込んだ場合、一部の通信がトンネル外に出る旨を警告します。

**(B) Tailscale バックエンド（1.8.0〜）。**既に Tailscale を使っているユーザー向け。RoamSwitch は `tailscale up`／ログイン／`tailscaled` の導入は**行いません**——`tailscale status --json` を読み、ヘルパー経由で `tailscale set --exit-node=<ノード>`／`--exit-node=`（解除）を実行するだけです（CLI は `/usr/local/bin`、Homebrew、Tailscale.app を探索。`--exit-node` 引数は英数・`.`・`-`・`:` のみ許可）。

- **Exit Node 必須。**中間者攻撃対策は「全通信を経由させる Exit Node」の指定で成立します。Exit Node を選んでいなければ機能は arm しません。選択した Exit Node がオフラインになった場合は自動で解除し通知します（死んだノードに全通信を流して黒穴にするより「未保護」の方がマシ）。
- **有効化の順序。**まず `tailscale set --exit-node=<ノード>` を実行し、`tailscale status` で実際にそのノードが Exit Node として有効になるのを最大 12 秒待ってから、キルスイッチを張ります。Exit Node が有効にならなければキルスイッチは張らず、通知して撤退します（先にキルスイッチを張ると Tailscale 自身の control／DERP 接続が切れて `tailscaled` が停止するため）。
- **キルスイッチ（`pf`、`block drop all`）。**WireGuard より許可範囲は広めです。Tailscale のトランスポートは単一エンドポイント IP に固定できない（ローミングするピアへの直結 UDP ＋ DERP リレーの TCP 443／UDP 3478）ためです。許可するのは：Tailscale の tun（`utunN`。macOS では動的なので、arm 時に `100.64.0.0/10` を持つ IF を `ifconfig` から特定）、CGNAT レンジ `100.64.0.0/10` と `fd7a:115c:a1e0::/48`、**DNS（`udp`/`tcp` port 53。`tailscaled` が control／DERP のホスト名を解決できないと停止するため）**、STUN `udp/3478`、Tailscale 直結 `udp/41641`、DERP `tcp/443`、DHCP、ICMP。**それ以外（SMB、mDNS、平文 HTTP、任意 TCP）は全遮断**します。DNS を許可するぶん WireGuard キルスイッチより「漏れにくい」止まりで「漏れない」ではありません。
- **既知の限界（キルスイッチ）。**同一 L2 上の観測者は「Tailscale 利用の事実、DERP リージョン、タイミング」を推定でき、遮断・遅延も可能です——ただしトンネル内容は読めません。直結 UDP を塞がれた環境では Tailscale は DERP（TCP/443）へフォールバックします。
- Exit Node を経由する通信の宛先・内容はユーザーの tailnet と選んだ Exit Node の管理下にあり、lafine とは無関係です。

## §6. ふだんの未信頼ネットワーク保護

登録していないネットワークに接続したときの「保護レベル」の切り替えは、pf ではなく、OS 標準の設定を、 あとで元に戻せる形で変更しているだけです。

**保護レベルごとの操作**

| 操作 | 実装 | 権限 | 復元方法 |
| --- | --- | --- | --- |
| ファイアウォール + ステルスモード ON | socketfilterfw --setblockall on / --setstealthmode on | root（ヘルパー） | 安全なネットワークに復帰したときに `off` |
| SSH / SMB / 画面共有の停止 | launchctl unload -w | root（ヘルパー） | **停止時に起動していたものだけ**を記録し、復帰時に `load -w`（SSH は `/usr/sbin/systemsetup -setremotelogin on` も連携実行して確実に復元） |
| AirDrop を無効化 | defaults write com.apple.sharingd DiscoverableMode | ユーザー（アプリ本体） | 直前の値を保存しておき、復帰時に書き戻す |

いずれも、RoamSwitch が新しく追加した遮断のしくみではなく、OS の設定を切り替えているだけです。 アプリを削除すると、ネットワークに応じた切り替えが行われなくなるだけで、最後に適用された OS 設定は そのまま残ります。締まったまま放置されることはありませんが、安全側に倒したい場合は、アンインストールの 前に、信頼できるネットワーク上で「オープン」に戻しておくことをおすすめします。

## §7. データの扱いと Zero Telemetry

### Mac の中に残るもの

**ディスクに保存されるデータ**

| データ | 場所 | 内容 |
| --- | --- | --- |
| ライセンストークン | Keychain com.tetsuharu.RoamSwitch.license | Ed25519 署名付きトークン。`kSecAttrAccessibleAfterFirstUnlock` |
| アプリ設定 / ガードの ON-OFF | UserDefaults suite com.tetsuharu.RoamSwitch | 信頼ネットワークの登録、保護ポリシー、除外リストなど |
| pf 状態 | /Library/Application Support/RoamSwitch/ | Air-Gap のタイムスタンプ、ガード対象ポートの JSON、VPN キルスイッチ状態、適用中ルールの一時ファイル |
| リンク保護の脅威フィード | ~/Library/Application Support/RoamSwitch/threatfeed/feed.txt | ダウンロード済みのフィッシング／詐欺ドメイン一覧（未取得ならアプリ同梱のシードを使用）。フィード版数は UserDefaults |
| リンク保護の管理セクション | /etc/hosts | `# BEGIN RoamSwitch link guard` 〜 `# END` で囲まれた区切り付きセクション。ブロック対象を `0.0.0.0` で無効化。モード「オフ」・拡張が有効なとき・非 Pro のとき削除されます（§5） |
| リンク保護 拡張の作業セット（1.8.0〜） | /Library/Application Support/RoamSwitch/linkfilter/{feed.txt, extra.txt, allowlist.txt, mode, events.log} | コンテンツフィルタ拡張が読むフィード／ユーザー追加ブロック／許可リスト／モードと、拡張が書き通知の元になる判定ログ。root 所有・誰でも読める（秘密は含まない）。ヘルパーが配信 |
| VPN バックエンド選択・Tailscale Exit Node（1.8.0〜） | UserDefaults | `RoamSwitch.VPNBackend`（`wireguard`／`tailscale`）、`RoamSwitch.VPNTailscaleExitNode`（選んだ Exit Node の DNS 名、空＝なし） |
| Tailscale キルスイッチ状態（1.8.0〜） | /Library/Application Support/RoamSwitch/pf_tailscale_killswitch.json | arm 中に特定した Tailscale の tun インターフェース名 |
| ARP/NDP 固定ピン | /Library/Application Support/RoamSwitch/gateway_arp_lock.json | 予防ロック（§5）で `permanent` 化した `IP → MAC` の集合。固定解除時に削除 |
| WireGuard 設定 | /Library/Application Support/RoamSwitch/（ヘルパー領域、`0600`） | ユーザーが読み込んだ `.conf` の内容。エンドポイントのホスト名は UserDefaults にも退避（アプリ側で解決するため） |
| デバイスフォールバック UUID | UserDefaults | IOKit が UUID を返さないときにのみ生成される乱数（§9） |
| ログ | os.Logger / NSLog | 統合ログ。外部への送信はありません |

### 外に出る通信（全リスト）

診断結果、ポート情報、URL、ログを収集して送信するコードは、どこにもありません。解析 SDK も クラッシュレポーター SDK も入れていません。外部ライブラリは Sparkle（アップデート）だけです。 ネットワークに出るのは、次の 6 つですべてです（6 つ目はユーザーが VPN を設定した場合のみ）。

**RoamSwitch が行う外部通信**

| 通信 | 宛先 | 発生条件 | 送信内容 |
| --- | --- | --- | --- |
| ライセンス認証 / 解除 | lafine.net /api/v1/license/* | ユーザーがライセンスキーを入力したとき、または Pro を解除したときだけ | ライセンスキー、デバイスハッシュ、ホスト名、アプリバージョン。個人情報は購入時に Stripe が扱い、アプリは扱いません |
| アップデート確認 | lafine.net /updates/appcast.xml | Sparkle が 24 時間ごと、および起動時に実施 | HTTP リクエスト（標準的な UA・バージョン）。取得物は EdDSA 署名で検証します（§10） |
| リンク保護の脅威フィード | lafine.net /updates/v1/{manifest, feed/&lt;版&gt;.txt} | リンク保護（§5）が有効で「自動更新」がオンのとき、24 時間ごと（＋起動時）。「自動更新」オフでこの経路は消えます | `GET` のみ。クエリ文字列・Cookie・端末を識別する情報はありません。**受信専用**の署名付き静的ファイルです。マニフェストとフィード本体を Ed25519 で検証します。署名鍵は**フィード専用**で、アプリ更新の `SUPublicEDKey` とは**別鍵**です（漏洩時の影響を「誤ったブロックリスト」に閉じ込めるため） |
| ClamAV ウイルス定義更新 | ClamAV 公式ミラー | ユーザーが ClamAV を導入し、スキャン機能を使うときだけ。`freshclam` を起動します | ClamAV 標準の定義取得。RoamSwitch 由来の情報は含みません |
| VPN トンネル（§5、WireGuard バックエンド） | ユーザーが設定した WireGuard エンドポイント | VPN トンネル（Pro・既定オフ）で WireGuard を選び、未信頼ネットワークに接続したときだけ。トンネル起動前にエンドポイントのホスト名を 1 回 DNS 解決します | WireGuard のハンドシェイク（UDP）とトンネル内の通信。**宛先はユーザー自身の VPN サーバー**で、内容はユーザーの通信そのものです。RoamSwitch は識別子・診断結果を一切足しません |
| VPN トンネル（§5、Tailscale バックエンド、1.8.0〜） | ユーザーの tailnet と選んだ Exit Node、Tailscale の DERP リレー | VPN トンネルで Tailscale を選び Exit Node を指定し、未信頼ネットワークに接続したときだけ | Tailscale のトランスポート（直結 UDP／DERP over TCP 443）と Exit Node 経由の通信。制御は `tailscaled`（別プロセス）。**宛先はユーザーの tailnet／Exit Node** で lafine とは無関係。RoamSwitch は `tailscale status` を読み `--exit-node` を設定するだけ |
| 決済ページ | Stripe Checkout | ユーザーが購入ボタンを押したときだけ（ブラウザで開きます） | —（ブラウザ側の遷移です） |

> **「Zero Telemetry」の範囲**
>
> ここで言う「Zero Telemetry」は、利用状況や診断結果を収集して送信するテレメトリを行わない、という 意味です。通信を一切しない、という意味ではありません。上の表の 6 経路は、実際に存在します。ただし、 いずれもユーザーがきっかけをつくるものか、署名検証つきの**受信専用**の取得であり、Mac 上の診断結果、 ポート、URL、ファイルの中身が外に出ることはありません。
>
> リンク保護の脅威フィード（3 行目）は「送らない」防御に「受け取るだけの更新はする」を足したものです。両者は別の話として切り分けており、Linux 版ホワイトペーパー §1.1 でも「Zero Telemetry」と「受信専用の更新」を分けて記述しています。「自動更新」をオフにすれば、リンク保護は同梱データ（約 6 万件のフィッシング／詐欺ドメイン）とオフラインのホモグラフ検知だけで動作し、この経路は発生しません。
>
> VPN トンネル（5 行目）はユーザーが自分の WireGuard サーバーを設定した場合にのみ発生し、宛先も内容もユーザーの管理下にあります。RoamSwitch はトンネルを張る・キルスイッチを掛けるだけで、識別子や利用状況を足すことはありません。VPN を設定しなければこの経路は存在しません。
>
> アプリ内の「リンク安全性診断」シートは、短縮 URL の飛び先を確認するために、対象の URL へ `HEAD` リクエストを送信します（プライベートアドレスやローカルアドレスへの追跡は、v1.4.5 の SSRF 対策で停止しています）。一方、MCP の `audit_url_safety` は、その場で完結するオフライン 解析であり、URL をどこにも送信しません（§8）。

### 実測（2026-08-29）

主張だけではありません。2026-08-29、稼働中の 1.4.7 を `tcpdump` ＋ プロセス帰属（`nettop` / `lsof` / 絞り込んだ `pktap` キャプチャ）＋ LuLu で、約2時間、セキュリティレベルを最大ロックダウンに固定し appcast チェックを強制発火させた状態で監査しました。**結果：`RoamSwitch` / `RoamSwitchHelper` / `RoamSwitchMCPServer` に帰属する外向きは、`lafine.net` への appcast チェック以外なし。MCP サーバーが開いたソケットはローカルホストのみ。entitlements のダンプは空。** 詳細と追試可能なスクリプト：[`audit/RESULTS-2026-08-29.ja.md`](https://github.com/lafine1211/roamswitch-support/blob/main/audit/RESULTS-2026-08-29.ja.md)、[`audit/`](https://github.com/lafine1211/roamswitch-support/tree/main/audit)。`./audit/rs-zerotel-audit.sh all` で自分のマシンでも再現できます。

> この実測は 1.4.7 時点のもので、リンク保護の脅威フィード（1.7.2、上表 3 行目）と VPN トンネル（1.7.6、5 行目）はまだ存在しません。1.7.2 以降で監査すると `lafine.net` への**受信専用の `GET` が 2 種類**（appcast と脅威フィード）観測されます。VPN トンネルを設定していれば、ユーザー自身の WireGuard サーバー宛の UDP も観測されます（宛先・内容ともユーザーの管理下）。いずれも「自動更新: オフ」「VPN 未設定」で消えます。

> この実測は 1.4.7 時点のもので、リンク保護の脅威フィード（1.7.2 で追加、上表 3 行目）はまだ存在しません。1.7.2 以降で監査すると、`lafine.net` への **受信専用の `GET` が 2 種類**（appcast と脅威フィード）観測されます。どちらも署名検証つきで、送信内容はありません。フィードを止めるには「リンク保護」→「自動更新: オフ」。

## §8. MCP サーバーのセキュリティモデル

`RoamSwitchMCPServer` は、`RoamSwitch.app/Contents/MacOS/` に同梱している単体の コマンドラインツールです。Claude Desktop や Claude Code などの MCP クライアントが、これをサブプロセスと して起動し、**stdio（改行区切りの JSON-RPC 2.0）**でやり取りします。公式 SDK が本機の macOS SDK ではビルドできなかったため、Foundation の `JSONSerialization` の上に手で実装して います。

### 設計で縛っていること

- **読み取り専用です。**セキュリティレベルの変更、ポートの隔離、デバイスの取り出しといった API は、そもそも用意していません。v1 で作り忘れたわけではなく、意図的に外しています。外部のコード（ここでは LLM）に、セキュリティツールの防御状態を書き換えさせてしまうと、すべてのユーザーの信頼が崩れるためです。
- **ソケットを開きません。**サービス登録もリッスンもしません。stdin から 1 行読み、stdout に 1 行返し、あとはクライアントがプロセスを終了させます。
- **外に送信しません。**診断はすべて Mac の中で完結します。
- **設定は別のドメインから読み取ります。**`UserDefaults(suiteName: "com.tetsuharu.RoamSwitch")` で、アプリ側のドメインを明示的に指定して読み取ります（自身のバンドル ID のドメインは空です）。読み取るだけで、書き込みは行いません。

### 公開しているツール

**tools/list が返すツールと、返すデータ**

| ツール | 返すもの | 通信 |
| --- | --- | --- |
| get_security_report | 10 項目診断（FileVault / SIP / Gatekeeper / 自動更新 / XProtect / ファイアウォール / Wi-Fi 暗号化 / ARP / 公開ポート / ガード構成）のスコアと、項目別の改善アドバイス | ローカルのみ |
| get_exposed_ports | 待ち受け中の TCP ポート一覧。localhost を越えて公開されているものは、既知危険サービス DB と照合し、`127.0.0.1:port` への HTTP プローブ（ローカル閉域）で CORS / ヘッダを確認します | 127.0.0.1 へのプローブのみ |
| get_guard_status | Pro の自動対応ガード（ポート異常 / ARP / USB / Bluetooth / Web・Mail ダウンロード / DNS 脅威保護）の ON / OFF、現在の保護レベル、信頼ネットワーク状態 | ローカルのみ |
| audit_url_safety | URL のフィッシング / ホモグラフ（Unicode 偽装）/ ブランドサブドメイン偽装 / 高リスク TLD / 平文 HTTP の判定。**同期・完全オフライン**です（`analyzeURL`。リダイレクト追跡は行いません） | なし |
| get_app_help | 同梱ナレッジベースの全文検索（機能仕様 / 設定 / トラブルシュート / 通知メッセージ解説） | なし |

`initialize` の応答に含まれる `instructions` でも、「Cannot change security level, isolate ports, or eject devices」と明記し、クライアント側の LLM に能力の境界を伝えています。MCP リソース （`roamswitch://docs/*`）も、読み取り専用の Markdown ドキュメントです。

> **要点：ソースを公開**
>
> このサーバーと、そこから使う検知ロジック（ARP 監視・ポートスキャン・ポート診断・10 項目ヘルスチェック・ リンク安全性診断）のソースは、`github.com/lafine1211/roamswitch-mcp` で公開しています（MIT、 出荷コードのミラー、リリースごとにタグ）。「読み取り専用であること」「LLM に何を渡しているか」 「外部送信がないこと」をコードで直接確認できます。特権ヘルパー・pf 制御・実際に遮断する各ガード・ ライセンスは含みません（本体リポジトリのまま）。
>
> テストも同梱しています（本体スイートのミラー＋敵対的入力テスト＋ミューテーションファジング、 `swift test` で実行、CI で検証）。ファジングで `JSONSerialization` の未対策の クラッシュ（深くネストした JSON オブジェクトでのスタックオーバーフロー）を 1 件発見し、 パーサ前段のネスト深度チェックで修正しました（`SECURITY_TESTING.md` に記録）。

## §9. ライセンス認証の暗号設計

### トークン

- **Ed25519（Curve25519 署名）を使っています。**公開鍵はアプリに埋め込んでいます（`LicenseVerifier.embeddedPublicKeyBase64`）。対応する秘密鍵は、ライセンスバックエンド（Firebase Functions の環境変数）にのみ存在し、リポジトリには含まれていません。
- **署名の対象は正準 JSON です。**`JSONEncoder` の `.sortedKeys` と `.withoutEscapingSlashes` で `LicensePayload`（ライセンスキー、tier、デバイスハッシュ、発行時刻、有効期限、台数）をエンコードした、正確なバイト列に対して署名と検証を行います。
- **fail-closed で設計しています。**埋め込み鍵が欠落・不正であったり、署名や正準 JSON の生成に失敗したりした場合は、「検証成功」にはならず、`invalidSignature` を返します。

### デバイスバインド

```sh
device_hash = SHA-256( "RoamSwitch-LifetimeSalt-v1" : lowercase(IOPlatformUUID) )
```

生のハードウェア UUID は、サーバーに送信しません。IOKit が UUID を返さないまれなケースでは、 `UserDefaults` に保持する乱数 UUID にフォールバックします。検証時、トークン内の `device_hash` と現在のデバイスハッシュが一致しない場合は、`deviceMismatch` と なります。

### オフラインで動く

> **要点：サーバーが無くても動く**
>
> 起動時の `validateSavedLicense()` が行うのは、Keychain のトークンを読み込み、埋め込みの 公開鍵で手元で検証することだけです。ネットワークには接続しません。ライセンスサーバーが将来的に停止した 場合でも、すでに認証済みの Mac では、Pro 機能はそのまま使えます。サーバーと通信するのは、新規の アクティベーションと、明示的な解除のときだけです。解除のサーバーへの通知はベストエフォートで、失敗した 場合でも、手元の解除は必ず完了します。

既定は買い切り（Lifetime）で、`is_lifetime` でない場合にのみ `expires_at` を 確認します。台数は tier で表現し、個人 Pro が 2 台、Team が 5 台です。

## §10. 配布とアップデート

### 署名・公証（`scripts/release.sh`）

1. `xcodebuild archive` を実行します（Release、手動署名、Developer ID Application）。
2. `-exportArchive` で `method: developer-id` としてエクスポートします。
3. `notarytool submit --wait` のあと、.app に `stapler staple` します。
4. `spctl -a -t exec -vv` で検証します。
5. **staple のあとに再度 zip し**、Sparkle 用の配信物を作ります（公証チケットを同梱し、オフラインでも Gatekeeper の警告なしで動くようにするためです）。
6. DMG を作成し、DMG も公証・staple したうえで、`stapler validate` で検証します。

### アップデート（Sparkle 2.9.6）

**Info.plist のアップデート設定**

| キー | 値 |
| --- | --- |
| SUFeedURL | https://lafine.net/updates/appcast.xml |
| SUPublicEDKey | CNxzwijMzMCJzliId76Yl88S/9np6t/xg/zQ9YbYzHs= |
| SUEnableAutomaticChecks | true |
| SUScheduledCheckInterval | 86400 |

配信物は、appcast に記載された **EdDSA 署名**を、アプリに埋め込んだ `SUPublicEDKey` で検証してから適用します。署名用の秘密鍵は、ビルド環境にしかありません。appcast は HTTPS で配信します。 差分（delta）アップデートも、同じように署名を検証します。

> **要点：appcast は公開前提**
>
> `appcast.xml` の URL が公開されていること自体は、弱点ではありません。中身は、バージョン 番号、リリースノート、ダウンロード URL、ファイルサイズ、各ビルドの EdDSA 署名だけで、秘密は含まれて いません。信頼のよりどころは、「通信の途中で appcast が本物かどうか」ではなく、アプリに焼き込まれた 公開鍵で配信物の署名を検証すること、にあります。appcast を完全に差し替えられる攻撃者（MITM、DNS 乗っ取り、Web ホストの侵害）であっても、署名鍵がないかぎり、不正なアップデートを通すことはできません。 Gatekeeper（Developer ID と公証）が、2 つ目の関門になります。
>
> 残るリスクは 2 つあります。1 つは、ホストの停止や壊れた appcast による更新の不達です（不正な インストールは起きず、単に更新されないだけです）。もう 1 つは、セキュリティ更新を意図的に握りつぶす freeze 攻撃です。Sparkle 2 系は、バージョンの順序を確認してダウングレードやリプレイを弾きますが、 freeze への完全な対策には、有効期限つきの専用アップデートサーバーが必要です。ここは今後の検討課題と しています。

## §11. 脅威モデルと、やらないこと

### RoamSwitch が相手にするもの

- 同じ LAN にいる攻撃者や、乗っ取られた IoT 機器からの探査・攻撃。ステルス化、公開ポートの監査、外部からの隔離で対応します（実測検証: [`audit/RESULTS-DEFENSE-2026-08-30.ja.md`](../audit/RESULTS-DEFENSE-2026-08-30.ja.md) および最新ペネトレーションテスト実測記録 [`audit/RESULTS-PENTEST-2026-08-31.ja.md`](../audit/RESULTS-PENTEST-2026-08-31.ja.md) にて、ARPスプーフィング・未知ポート待受・ランサムウェアカナリア暗号化・ダウンロード検疫の全攻撃シナリオに対する自律遮断を実証済み）。
- 信頼していないネットワークでの露出。共有サービスと AirDrop を自動的に停止します。
- **中間者攻撃（ARP/NDP スプーフィング）**。1.7.6 以降は多層で対応します：（1）VPN トンネル + キルスイッチ（§5、本命。L2 の完全性に依存しない）、（2）未信頼ネットワークでのゲートウェイ ARP/NDP 予防固定（§5）、（3）スプーフィング検知と緊急 Air-Gap（事後）。いずれも Pro・既定オフ（検知は既定オン）。
- 認証なしで `0.0.0.0` に晒された開発サーバーやデータベース（Redis、MongoDB、Elasticsearch など）、およびローカルAI/LLM推論サーバー（Ollama、LM Studio、vLLM、Gradio など）を見つけ、外部から遮断します。
- ランサムウェアのような不正な暗号化の動きを早い段階で捉え、通信をすべて止めます（シグネチャには依存しません）。
- 未承認のキーボードや改造USBケーブル（Rubber Ducky / O.MG Cable等）からの自動コマンド注入を水際で遮断するBadUSB物理キーボード承認ガード（`USBKeyboardGuard`、CGEventTap + IOKit）。
- 許可していない USB ストレージの承認プロンプト（未知のドライブは即取り出しではなく読み取り専用で保留）と、接続されたストレージの自動 ClamAV スキャン（任意）。

### やらないと決めていること

- **アンチウイルスの代わりにはなりません。**ClamAV と XProtect は補助として使いますが、RoamSwitch 単体は、汎用のマルウェア検出器ではありません。
- **保証ではありません。**多層防御のうちの 1 層であって、「ランサムウェアを完全に防ぐ」ものではありません。マーケティングの文言も、この前提でレビューしています。
- **すでに乗っ取られた root やカーネルは守れません。**攻撃者がすでに root を取得している場合、ヘルパーの pf ルールも外せてしまいます。
- **L2 の完全性そのものを回復することはしません。**ARP/NDP 予防固定は「最初に観測した MAC を信頼する（TOFU）」方式で、接続前から攻撃者が居座っている場合は偽の MAC を固定し得ます。この前提を置きたくない場合の答えが VPN トンネル（§5）で、こちらは L2 が汚染されていても中身は暗号化されキルスイッチで平文が漏れません。企業ネットワークの DHCP スヌーピングや Dynamic ARP Inspection の代わりにはなりません。
- **VPN サーバーは提供しません。**トンネル機能はユーザーが用意した WireGuard 設定を使うもので、RoamSwitch が VPN 事業者になることはありません。

### RoamSwitch を入れることで増える攻撃面

**導入で増える攻撃面と、その抑え方**

| 攻撃面 | 抑え方 |
| --- | --- |
| root で動く LaunchDaemon と、その mach service（`com.tetsuharu.RoamSwitch.Helper`） | 操作面を `HelperProtocol` に固定しています（§3 の表）。任意コマンドを実行する口はありません。接続はコード署名要件で認可し、`audit_token` を使います。 |
| `RoamSwitch.app` 本体が侵害された場合、ヘルパーの全操作が攻撃者に渡ります | Hardened Runtime を有効にし、アプリ側に不要な権限を持たせません。ネットワーク送信は、上表の 6 経路（6 つ目はユーザーが設定した VPN のみ）に限定しています。今後、第三者レビューの対象にする予定です。 |
| ヘルパーが起動するシステムバイナリのパス | `/sbin/pfctl` などを絶対パスで直接指定し、`PATH` には依存しません。引数もハードコードしています（ポート番号・DNS 文字列・ARP の IP/MAC・VPN エンドポイント IP を除く。いずれも形式を検証します）。 |
| リンク保護が `/etc/hosts` を書き換える（`setLinkGuardSinkhole`） | 書き込みは区切り付きの管理セクション内に限定し、セクション外の行はそのまま保持します。ドメインは正規化・検証し、IP や不正文字列は捨て、6 万件でキャップ、一時ファイル + アトミック置換で書きます。適用するのは「脅威フィード掲載」または「ブランド名のホモグラフ偽装」の明確なケースだけで、判定エンジンはローカル完結です。ブロックリスト自体は署名検証済みのフィード（フィード専用鍵）に由来します。 |
| リンク保護の脅威フィード取得（受信専用の日次 `GET`） | クエリ・識別子なしの静的ファイル取得のみ。マニフェスト・フィード本体とも Ed25519 で検証し、検証に失敗した取得物は破棄します（無署名データにフォールバックしません）。「自動更新: オフ」でこの経路自体が消えます。 |
| ARP/NDP 予防固定（`lockGatewayARP`） | 固定するのは「ゲートウェイ・IPv6 ルーター・同一リンク上 DNS」の近隣キャッシュ エントリだけ。渡された IP・MAC は形式を検証し、要求集合との reconcile 方式（勝手にエントリを増やさない）。未信頼ネットワークでのみ動作し、Pro・既定オフ。TOFU の限界は §11「やらないと決めていること」に明記。 |
| VPN トンネル（`wireGuardImport/Up/…`、Homebrew `wireguard-tools`） | `.conf` はヘルパーが `0600` で保存。エンドポイント IP はアプリ側で解決してヘルパーに渡す（ヘルパーに任意ホスト名の名前解決をさせない）。トンネルの宛先・内容はユーザー管理下。`wireguard-tools` 未導入なら機能は無効。Pro・既定オフ。キルスイッチは `PFRulesetCoordinator`（§4）を経由。 |
| MCP サーバーが LLM にシステム状態を渡すこと（confused deputy） | 読み取り専用で、書き込み API は実装していません。URL 診断はオフラインです。設定ドメインは read-only で参照します。 |
| アップデート経路の乗っ取り | EdDSA 署名検証（`SUPublicEDKey`）と、公証チケットの同梱で対応します。appcast は HTTPS です。 |

## 付録 A. セルフチェック

本書に記載した内容は、配布物に対して次のコマンドで確認できます。

### 署名・公証

```sh
# Developer ID 署名とチーム ID
codesign -dvvv /Applications/RoamSwitch.app 2>&1 | grep -E 'Authority|TeamIdentifier|flags'

# 公証チケットが staple されているか
stapler validate /Applications/RoamSwitch.app
spctl -a -t exec -vvv /Applications/RoamSwitch.app

# 同梱ヘルパー / MCP サーバーの署名
codesign -dvvv /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchHelper
codesign -dvvv /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
```

### Entitlements（ネットワーク送信権限が無いこと）

```sh
codesign -d --entitlements :- /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchHelper
codesign -d --entitlements :- /Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
# → 空の entitlements 辞書。app-sandbox / network client のキーはありません
```

### 通信の実測

```sh
# Little Snitch / tcpdump を併走させ、通常利用で通信が出ないことを確認します
sudo tcpdump -i any -n 'host not 127.0.0.1' and 'not port 53'
# ライセンス認証・アップデート確認・ClamAV 更新以外のトラフィックが無いこと
```

### 特権ヘルパーの実体

```sh
# 登録されている LaunchDaemon
sudo launchctl print system/com.tetsuharu.RoamSwitch.Helper

# 現在ロードされている pf ルール（Air-Gap / ポートガードの実状）
sudo pfctl -sr

# ヘルパーの状態ディレクトリ
ls -la "/Library/Application Support/RoamSwitch/"

# リンク保護 コンテンツフィルタ拡張の状態（1.8.0〜）
systemextensionsctl list | grep -i roamswitch          # activated enabled になっているか
ls -la "/Library/Application Support/RoamSwitch/linkfilter/"   # 作業セット（秘密は含まない）

# フィルタが効いているか（フィード掲載ドメインへ system DNS と DoH の両方で）
D=$(grep -m1 -E '\.(com|net|dev)$' "/Library/Application Support/RoamSwitch/linkfilter/feed.txt")
curl -sS -m 8 -o /dev/null -w '%{http_code}\n' "https://$D/"                         # 接続失敗
curl -sS -m 8 --doh-url https://cloudflare-dns.com/dns-query -o /dev/null "https://$D/" # 接続失敗（SNI 経路）
```

### MCP サーバーの応答（オフライン確認）

```sh
BIN=/Applications/RoamSwitch.app/Contents/MacOS/RoamSwitchMCPServer
printf '%s\n' '{"jsonrpc":"2.0","id":1,"method":"initialize","params":{}}' \
              '{"jsonrpc":"2.0","id":2,"method":"tools/list"}' | "$BIN"
# serverInfo と 5 ツールの定義が返ります。ネットワーク接続は発生しません
```

### MCP サーバーのソースとテスト

```sh
git clone https://github.com/lafine1211/roamswitch-mcp
cd roamswitch-mcp
swift build -c release        # 出荷バイナリと同じソース
swift test                    # 単体・敵対的入力・stdio・ミューテーションファジング
# SECURITY_TESTING.md にテスト内容と発見済みの問題
```

### デバイス識別子

```sh
# トークンにバインドされる素の値（送信されるのは salted SHA-256 のみ）
ioreg -d2 -c IOPlatformExpertDevice | awk -F'"' '/IOPlatformUUID/{print $4}'
```

### DNS 脅威保護（Quad9 悪質ドメイン・C2 遮断）の動作確認

```sh
# Quad9 公式の脅威ブロック検証用テストドメインを問い合わせ
nslookup test.dns9.quad9.net
# → ** server can't find test.dns9.quad9.net: NXDOMAIN となり名前解決が遮断されること
```

### ダウンロード保護（ClamAV リアルタイム検知 & 隔離）の動作確認

```sh
# 無害なアンチウイルス標準テスト文字列（EICAR）を Downloads に作成
echo 'X5O!P%@AP[4\PZX54(P^)7CC)7}$EICAR-STANDARD-ANTIVIRUS-TEST-FILE!$H+H*' > ~/Downloads/eicar_test.com
# → FSEvents 検知により ClamAV が即時スキャンし、隔離マネージャーへ退避 & 警告通知が発火すること
```

### リンク保護（フィッシング接続の遮断）の動作確認

```sh
# 管理セクションが書かれているか（Pro + 既定モードなら BEGIN/END の 2 行）
sudo grep -c 'RoamSwitch link guard' /etc/hosts

# セクションの中身と sinkhole 件数
sudo sed -n '/BEGIN RoamSwitch link guard/,/END RoamSwitch link guard/p' /etc/hosts | head -4
sudo sed -n '/BEGIN RoamSwitch link guard/,/END RoamSwitch link guard/p' /etc/hosts | grep -c '^0\.0\.0\.0'

# 実際に落ちているか（セクション内の 1 件で確認。無害）
D=$(sudo sed -n '/BEGIN RoamSwitch/,/END RoamSwitch/p' /etc/hosts | awk '/^0\.0\.0\.0/{print $2; exit}')
dscacheutil -q host -a name "$D"   # → ip_address: 0.0.0.0（名前解決が遮断されている）

# メニュー →「リンク保護」→「オフ」にすると上記セクションが消えることも確認
```

### 脅威フィードの受信専用取得（署名検証つき）

```sh
# 公開フィードとマニフェスト（誰でも取得・検証可能）
curl -s https://lafine.net/updates/v1/manifest        # version/generated/threatfeed{version,url,sha256,signature}
curl -sI https://lafine.net/updates/v1/manifest.sig   # → text/plain
# 送信内容はクエリ・Cookie・識別子なしの GET のみ。tcpdump 併走で確認できます
```

### 予防的 ARP/NDP 固定（§5、1.7.5+）の動作確認

```sh
# 予防ロックが有効な状態で未信頼ネットワークに接続 → permanent エントリを確認
arp -an | grep -i permanent          # ゲートウェイ等の IP が (permanent) で並ぶ
ndp -an | grep -i 'P '               # IPv6 側（P = permanent）
sudo cat "/Library/Application Support/RoamSwitch/gateway_arp_lock.json"  # 固定中の IP→MAC 集合
# メニューで固定を解除 → 上記が消えること
```

### VPN トンネル + キルスイッチ（§5、1.7.6+）の動作確認

```sh
# wireguard-tools（Homebrew）が前提
brew list wireguard-tools >/dev/null && echo "wireguard-tools: OK"

# 未信頼ネットワークで VPN を有効化 → トンネル確立前は pf がキルスイッチ状態
sudo pfctl -sr | grep -E 'block drop all|pass .*(utun|udp)'   # block drop all + 限定的な pass quick

# トンネル確立後（wg-quick up 済み）
wg show                              # handshake / transfer が動いている
route -n get default | grep interface  # → utunN（既定ルートがトンネル）
# VPN を無効化 → キルスイッチ解除、pf が元に戻ること
```

### 防御機構・ペネトレーション自動検証スイート

```sh
# XPC 認可境界、pf Air-Gap 優先度、ポート露出検知、MCP Read-Only、ARP 監視を一括自動検証
git clone https://github.com/lafine1211/roamswitch-support
cd roamswitch-support/audit
./rs-defense-audit.sh all
# → report.md および FINDINGS-DEFENSE.md を生成（実測検証記録: audit/RESULTS-DEFENSE-2026-08-30.ja.md）
```
