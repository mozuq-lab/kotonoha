# ADR-009: クラッシュ報告はストア標準に依拠し、アプリからは何も送らない

## ステータス

承認済み（2026-09-02 のヒアリングによる）

## 署名

- 起案者: mozuq
- 承認者: mozuq

## 日付

- 起案日: 2026-09-02
- 承認日: 2026-09-02

## コンテキスト

ADR-007 のリリース条件3 は「クラッシュ報告が導入済み（**会話内容・入力内容・ハッシュを
一切含まない**）で、プライバシーポリシーに送信内容が明記されている」。
その導入は **依存の追加**と**外部送信先の追加**という「負債を作る行為」2項目に該当し、
ADR-007 自身が「ツール選定・送信内容の上限は導入時に別 ADR で決める」と定めていた。
本 ADR がそれである。

### 着手時の実測（2026-09-02）

| 項目 | 実測 |
|---|---|
| クラッシュ報告系の依存 | **0件**（`pubspec.yaml` に crashlytics / sentry / firebase なし） |
| グローバルエラーハンドラ | **0件**（`FlutterError.onError` / `PlatformDispatcher.instance.onError` / `runZonedGuarded` は `lib/` に存在しない） |
| `debugPrint` の呼び出し | 10箇所。**いずれも利用者の入力内容を載せていない**（box 名・例外オブジェクトのみ） |
| プライバシーポリシー | `docs/privacy-policy.md`（最終更新 2024-12-03）。「端末内データは外部サーバーに送信されません」と明記。クラッシュ報告の記載は無い |
| Web | `main` への push で Vercel 本番へデプロイされる構成がある |
| Android release ビルド | `isMinifyEnabled = true`（ProGuard 難読化）。**mapping.txt を配布物へ渡す仕組みは無い** |

### ADR-007 の前提のうち1つは、もう成り立っていない

ADR-007 は品質フィードバック経路を入れる理由として、選択肢1（一切入れない）の短所に
「**サイレントな不具合（データ喪失等）が永久に見えない**」を挙げていた。

**データ喪失はもうサイレントではない。** Phase 3 WP-1 で `PersistenceState` と常設バナーを
入れ、保存できない状態は利用者に伝わる（ADR-005）。さらに書き込みの失敗も
`writeFailureProvider` 経由でバナーに合流する。**この製品で最も重い事象は、
クラッシュ報告ではなく画面で観測できるようになっている。**

したがってクラッシュ報告に残る価値は「データ喪失を見ること」ではなく、
**想定していない例外を見ること**に絞られる。この差が、下の決定の前提である。

## 制約条件

- 対象利用者は発話困難な方。**壊れても声で助けを求められない**
- 会話内容は端末内のみ（NFR-101）。いかなる形でも送信しない
- **リリースは backend に依存しない**（ADR-007）。自前の送信先は初回リリースでは採れない
- **Flutter の Dart 例外はプロセスを落とさない。** したがってストアのクラッシュ集計には
  映らない。見えるようにするには `FlutterError.onError` /
  `PlatformDispatcher.instance.onError` を報告先へ配線する必要がある
  （[Flutter 公式](https://docs.flutter.dev/reference/crash-reporting)）
- **`firebase_crashlytics` は Flutter Web 未対応。** web では `Crashlytics#onError` の
  実装が無く `MissingPluginException` になる
  （[flutter/flutter#45301](https://github.com/flutter/flutter/issues/45301) /
  [flutterfire#1693](https://github.com/FirebaseExtended/flutterfire/issues/1693)）。
  Google I/O 2026 で web 対応が予告されたが、Flutter プラグインは未実装
  （[Firebase blog](https://firebase.blog/posts/2026/05/google-io-2026-announcements/)）

## 検討した選択肢

### 選択肢A: Firebase Crashlytics

- 長所: 無料。実績が多い。Dart 例外も配線すれば拾える
- 短所: **Flutter Web 未対応。** `firebase_core` を含む依存が増える。Google への送信先が増える。
  設定ファイル（`google-services.json` / `GoogleService-Info.plist`）が要る

### 選択肢B: Sentry（`sentry_flutter`）

- 長所: iOS / Android / Web すべて対応。`beforeSend` / `beforeBreadcrumb` で送信前に落とせる
  （[Sentry docs](https://docs.sentry.io/platforms/flutter/data-management/sensitive-data/)）。
  `sendDefaultPii` は既定 false
- 短所: 依存追加＋外部送信先追加。**既定でブレッドクラムがログ文を拾いうる**ため、
  「一切含まない」を保つのは**設定で守る**形になり、設定漏れが漏えいになる。
  8周の失敗（許可集合を手書きして守る形）と同じ構造

### 選択肢C: ストア標準に依拠し、アプリからは何も送らない（採用）

App Store Connect と Google Play Console が提供するクラッシュ集計だけを使う。
アプリにクラッシュ報告の SDK を入れず、アプリからは1バイトも送らない。

- 長所: **依存の追加ゼロ・外部送信先の追加ゼロ。**「負債を作る行為」に1つも触れない。
  プライバシーポリシーの根幹（本アプリは端末内データを送信しない）を維持できる。
  **送信経路が存在しないので、会話内容が漏れることを表現できない**
- 短所: **Dart 例外は見えない**（プロセスが落ちないため）。**Web のクラッシュも見えない**。
  観測できるのはネイティブのクラッシュ（エンジン・OOM 等）だけ

### 選択肢D: 自前の送信先（backend に1エンドポイント）

- 長所: 送る内容を型で完全に決められる（ADR-003「エラーは型」と一直線）
- 短所: **リリースが backend に依存する。** ADR-007 の「リリースは backend に依存しない」に反する

### 選択肢E: 端末内に貯めて、利用者が任意で共有する（オプトイン）

- 長所: 送信の主導権が利用者にある
- 短所: **ADR-007 が既に却下している**（「同意率の分だけ盲目になる」）。
  加えて対象利用者は発話で説明できないため、共有操作そのものが負担になる

## 決定

**選択肢C。クラッシュ報告はストア標準（App Store Connect / Google Play Console）に
依拠し、アプリにはクラッシュ報告の SDK を入れず、アプリからは何も送らない。**

- **Web は初回リリースのクラッシュ報告の対象外とする。** ADR-007 のリリースは
  App Store と Google Play の2経路であり、Vercel への Web デプロイは
  リリース対象ではなく開発・確認用と位置づける
- **「会話内容・入力内容・ハッシュを一切含まない」は、送信経路を持たないという
  構造そのもので担保する。** 新しい型・検査・サニタイザは作らない。
  ADR-008 の教訓（到達経路を示せない脅威に機械を作らない）に従う
- **プライバシーポリシーには「本アプリ自身はクラッシュ情報を送信しないこと」と、
  「OS／ストアの診断機能により、利用者が OS 設定で許可した場合に限り
  Apple・Google へクラッシュ情報が送られうること」を明記する**

## 決定理由（却下した案と理由）

- **A（Crashlytics）を却下**: Flutter Web 未対応であることに加え、Web を対象外とした
  時点でも「依存追加＋外部送信先追加」を払う価値が、得られるもの
  （＝想定外の Dart 例外の可視化）に見合わないと判断した
- **B（Sentry）を却下**: 機能面では最良だが、「一切含まない」を**設定で守る**形になる。
  本プロジェクトは、許可集合を手書きで守る形で8周を費やした前例があり、
  同じ構造を選ばない。**送信経路を持たない案が構造的に強い**
- **D（自前）を却下**: リリースが backend に依存する。ADR-007 に反する
- **E（オプトイン）を却下**: ADR-007 が既に却下済み

**A・B に共通する却下理由**: ADR-007 が入れたかった「サイレントな不具合」の代表
（データ喪失）は、Phase 3 WP-1 で画面に出るようになった。**最も重い事象が既に
観測できるため、外部送信先を1つ増やす取引が割に合わなくなった。**

## 結果・影響

### 失うもの

- **想定していない Dart 例外が見えない。** ウィジェットのビルド中の例外・非同期の
  未捕捉例外は、利用者の画面には影響が出ても開発者には届かない
- **Web のクラッシュが見えない**
- 受け皿は ADR-007 条件4 の**サポート連絡先**（月1で巡回）とストアレビューだけになる。
  **非クラッシュ不具合と同じ扱いになる**

### 得るもの

- 依存 0・外部送信先 0。プライバシーポリシーの根幹を維持できる
- 実装作業はプライバシーポリシーの更新のみ。リリースまでの距離が縮む

### この決定が意味を持つための前提（リリース用ビルドの作業）

**ストア標準に依拠する以上、ストアに届くレポートが読めなければ意味が無い。**
現状の Android release ビルドは `isMinifyEnabled = true` で難読化されており、
**mapping.txt を配布物へ渡す仕組みが無い**（2026-09-02 実測）。

- Google Play: AAB（`flutter build appbundle`）で配布すれば mapping は同梱される。
  現状 CI が作るのは `apk --flavor internal` で、これは内部確認用であって配布物ではない
- ネイティブのシンボル: `debugSymbolLevel` 等の設定が要る

**これはリリース用ビルドの作業なので、条件4（ストア要件）で扱う。**
台帳へ送った（Issue #85）。**条件3 を満たすための追加条件にはしない**——
条件を増やすには ADR-007 の改訂が要る、という規定を守る。

### この決定が守られているかの判定手段

`pubspec.yaml` に crashlytics / sentry / firebase 系の依存が入っていないこと。
**機械のゲートは作らない**（ADR-008）。受け皿は AGENTS.md「負債を作る行為には
理由が要る」節（依存の追加・外部送信先の追加）と、層1・層3・層5。

### 撤回条件・再訪条件

- **ストアのクラッシュ集計だけでは原因が分からない不具合が実際に報告されたとき**、
  選択肢B（Sentry）を再検討する。そのとき「一切含まない」を設定ではなく
  **型で閉じる**設計（選択肢D の思想を SDK 境界に適用する）を先に決めること
- Web を正式なリリース対象に格上げするとき（現在は対象外）
- `firebase_crashlytics` が Flutter Web に対応し、かつ上の1つ目が起きたとき

## ADR-007 の改訂（本 ADR に伴う）

本 ADR の決定は、**ADR-007 が列挙した3つの品質フィードバック経路のどれでもない
第4案**である。ADR-007 の採用案は「クラッシュ報告のみ（採用）— クラッシュ・
致命的エラーのみ**送信**、入力内容ゼロ」で、**アプリから送ること**を前提にしていた。

ADR-007 は「新しい条件を足すには本 ADR の改訂が要る」と定めており、
**条件の中身を変える場合も同じ手続きを踏む**。よって次を改訂する。

1. 「品質フィードバック経路の選択肢」に**選択肢4（ストア標準に依拠し、
   アプリからは送らない）**を追加し、採用をそれへ移す
2. 条件3 の文言を「クラッシュ報告の方針が決まっており（本 ADR）、
   プライバシーポリシーに**本アプリが送信しないこと**と、OS／ストアの診断機能により
   送られうる内容が明記されている」に改める

**交換材料**: ADR-007 は「条件を足すなら何かを削る」を求めている。今回は条件を
足していない（むしろ実装量が減る）ため、削減案 A・B の発動は不要である。

## 置き換える ADR

なし。ADR-007 を上記のとおり改訂する。ADR-001（ユーザー由来の内容を載せない）は
そのまま適用される——送信経路が無いので、原則が破られる面が存在しない。

## 参考資料

- [Flutter 公式: Crash reporting](https://docs.flutter.dev/reference/crash-reporting)
- [flutter/flutter#45301 firebase_crashlytics に web 対応を追加](https://github.com/flutter/flutter/issues/45301)
- [flutterfire#1693 firebase_crashlytics web support](https://github.com/FirebaseExtended/flutterfire/issues/1693)
- [Firebase blog: What's new from Firebase at Google I/O 2026](https://firebase.blog/posts/2026/05/google-io-2026-announcements/)
- [Sentry for Flutter: Scrubbing Sensitive Data](https://docs.sentry.io/platforms/flutter/data-management/sensitive-data/)
- ADR-005（永続化の失敗は利用者に伝える）／ADR-007（リリース基準）／ADR-008（機械のゲートを作らない）
- `docs/verification-principles.md`「P1 の処方箋」
