# ADR-009: クラッシュ報告はストア標準に依拠し、アプリからは何も送らない

状態: 承認済み（2026-09-02 ヒアリングで決定、2026-09-06 書き直し。署名: mozuq）／ 実装は PR #91（ADR-007 条件 3）

## 背景と課題

ADR-007 のリリース条件 3「クラッシュ報告」をどう入れるか。導入は**依存の追加**と**外部送信先の追加**という「負債を作る行為」2 項目に該当し、ADR-007 自身が「ツール選定・送信内容の上限は導入時に別 ADR で決める」と定めていた。本 ADR がそれである。
**Flutter の Dart 例外はプロセスを落とさない。** したがってストアのクラッシュ集計には映らず、見えるようにするには `FlutterError.onError` / `PlatformDispatcher.instance.onError` を報告先へ配線する必要がある（[Flutter 公式](https://docs.flutter.dev/reference/crash-reporting)）。
着手時の実測（2026-09-02）: クラッシュ報告系の依存 0 件（`pubspec.yaml` に crashlytics / sentry / firebase なし）／グローバルエラーハンドラ 0 件（`FlutterError.onError`・`PlatformDispatcher.instance.onError`・`runZonedGuarded` が `lib/` に存在しない）／`debugPrint` は 10 箇所あるがいずれも利用者の入力内容を載せていない（box 名・例外オブジェクトのみ）／プライバシーポリシー（`docs/privacy-policy.md`、最終更新 2024-12-03）は「端末内データは外部サーバーに送信されません」と書くのみでクラッシュ報告の記載が無い／`main` への push で Vercel 本番へ Web がデプロイされる構成がある／Android release ビルドは `isMinifyEnabled = true`（ProGuard 難読化）で mapping.txt を配布物へ渡す仕組みが無い。
**ADR-007 の前提のうち 1 つはもう成り立っていない。** ADR-007 は経路を入れる理由として「一切入れない」の短所に「サイレントな不具合（データ喪失等）が永久に見えない」を挙げていたが、データ喪失は Phase 3 WP-1 の `PersistenceState` と常設バナー（書き込み失敗も `writeFailureProvider` 経由で合流）で画面に出るようになった（ADR-005）。**この製品で最も重い事象は既に観測できる**ので、クラッシュ報告に残る価値は**想定していない例外を見ること**だけに絞られる。

## 制約

- 対象利用者は発話困難な方。**壊れても声で助けを求められない**
- 会話内容は端末内のみ（NFR-101）。いかなる形でも送信しない
- **リリースは backend に依存しない**（ADR-007）。自前の送信先は初回リリースでは採れない
- **`firebase_crashlytics` は Flutter Web 未対応。** web では `Crashlytics#onError` の実装が無く `MissingPluginException` になる（[flutter/flutter#45301](https://github.com/flutter/flutter/issues/45301) / [flutterfire#1693](https://github.com/FirebaseExtended/flutterfire/issues/1693)）。Google I/O 2026 で web 対応が予告されたが Flutter プラグインは未実装（[Firebase blog](https://firebase.blog/posts/2026/05/google-io-2026-announcements/)）

## 検討した選択肢

A. Firebase Crashlytics（無料・実績が多い。Dart 例外も配線すれば拾える）
B. Sentry（`sentry_flutter`。iOS / Android / Web すべて対応し、[`beforeSend` / `beforeBreadcrumb`](https://docs.sentry.io/platforms/flutter/data-management/sensitive-data/) で送信前に落とせる。`sendDefaultPii` は既定 false）
C. **ストア標準（App Store Connect / Google Play Console）のクラッシュ集計だけを使い、アプリからは何も送らない**（採用）
D. 自前の送信先（backend に 1 エンドポイント。送る内容を型で完全に決められ、ADR-003「エラーは型」と一直線）
E. 端末内に貯めて、利用者が任意で共有する（オプトイン。送信の主導権が利用者にある）

## 決定

案 C。アプリにクラッシュ報告の SDK を入れず、アプリからは 1 バイトも送らない。**依存の追加ゼロ・外部送信先の追加ゼロで、「負債を作る行為」に 1 つも触れない。** 実装作業はプライバシーポリシーの更新のみで、リリースまでの距離が縮む。

- **「会話内容・入力内容・ハッシュを一切含まない」は、送信経路を持たないという構造そのもので担保する。** 新しい型・検査・サニタイザは作らない（ADR-008 の教訓: 到達経路を示せない脅威に機械を作らない）
- **Web は初回リリースのクラッシュ報告の対象外とする。** ADR-007 のリリースは App Store と Google Play の 2 経路であり、Vercel への Web デプロイはリリース対象ではなく開発・確認用と位置づける
- **プライバシーポリシーには「本アプリ自身はクラッシュ情報を送信しないこと」と、「OS・ストアの診断機能により、利用者が OS 設定で許可した場合に限り Apple・Google へクラッシュ情報が送られうること」を明記する**

## 決定理由と却下案

- **A（Crashlytics）却下**: Flutter Web 未対応であることに加え、Web を対象外とした時点でも「依存追加＋外部送信先追加」を払う価値が、得られるもの（＝想定外の Dart 例外の可視化）に見合わない。`firebase_core` を含む依存が増え、Google への送信先が増え、設定ファイル（`google-services.json` / `GoogleService-Info.plist`）も要る
- **B（Sentry）却下**: 機能面では最良だが、既定でブレッドクラムがログ文を拾いうるため「一切含まない」を**設定で守る**形になり、設定漏れがそのまま漏えいになる。許可集合を手書きで守る形で 8 周を費やした前例と同じ構造で、**送信経路を持たない案が構造的に強い**
- **D（自前）却下**: リリースが backend に依存する。ADR-007 の「リリースは backend に依存しない」に反する
- **E（オプトイン）却下**: ADR-007 が既に却下済み（「同意率の分だけ盲目になる」）。加えて対象利用者は発話で説明できないため、共有操作そのものが負担になる
- **A・B に共通する却下理由**: ADR-007 が入れたかった「サイレントな不具合」の代表（データ喪失）は Phase 3 WP-1 で画面に出るようになった。最も重い事象が既に観測できるため、外部送信先を 1 つ増やす取引が割に合わない
- 交換材料は不要: ADR-007 は「条件を足すなら何かを削る」を求めるが、本 ADR は条件を足していない（むしろ実装量が減る）ので、削減案 A・B の発動は要らない

## 限界

**想定していない Dart 例外が見えない。** ウィジェットのビルド中の例外・非同期の未捕捉例外は、利用者の画面に影響が出ても開発者には届かない。**Web のクラッシュも見えない。** 観測できるのはネイティブのクラッシュ（エンジン・OOM 等）だけで、受け皿は ADR-007 条件 4 のサポート連絡先（月 1 で巡回）とストアレビューになる——**非クラッシュ不具合と同じ扱いになる。**
**ストアに届くレポートが読めなければ、この決定は意味を持たない。** リリースビルドに mapping とネイティブシンボル（`debugSymbolLevel` 等の設定）が要る。Google Play へは AAB（`flutter build appbundle`）で配布すれば mapping が同梱され、これは #97 で解決済み（着手時の CI が作っていた `apk --flavor internal` は内部確認用であって配布物ではなかった）。残るアップロード鍵は L-52。**これはリリース用ビルドの作業なので ADR-007 の条件 4 で扱い、条件 3 を満たすための追加条件にはしない**（条件を増やすには ADR-007 の改訂が要る、という規定を守る）。

## 検査

(i) 層 2 — 依存・外部送信先（`scripts/adr-touch.sh` が `pubspec.yaml` を拾って索引行を貼る）。
`pubspec.yaml` に crashlytics / sentry / firebase 系の依存が入っていないことは月 1 の棚卸しの目視で見る。**機械のゲートは作らない**（ADR-008／`docs/verification-principles.md`「P1 の処方箋」）。受け皿は AGENTS.md「負債を作る行為には理由が要る」節（依存の追加・外部送信先の追加）と、層 1・層 3・層 5。ADR-001（ユーザー由来の内容を載せない）は送信経路が無いので破られる面が存在しない。

## 再訪条件

**ストアのクラッシュ集計だけでは原因が分からない不具合が実際に報告されたとき**、案 B（Sentry）を再検討する。そのとき「一切含まない」を設定ではなく**型で閉じる**設計（案 D の思想を SDK 境界に適用する）を先に決めること。
Web を正式なリリース対象に格上げするとき（現在は対象外）。`firebase_crashlytics` が Flutter Web に対応し、かつ 1 つ目が起きたとき。
