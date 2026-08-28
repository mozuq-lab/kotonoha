# TASK-0089: 文字盤UI最適化 - テストケース一覧

## テスト概要

### テスト対象
- 文字盤ウィジェットのパフォーマンス最適化実装
- 再レンダリング最適化、constコンストラクタ活用、RepaintBoundary配置、メモリ最適化

### テスト戦略
- **単体テスト**: ウィジェットの最適化構造をテスト
- **パフォーマンステスト**: タップ応答時間、再レンダリング範囲、メモリ使用量を計測
- **統合テスト**: E2Eでのパフォーマンス検証

### テスト環境
- Flutter 3.38.1
- テストフレームワーク: flutter_test, integration_test
- 計測ツール: Flutter DevTools (Repaint Rainbow, Memory Profiler, Widget Inspector)

---

## 1. パフォーマンステストケース

### TC-OPT-001: 文字盤タップ応答時間（100ms以内）

**テスト目的**: NFR-003の充足確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: ユーザーが「あ」の文字ボタンをタップする
Then: タップから入力欄反映まで100ms以内で完了する
```

**期待結果**:
- タップ応答時間が100ms以内
- 入力欄に「あ」が表示される
- パフォーマンス計測結果が✅ PASSとなる

**テストコード概要**:
```dart
// integration_test/character_board_optimization_e2e_test.dart
final stopwatch = Stopwatch()..start();
await tester.tap(find.text('あ'));
await tester.pump();
stopwatch.stop();
expect(stopwatch.elapsedMilliseconds, lessThan(100));
expect(find.text('あ'), findsOneWidget);
```

**関連要件**: NFR-003, REQ-OPT-004

**信頼性**: 🔵 青信号

---

### TC-OPT-002: 10文字連続タップ応答時間

**テスト目的**: 連続操作時のパフォーマンス維持確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: ユーザーが「あいうえおかきくけこ」を連続でタップする
Then: 各タップが100ms以内で応答する
```

**期待結果**:
- 各タップの応答時間が100ms以内
- 全10文字が入力欄に順番に表示される
- パフォーマンスが低下しない（1文字目と10文字目で同等の応答時間）
- 平均応答時間が50ms以下

**テストコード概要**:
```dart
const characters = 'あいうえおかきくけこ';
final results = <PerformanceResult>[];
for (final char in characters.split('')) {
  final result = await measureCharacterTapResponse(tester, char);
  results.add(result);
}
final failedResults = results.where((r) => !r.passed).toList();
expect(failedResults, isEmpty);
```

**関連要件**: NFR-003, REQ-OPT-004

**信頼性**: 🔵 青信号

---

### TC-OPT-003: カテゴリ切り替え時のパフォーマンス

**テスト目的**: カテゴリ切り替え時の再レンダリング最適化確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、基本カテゴリが表示されている
When: ユーザーが「濁音」タブをタップする
Then: 切り替えがスムーズに行われる（カクつきなし）
And: 切り替え時間が200ms以内
```

**期待結果**:
- カテゴリ切り替えが200ms以内で完了
- 濁音カテゴリの文字が正しく表示される
- アニメーションがスムーズ（フレーム落ちなし）

**テストコード概要**:
```dart
final stopwatch = Stopwatch()..start();
await tester.tap(find.text('濁音'));
await tester.pumpAndSettle();
stopwatch.stop();
expect(stopwatch.elapsedMilliseconds, lessThan(200));
expect(find.text('が'), findsOneWidget);
```

**関連要件**: REQ-OPT-002, REQ-OPT-003

**信頼性**: 🔵 青信号

---

## 2. 再レンダリング最適化テストケース

### TC-OPT-004: RepaintBoundaryの配置確認

**テスト目的**: RepaintBoundaryが適切に配置されていることを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetが構築される
When: ウィジェットツリーを検査する
Then: 各CharacterButtonがRepaintBoundaryで囲まれている
```

**期待結果**:
- GridViewのitemBuilder内でRepaintBoundaryが使用されている
- CharacterButton個別にRepaintBoundaryが配置されている
- カテゴリタブ部分とグリッド部分が分離されている

**テストコード概要**:
```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CharacterBoardWidget(onCharacterTap: (_) {}),
    ),
  ),
);
final repaintBoundaries = find.byType(RepaintBoundary);
expect(repaintBoundaries, findsWidgets);
// 文字ボタン数+グリッド境界分のRepaintBoundaryが存在すること
```

**関連要件**: REQ-OPT-002

**信頼性**: 🔵 青信号

---

### TC-OPT-005: 単一ボタンタップ時の再描画範囲

**テスト目的**: 1つのボタンタップ時に他のボタンが再描画されないことを確認

**テスト種別**: Manual Test (Flutter DevTools)

**テスト手順**:
```
Given: Flutter DevToolsのRepaint Rainbowを有効化
And: アプリが起動し、文字盤が表示されている
When: 「あ」の文字ボタンをタップする
Then: 「あ」ボタンのみが再描画される（虹色表示）
And: 他の文字ボタンは再描画されない
```

**期待結果**:
- タップしたボタンのみがRepaint Rainbowで虹色に表示される
- 周囲のボタンは色が変わらない
- グリッド全体が再描画されない

**検証方法**:
1. Flutter DevToolsを起動
2. Performance Overlayを有効化
3. Repaint Rainbowを有効化
4. 文字ボタンをタップし、虹色の範囲を目視確認

**関連要件**: REQ-OPT-002

**信頼性**: 🔵 青信号

---

### TC-OPT-006: カテゴリ切り替え時の再描画範囲

**テスト目的**: カテゴリ切り替え時にタブ部分が再描画されないことを確認

**テスト種別**: Manual Test (Flutter DevTools)

**テスト手順**:
```
Given: Flutter DevToolsのRepaint Rainbowを有効化
And: アプリが起動し、基本カテゴリが表示されている
When: 「濁音」タブをタップする
Then: グリッド部分のみが再描画される
And: カテゴリタブ部分は再描画されない
```

**期待結果**:
- グリッド部分（GridView）のみが虹色に表示される
- カテゴリタブ部分は色が変わらない
- RepaintBoundaryによる分離が機能している

**検証方法**:
1. Flutter DevToolsを起動
2. Repaint Rainbowを有効化
3. カテゴリタブをタップし、虹色の範囲を目視確認

**関連要件**: REQ-OPT-002

**信頼性**: 🔵 青信号

---

### TC-OPT-007: constコンストラクタの使用確認

**テスト目的**: constコンストラクタが適切に使用されていることを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetが構築される
When: ウィジェットツリーを検査する
Then: CharacterDataがconstで定義されている
And: 可能な部分でconstウィジェットが使用されている
```

**期待結果**:
- CharacterData.getCharacters()が返すリストがconstリスト
- SizedBox.shrink()がconstで構築されている
- 固定値のPadding、SizedBoxがconstで構築されている

**テストコード概要**:
```dart
// character_data.dartの確認
test('CharacterData.basicCharactersがconstリスト', () {
  const characters = CharacterData.basicCharacters;
  expect(characters, isNotNull);
  expect(characters.length, greaterThan(0));
});
```

**関連要件**: REQ-OPT-001

**信頼性**: 🔵 青信号

---

### TC-OPT-008: 親ウィジェット再ビルド時の子ウィジェット安定性

**テスト目的**: 親ウィジェットが再ビルドされても子ウィジェットが不要に再ビルドされないことを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetを含む親ウィジェットが構築される
When: 親ウィジェットが再ビルドされる（setStateなど）
Then: CharacterBoardWidgetは再ビルドされない
```

**期待結果**:
- constコンストラクタによりCharacterBoardWidgetが再利用される
- CharacterButtonが不要に再構築されない
- パフォーマンスが維持される

**テストコード概要**:
```dart
int buildCount = 0;
await tester.pumpWidget(
  MaterialApp(
    home: StatefulBuilder(
      builder: (context, setState) {
        return Column(
          children: [
            CharacterBoardWidget(
              onCharacterTap: (_) {},
              key: const ValueKey('character_board'),
            ),
            ElevatedButton(
              onPressed: () => setState(() {}),
              child: const Text('Rebuild Parent'),
            ),
          ],
        );
      },
    ),
  ),
);
await tester.tap(find.text('Rebuild Parent'));
await tester.pump();
// CharacterBoardWidgetが再ビルドされないことを検証
```

**関連要件**: REQ-OPT-001, REQ-OPT-006

**信頼性**: 🔵 青信号

---

## 3. メモリ最適化テストケース

### TC-OPT-009: メモリリークの検証

**テスト目的**: メモリリークがないことを確認

**テスト種別**: Manual Test (Flutter DevTools)

**テスト手順**:
```
Given: Flutter DevToolsのMemory Profilerを起動
And: アプリが起動し、文字盤が表示されている
When: カテゴリを基本→濁音→半濁音→小文字→記号と切り替える（10回繰り返し）
Then: メモリ使用量が安定している
And: メモリリークが検出されない
```

**期待結果**:
- カテゴリ切り替え前後でメモリ使用量が増加し続けない
- GC後にメモリが解放される
- メモリ使用量が合理的な範囲内（文字盤表示で10MB以下）

**検証方法**:
1. Flutter DevToolsのMemoryタブを開く
2. Snapshot取得
3. カテゴリを10回繰り返し切り替え
4. 再度Snapshot取得
5. Diff比較でメモリリークを確認

**関連要件**: REQ-OPT-005

**信頼性**: 🔵 青信号

---

### TC-OPT-010: 文字盤表示中のメモリ使用量

**テスト目的**: 文字盤表示中のメモリ使用量が合理的な範囲内であることを確認

**テスト種別**: Manual Test (Flutter DevTools)

**テスト手順**:
```
Given: Flutter DevToolsのMemory Profilerを起動
And: アプリが起動している
When: 文字盤が表示される
Then: メモリ使用量が10MB以下
```

**期待結果**:
- 文字盤表示に必要なメモリが10MB以下
- 大量の文字ボタン（基本50個、濁音20個など）でもメモリ効率が良い
- ウィジェットツリーの深さが最適化されている

**検証方法**:
1. Flutter DevToolsのMemoryタブを開く
2. 文字盤表示時のメモリ使用量を記録
3. カテゴリごとのメモリ使用量を比較

**関連要件**: REQ-OPT-005

**信頼性**: 🔵 青信号

---

### TC-OPT-011: 連続タップ時のメモリ安定性

**テスト目的**: 連続タップ時にメモリリークが発生しないことを確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: 100文字連続でタップする
Then: メモリ使用量が安定している
And: メモリリークが発生しない
```

**期待結果**:
- 100回タップ後もメモリ使用量が急増しない
- アニメーション用のオブジェクトが適切に解放される
- タップフィードバック（InkWell）のメモリが適切に管理される

**テストコード概要**:
```dart
// integration_testで100回タップをシミュレート
for (int i = 0; i < 100; i++) {
  await tester.tap(find.text('あ'));
  await tester.pump();
}
// メモリリークはFlutter DevToolsで手動確認
```

**関連要件**: REQ-OPT-005

**信頼性**: 🔵 青信号

---

## 4. ウィジェットツリー最適化テストケース

### TC-OPT-012: CharacterButton階層の深さ確認

**テスト目的**: ウィジェット階層が5層以内であることを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetが構築される
When: Widget Inspectorでウィジェットツリーを検査する
Then: CharacterButton内のウィジェット階層が5層以内
```

**期待結果**:
- CharacterButtonのウィジェット階層が5層以内
- 不要なContainer、Columnが削除されている
- レンダリングコストが最小化されている

**検証方法**:
1. Flutter DevToolsのWidget Inspectorを開く
2. CharacterButtonを選択
3. ウィジェットツリーの深さを確認

**関連要件**: REQ-OPT-003

**信頼性**: 🔵 青信号

---

### TC-OPT-013: 不要なSemanticsラッパーの削除確認

**テスト目的**: 必要最小限のSemanticsのみ使用されていることを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetが構築される
When: ウィジェットツリーを検査する
Then: Semanticsが必要最小限のみ使用されている
```

**期待結果**:
- ElevatedButton、InkWellが持つ暗黙的なSemanticsのみ使用
- 不要な明示的Semanticsラッパーがない
- アクセシビリティが損なわれていない

**テストコード概要**:
```dart
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CharacterBoardWidget(onCharacterTap: (_) {}),
    ),
  ),
);
// Semanticsツリーを検査
final SemanticsNode semantics = tester.getSemantics(find.text('あ'));
expect(semantics.label, isNotNull);
```

**関連要件**: REQ-OPT-003

**信頼性**: 🔵 青信号

---

## 5. タップフィードバック最適化テストケース

### TC-OPT-014: InkWellのsplash効果パフォーマンス

**テスト目的**: splash効果が軽量化され、100ms応答を確保できることを確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: 「あ」の文字ボタンをタップする
Then: タップから入力欄反映まで100ms以内
And: splash効果が視認できる
```

**期待結果**:
- タップ応答時間が100ms以内
- InkWellのsplash効果が表示される
- アニメーションがパフォーマンスを阻害しない

**テストコード概要**:
```dart
final stopwatch = Stopwatch()..start();
await tester.tap(find.text('あ'));
await tester.pump(); // 1フレーム進める
stopwatch.stop();
expect(stopwatch.elapsedMilliseconds, lessThan(100));
// splash効果の視覚確認は手動テスト
```

**関連要件**: REQ-OPT-004, NFR-003

**信頼性**: 🔵 青信号

---

### TC-OPT-015: タップフィードバックのユーザビリティ確認

**テスト目的**: 最適化後もユーザビリティを損なわない視覚フィードバックが維持されることを確認

**テスト種別**: Manual Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: 複数の文字ボタンをタップする
Then: 各タップで視覚的フィードバック（splash、highlight）が視認できる
```

**期待結果**:
- タップ時にsplash効果が表示される
- highlight効果が適切に表示される
- ユーザーがタップしたことを明確に認識できる

**検証方法**:
1. 実機またはシミュレータでアプリを起動
2. 文字ボタンを複数タップ
3. splash効果、highlight効果を目視確認

**関連要件**: REQ-OPT-004

**信頼性**: 🔵 青信号

---

## 6. Riverpod状態管理最適化テストケース

### TC-OPT-016: inputBufferProvider変更時の再ビルド範囲

**テスト目的**: inputBufferProviderの変更がCharacterBoardWidgetを不要に再ビルドしないことを確認

**テスト種別**: Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidgetを含むアプリが起動
When: 文字をタップし、inputBufferProviderが更新される
Then: CharacterBoardWidgetは再ビルドされない
And: 入力欄のみが更新される
```

**期待結果**:
- CharacterBoardWidgetがinputBufferProviderをwatchしていない
- 入力バッファ更新時にCharacterBoardWidgetが再ビルドされない
- onCharacterTapコールバックのみが実行される

**テストコード概要**:
```dart
// CharacterBoardWidgetがConsumerWidgetでないことを確認
test('CharacterBoardWidgetがStatefulWidget', () {
  expect(CharacterBoardWidget, isA<StatefulWidget>());
});

// inputBufferProviderを直接watchしていないことを確認
// ※コードレビューで検証
```

**関連要件**: REQ-OPT-006

**信頼性**: 🔵 青信号

---

### TC-OPT-017: ConsumerWidgetの使用範囲確認

**テスト目的**: ConsumerWidgetが必要最小限のみ使用されていることを確認

**テスト種別**: Code Review / Static Analysis

**テスト手順**:
```
Given: CharacterBoardWidget関連のコードベース
When: ConsumerWidgetの使用箇所を検査する
Then: CharacterBoardWidget自体はStatefulWidget
And: 親ウィジェット（InputScreen等）でのみConsumerWidgetを使用
```

**期待結果**:
- CharacterBoardWidget自体はStatefulWidget
- inputBufferProviderは親ウィジェットでwatch
- onCharacterTapコールバックを経由してデータを渡す設計

**検証方法**:
```bash
grep -r "ConsumerWidget" lib/features/character_board/
# CharacterBoardWidget内でConsumerWidgetが使用されていないことを確認
```

**関連要件**: REQ-OPT-006

**信頼性**: 🔵 青信号

---

## 7. 統合テストケース（最適化総合検証）

### TC-OPT-018: 文字盤UI最適化総合検証

**テスト目的**: すべての最適化が適用され、パフォーマンス要件を満たすことを確認

**テスト種別**: E2E Integration Test

**テスト手順**:
```
Given: アプリが起動し、文字盤が表示されている
When: 以下の操作を順番に実行する
  1. 「あいうえお」を連続タップ（5文字）
  2. カテゴリを「濁音」に切り替え
  3. 「がぎぐげご」を連続タップ（5文字）
  4. カテゴリを「基本」に戻す
  5. 「かきくけこ」を連続タップ（5文字）
Then: 以下をすべて満たす
  - 各タップが100ms以内で応答
  - カテゴリ切り替えが200ms以内
  - 入力欄に全15文字が正しく表示される
  - メモリリークが発生しない
```

**期待結果**:
- 全タップが100ms以内で応答（NFR-003）
- カテゴリ切り替えが200ms以内
- 入力欄に「あいうえおがぎぐげごかきくけこ」が表示される
- メモリ使用量が安定している
- アニメーションがスムーズ

**テストコード概要**:
```dart
// 5文字タップ
final chars1 = 'あいうえお'.split('');
for (final char in chars1) {
  final result = await measureCharacterTapResponse(tester, char);
  expect(result.passed, isTrue);
}

// カテゴリ切り替え
final sw = Stopwatch()..start();
await tester.tap(find.text('濁音'));
await tester.pumpAndSettle();
sw.stop();
expect(sw.elapsedMilliseconds, lessThan(200));

// 5文字タップ
final chars2 = 'がぎぐげご'.split('');
for (final char in chars2) {
  final result = await measureCharacterTapResponse(tester, char);
  expect(result.passed, isTrue);
}

// カテゴリ切り替え
await tester.tap(find.text('基本'));
await tester.pumpAndSettle();

// 5文字タップ
final chars3 = 'かきくけこ'.split('');
for (final char in chars3) {
  final result = await measureCharacterTapResponse(tester, char);
  expect(result.passed, isTrue);
}

// 入力欄確認
expect(find.text('あいうえおがぎぐげごかきくけこ'), findsOneWidget);
```

**関連要件**: NFR-003, REQ-OPT-001〜006

**信頼性**: 🔵 青信号

---

### TC-OPT-019: 最適化前後のパフォーマンス比較

**テスト目的**: 最適化前と最適化後のパフォーマンスを比較し、改善を確認

**テスト種別**: Benchmark / Manual Test

**テスト手順**:
```
Given: 最適化前のコードと最適化後のコードが準備されている
When: 同一条件で以下の操作を実行する
  - 10文字連続タップ
  - カテゴリ切り替え5回
Then: 最適化後のパフォーマンスが向上していることを確認
```

**期待結果**:
- タップ応答時間が改善（例: 120ms → 80ms）
- 再レンダリング範囲が限定される
- メモリ使用量が削減される

**検証方法**:
1. 最適化前のコードでベンチマーク実行
2. 最適化後のコードでベンチマーク実行
3. Flutter DevToolsでパフォーマンス比較
4. 結果をドキュメント化

**関連要件**: 全REQ-OPT

**信頼性**: 🟡 黄信号（ベンチマーク環境に依存）

---

## 8. コード品質テストケース

### TC-OPT-020: flutter_lints準拠確認

**テスト目的**: コード品質がflutter_lintsに準拠していることを確認

**テスト種別**: Static Analysis

**テスト手順**:
```
Given: 最適化後のコードベース
When: flutter analyzeを実行する
Then: リンティングエラーが0件
```

**期待結果**:
- flutter analyzeでエラーが出ない
- 警告が最小限（または0件）
- コーディング規約に準拠

**検証方法**:
```bash
cd frontend/kotonoha_app
flutter analyze
```

**関連要件**: AC-007（コード品質）

**信頼性**: 🔵 青信号

---

### TC-OPT-021: constコンストラクタの最大活用確認

**テスト目的**: constコンストラクタが可能な限り使用されていることを確認

**テスト種別**: Code Review / Static Analysis

**テスト手順**:
```
Given: 最適化後のコードベース
When: constが使用可能な箇所を検査する
Then: 以下がconstで定義されている
  - CharacterData.basicCharacters等
  - SizedBox.shrink()
  - 固定値のPadding、SizedBox
```

**期待結果**:
- CharacterData.basicCharactersがconstリスト
- GridView内の空要素がconst SizedBox.shrink()
- 固定値のウィジェットがconstで構築

**検証方法**:
```bash
# constの使用状況を確認
grep -r "const " lib/features/character_board/
```

**関連要件**: REQ-OPT-001, AC-007

**信頼性**: 🔵 青信号

---

### TC-OPT-022: ウィジェットkeyパラメータ確認

**テスト目的**: ウィジェットがkeyパラメータを持つことを確認

**テスト種別**: Code Review / Widget Unit Test

**テスト手順**:
```
Given: CharacterBoardWidget、CharacterButtonのコード
When: コンストラクタ定義を検査する
Then: super.keyまたはkeyパラメータが定義されている
```

**期待結果**:
- CharacterBoardWidgetがsuper.keyを持つ
- CharacterButtonがkeyパラメータを持つ
- ValueKeyが適切に使用されている

**テストコード概要**:
```dart
// keyパラメータの存在確認
await tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: CharacterBoardWidget(
        key: const ValueKey('test_key'),
        onCharacterTap: (_) {},
      ),
    ),
  ),
);
expect(find.byKey(const ValueKey('test_key')), findsOneWidget);
```

**関連要件**: AC-007（コーディング規約）

**信頼性**: 🔵 青信号

---

## テストケース総数サマリー

| カテゴリ | テストケース数 | 信頼性レベル |
|---------|--------------|------------|
| パフォーマンステスト | TC-OPT-001〜003 (3件) | 🔵 |
| 再レンダリング最適化テスト | TC-OPT-004〜008 (5件) | 🔵 |
| メモリ最適化テスト | TC-OPT-009〜011 (3件) | 🔵 |
| ウィジェットツリー最適化テスト | TC-OPT-012〜013 (2件) | 🔵 |
| タップフィードバック最適化テスト | TC-OPT-014〜015 (2件) | 🔵 |
| Riverpod状態管理最適化テスト | TC-OPT-016〜017 (2件) | 🔵 |
| 統合テスト | TC-OPT-018〜019 (2件) | 🔵/🟡 |
| コード品質テスト | TC-OPT-020〜022 (3件) | 🔵 |
| **合計** | **22件** | **🔵 21件 / 🟡 1件** |

---

## テスト実行順序

### フェーズ1: 単体テスト（Widget Unit Test）
1. TC-OPT-004: RepaintBoundaryの配置確認
2. TC-OPT-007: constコンストラクタの使用確認
3. TC-OPT-008: 親ウィジェット再ビルド時の子ウィジェット安定性
4. TC-OPT-012: CharacterButton階層の深さ確認
5. TC-OPT-013: 不要なSemanticsラッパーの削除確認
6. TC-OPT-016: inputBufferProvider変更時の再ビルド範囲
7. TC-OPT-022: ウィジェットkeyパラメータ確認

### フェーズ2: E2Eパフォーマンステスト
1. TC-OPT-001: 文字盤タップ応答時間（100ms以内）
2. TC-OPT-002: 10文字連続タップ応答時間
3. TC-OPT-003: カテゴリ切り替え時のパフォーマンス
4. TC-OPT-014: InkWellのsplash効果パフォーマンス
5. TC-OPT-018: 文字盤UI最適化総合検証

### フェーズ3: 手動テスト（Flutter DevTools）
1. TC-OPT-005: 単一ボタンタップ時の再描画範囲
2. TC-OPT-006: カテゴリ切り替え時の再描画範囲
3. TC-OPT-009: メモリリークの検証
4. TC-OPT-010: 文字盤表示中のメモリ使用量
5. TC-OPT-011: 連続タップ時のメモリ安定性
6. TC-OPT-015: タップフィードバックのユーザビリティ確認

### フェーズ4: 静的解析・コードレビュー
1. TC-OPT-017: ConsumerWidgetの使用範囲確認
2. TC-OPT-020: flutter_lints準拠確認
3. TC-OPT-021: constコンストラクタの最大活用確認

### フェーズ5: ベンチマーク
1. TC-OPT-019: 最適化前後のパフォーマンス比較

---

## 自動化レベル

| テスト種別 | テストケース数 | 自動化可能 | 手動必須 |
|----------|--------------|----------|---------|
| Widget Unit Test | 7件 | ✅ 7件 | - |
| E2E Integration Test | 8件 | ✅ 8件 | - |
| Manual Test (DevTools) | 6件 | - | ⚠️ 6件 |
| Static Analysis / Code Review | 3件 | ✅ 3件 | - |
| **合計** | **24件** | **18件 (75%)** | **6件 (25%)** |

---

## 成功基準（Definition of Done）

### 必須条件
- [ ] 全自動テスト（18件）が✅ PASSする
- [ ] タップ応答時間が100ms以内（TC-OPT-001, 002, 014）
- [ ] カテゴリ切り替えが200ms以内（TC-OPT-003）
- [ ] RepaintBoundaryが適切に配置されている（TC-OPT-004）
- [ ] メモリリークが検出されない（TC-OPT-009）
- [ ] flutter_lintsに準拠（TC-OPT-020）

### 推奨条件
- [ ] 手動テスト（6件）ですべて期待結果を満たす
- [ ] 最適化前と比較してパフォーマンスが向上（TC-OPT-019）
- [ ] constコンストラクタが最大限活用されている（TC-OPT-021）

---

## 次のステップ

テストケース洗い出しが完了しました。次は以下のコマンドで実装に進みます：

```bash
/tsumiki:tdd-red
```

TDDのRedフェーズで、失敗するテストケースを順番に作成していきます。
