# TASK-0069: AI変換結果表示・選択UI テストケース一覧

## 開発言語・フレームワーク

- **プログラミング言語**: Dart 3.10+ 🔵
  - **言語選択の理由**: Flutter公式言語、プロジェクト既存技術スタック
  - **テストに適した機能**: async/await、強い型付け、WidgetTester
- **テストフレームワーク**: flutter_test 🔵
  - **フレームワーク選択の理由**: Flutter標準テストフレームワーク、Widget Test対応
  - **テスト実行環境**: `flutter test` コマンド

---

## テストファイル構成

```
test/features/ai_conversion/presentation/widgets/
└── ai_conversion_result_dialog_test.dart
```

---

## 1. 正常系テストケース（基本的な動作）

### TC-069-001: ダイアログが正しく表示される 🔵

- **テスト名**: ダイアログが正しく表示される
  - **何をテストするか**: AIConversionResultDialogがshowDialogで正しくレンダリングされる
  - **期待される動作**: ダイアログがモーダルとして表示される
- **入力値**:
  - originalText: '水 ぬるく'
  - convertedText: 'お水をぬるめでお願いします'
  - politenessLevel: PolitenessLevel.polite
  - **入力データの意味**: 典型的なAI変換の入出力パターン
- **期待される結果**:
  - AlertDialogまたはDialogが画面に表示される
  - **期待結果の理由**: REQ-902の「AI変換結果を自動的に表示」の実現
- **テストの目的**: 基本的なダイアログ表示機能の確認
  - **確認ポイント**: ダイアログウィジェットが存在すること

```dart
testWidgets('TC-069-001: ダイアログが正しく表示される', (tester) async {
  // 【テストデータ準備】: ダイアログ表示用のコンテキストを準備
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => AIConversionResultDialog.show(
              context: context,
              originalText: '水 ぬるく',
              convertedText: 'お水をぬるめでお願いします',
              politenessLevel: PolitenessLevel.polite,
              onAdopt: (_) {},
              onRegenerate: () {},
              onUseOriginal: (_) {},
            ),
            child: const Text('Open'),
          ),
        ),
      ),
    ),
  );

  // 【実際の処理実行】: ダイアログを開く
  await tester.tap(find.text('Open'));
  await tester.pumpAndSettle();

  // 【結果検証】: ダイアログが表示されていること
  expect(find.byType(AIConversionResultDialog), findsOneWidget);
});
```

---

### TC-069-002: タイトル「AI変換結果」が表示される 🔵

- **テスト名**: タイトル「AI変換結果」が表示される
  - **何をテストするか**: ダイアログのヘッダーに正しいタイトルが表示される
  - **期待される動作**: 「AI変換結果」テキストが表示される
- **入力値**: 標準的なテストデータ
- **期待される結果**: find.text('AI変換結果') が findsOneWidget
- **テストの目的**: UIのタイトル表示確認

```dart
testWidgets('TC-069-002: タイトルが表示される', (tester) async {
  // 【結果検証】: タイトルが正しく表示されていること
  expect(find.text('AI変換結果'), findsOneWidget);
});
```

---

### TC-069-003: 元の文が表示される 🔵

- **テスト名**: 元の文が表示される
  - **何をテストするか**: originalTextがダイアログ内に表示される
  - **期待される動作**: 「元の文」ラベルと入力テキストが表示される
- **入力値**: originalText: '水 ぬるく'
- **期待される結果**:
  - find.text('元の文') が findsOneWidget
  - find.text('水 ぬるく') が findsOneWidget
- **テストの目的**: REQ-902の比較表示機能の確認

```dart
testWidgets('TC-069-003: 元の文が表示される', (tester) async {
  // 【結果検証】: ラベルとテキストが表示されていること
  expect(find.text('元の文'), findsOneWidget);
  expect(find.text('水 ぬるく'), findsOneWidget);
});
```

---

### TC-069-004: 変換結果が表示される 🔵

- **テスト名**: 変換結果が表示される
  - **何をテストするか**: convertedTextがダイアログ内に強調表示される
  - **期待される動作**: 「変換結果」ラベルと変換後テキストが表示される
- **入力値**: convertedText: 'お水をぬるめでお願いします'
- **期待される結果**:
  - find.text('変換結果') が findsOneWidget
  - find.text('お水をぬるめでお願いします') が findsOneWidget
- **テストの目的**: REQ-902の変換結果表示確認

```dart
testWidgets('TC-069-004: 変換結果が表示される', (tester) async {
  // 【結果検証】: 変換結果が表示されていること
  expect(find.textContaining('変換結果'), findsOneWidget);
  expect(find.text('お水をぬるめでお願いします'), findsOneWidget);
});
```

---

### TC-069-005: 丁寧さレベルが表示される 🔵

- **テスト名**: 丁寧さレベルが表示される
  - **何をテストするか**: 使用した丁寧さレベルがUIに表示される
  - **期待される動作**: 「丁寧」などのレベル表示がある
- **入力値**: politenessLevel: PolitenessLevel.polite
- **期待される結果**: find.text('丁寧') が findsOneWidget
- **テストの目的**: ユーザーが変換条件を確認できること

```dart
testWidgets('TC-069-005: 丁寧さレベルが表示される', (tester) async {
  // 【結果検証】: 丁寧さレベルが表示されていること
  expect(find.text('丁寧'), findsOneWidget);
});
```

---

### TC-069-006: 「採用」ボタンが表示される 🔵

- **テスト名**: 「採用」ボタンが表示される
  - **何をテストするか**: プライマリアクションボタンの表示
  - **期待される動作**: 「採用」ボタンが表示される
- **期待される結果**: find.text('採用') が findsOneWidget
- **テストの目的**: REQ-902の採用選択機能の確認

```dart
testWidgets('TC-069-006: 採用ボタンが表示される', (tester) async {
  expect(find.text('採用'), findsOneWidget);
});
```

---

### TC-069-007: 「再生成」ボタンが表示される 🔵

- **テスト名**: 「再生成」ボタンが表示される
  - **何をテストするか**: 再生成アクションボタンの表示
  - **期待される動作**: 「再生成」ボタンが表示される
- **期待される結果**: find.text('再生成') が findsOneWidget
- **テストの目的**: REQ-904の再生成機能の確認

```dart
testWidgets('TC-069-007: 再生成ボタンが表示される', (tester) async {
  expect(find.text('再生成'), findsOneWidget);
});
```

---

### TC-069-008: 「元の文を使う」ボタンが表示される 🔵

- **テスト名**: 「元の文を使う」ボタンが表示される
  - **何をテストするか**: 元の文使用アクションボタンの表示
  - **期待される動作**: 「元の文を使う」ボタンが表示される
- **期待される結果**: find.text('元の文を使う') が findsOneWidget
- **テストの目的**: REQ-904の元の文使用機能の確認

```dart
testWidgets('TC-069-008: 元の文を使うボタンが表示される', (tester) async {
  expect(find.text('元の文を使う'), findsOneWidget);
});
```

---

### TC-069-009: 「採用」ボタンタップでコールバックが呼ばれる 🔵

- **テスト名**: 「採用」ボタンタップでコールバックが呼ばれる
  - **何をテストするか**: onAdoptコールバックが正しく呼び出される
  - **期待される動作**: コールバックに変換結果のテキストが渡される
- **入力値**: convertedText: 'お水をぬるめでお願いします'
- **期待される結果**: onAdoptが呼ばれ、引数に変換結果が渡される
- **テストの目的**: REQ-902の採用機能動作確認

```dart
testWidgets('TC-069-009: 採用ボタンタップでコールバックが呼ばれる', (tester) async {
  String? adoptedText;

  // ダイアログ表示（省略）

  // 【実際の処理実行】: 採用ボタンをタップ
  await tester.tap(find.text('採用'));
  await tester.pumpAndSettle();

  // 【結果検証】: コールバックが正しいテキストで呼ばれたこと
  expect(adoptedText, equals('お水をぬるめでお願いします'));
});
```

---

### TC-069-010: 「再生成」ボタンタップでコールバックが呼ばれる 🔵

- **テスト名**: 「再生成」ボタンタップでコールバックが呼ばれる
  - **何をテストするか**: onRegenerateコールバックが正しく呼び出される
  - **期待される動作**: コールバックが呼び出される
- **期待される結果**: onRegenerateが1回呼ばれる
- **テストの目的**: REQ-904の再生成機能動作確認

```dart
testWidgets('TC-069-010: 再生成ボタンタップでコールバックが呼ばれる', (tester) async {
  bool regenerateCalled = false;

  // 【実際の処理実行】: 再生成ボタンをタップ
  await tester.tap(find.text('再生成'));
  await tester.pumpAndSettle();

  // 【結果検証】: コールバックが呼ばれたこと
  expect(regenerateCalled, isTrue);
});
```

---

### TC-069-011: 「元の文を使う」ボタンタップでコールバックが呼ばれる 🔵

- **テスト名**: 「元の文を使う」ボタンタップでコールバックが呼ばれる
  - **何をテストするか**: onUseOriginalコールバックが正しく呼び出される
  - **期待される動作**: コールバックに元の文テキストが渡される
- **入力値**: originalText: '水 ぬるく'
- **期待される結果**: onUseOriginalが呼ばれ、引数に元の文が渡される
- **テストの目的**: REQ-904の元の文使用機能動作確認

```dart
testWidgets('TC-069-011: 元の文を使うボタンタップでコールバックが呼ばれる', (tester) async {
  String? usedOriginalText;

  // 【実際の処理実行】: 元の文を使うボタンをタップ
  await tester.tap(find.text('元の文を使う'));
  await tester.pumpAndSettle();

  // 【結果検証】: コールバックが正しいテキストで呼ばれたこと
  expect(usedOriginalText, equals('水 ぬるく'));
});
```

---

### TC-069-012: 各丁寧さレベルが正しく表示される 🔵

- **テスト名**: 各丁寧さレベルが正しく表示される
  - **何をテストするか**: casual/normal/politeがそれぞれ正しい日本語で表示される
  - **期待される動作**: 「カジュアル」「普通」「丁寧」が表示される
- **入力値**: 各PolitenessLevel値
- **期待される結果**:
  - casual → 「カジュアル」
  - normal → 「普通」
  - polite → 「丁寧」
- **テストの目的**: 丁寧さレベル表示の正確性確認

```dart
testWidgets('TC-069-012: casualレベルが正しく表示される', (tester) async {
  // politenessLevel: PolitenessLevel.casual でダイアログ表示
  expect(find.text('カジュアル'), findsOneWidget);
});

testWidgets('TC-069-012: normalレベルが正しく表示される', (tester) async {
  // politenessLevel: PolitenessLevel.normal でダイアログ表示
  expect(find.text('普通'), findsOneWidget);
});
```

---

## 2. 異常系テストケース（エラーハンドリング）

### TC-069-013: ダイアログ外タップで閉じない 🔵

- **テスト名**: ダイアログ外タップで閉じない
  - **エラーケースの概要**: 誤操作防止のためダイアログ外タップを無視
  - **エラー処理の重要性**: 重要な選択を誤って閉じないため
- **入力値**: ダイアログ外座標へのタップ
- **期待される結果**: ダイアログが表示されたまま
- **テストの目的**: barrierDismissible: falseの動作確認

```dart
testWidgets('TC-069-013: ダイアログ外タップで閉じない', (tester) async {
  // ダイアログ表示後

  // 【実際の処理実行】: ダイアログ外をタップ
  await tester.tapAt(const Offset(10, 10));
  await tester.pumpAndSettle();

  // 【結果検証】: ダイアログがまだ表示されていること
  expect(find.byType(AIConversionResultDialog), findsOneWidget);
});
```

---

### TC-069-014: 連続タップで複数回コールバックが呼ばれない 🔵

- **テスト名**: 連続タップで複数回コールバックが呼ばれない
  - **エラーケースの概要**: 高速な連続タップによる重複処理防止
  - **エラー処理の重要性**: 意図しない複数回実行を防ぐ
- **入力値**: 採用ボタンへの連続タップ
- **期待される結果**: コールバックは1回のみ呼ばれる
- **テストの目的**: 連続タップ防止機能の確認

```dart
testWidgets('TC-069-014: 連続タップで複数回コールバックが呼ばれない', (tester) async {
  int callCount = 0;

  // 【実際の処理実行】: 連続タップ
  final adoptButton = find.text('採用');
  await tester.tap(adoptButton);
  await tester.pump(const Duration(milliseconds: 10));
  await tester.tap(adoptButton);
  await tester.pump(const Duration(milliseconds: 10));
  await tester.tap(adoptButton);
  await tester.pumpAndSettle();

  // 【結果検証】: コールバックは1回のみ
  expect(callCount, equals(1));
});
```

---

## 3. 境界値テストケース

### TC-069-015: 長いテキストが正しく表示される 🟡

- **テスト名**: 長いテキストが正しく表示される
  - **境界値の意味**: 500文字の最大長テキストの表示
  - **境界値での動作保証**: スクロールまたはオーバーフロー対策の確認
- **入力値**: 500文字のconvertedText
- **期待される結果**: テキストがスクロール可能エリアで表示される
- **テストの目的**: 長文表示時のレイアウト確認

```dart
testWidgets('TC-069-015: 長いテキストが正しく表示される', (tester) async {
  final longText = 'あ' * 500;

  // 【結果検証】: テキストが表示され、ダイアログがオーバーフローしない
  expect(tester.takeException(), isNull);
  expect(find.textContaining('あ'), findsWidgets);
});
```

---

### TC-069-016: 最小長テキスト（2文字）が表示される 🟡

- **テスト名**: 最小長テキスト（2文字）が表示される
  - **境界値の意味**: AI変換の最小入力文字数
  - **境界値での動作保証**: 短いテキストでも正しく表示
- **入力値**: originalText: 'あい', convertedText: 'あいうえお'
- **期待される結果**: 両方のテキストが正しく表示される
- **テストの目的**: 最小入力での動作確認

```dart
testWidgets('TC-069-016: 最小長テキストが表示される', (tester) async {
  // 【結果検証】: 2文字でも正しく表示
  expect(find.text('あい'), findsOneWidget);
});
```

---

### TC-069-017: 元の文と変換結果が同じ場合の表示 🟡

- **テスト名**: 元の文と変換結果が同じ場合の表示
  - **境界値の意味**: 変換しても同じ結果になるケース
  - **境界値での動作保証**: エラーにならず正常表示
- **入力値**: originalText: 'ありがとう', convertedText: 'ありがとう'
- **期待される結果**: 両方同じテキストが表示される（エラーなし）
- **テストの目的**: 同一テキストケースの動作確認

```dart
testWidgets('TC-069-017: 同一テキストでも正常表示', (tester) async {
  // 【結果検証】: 同じテキストでもダイアログが正常動作
  expect(find.text('ありがとう'), findsWidgets); // 2箇所に表示
  expect(find.text('採用'), findsOneWidget);
});
```

---

## 4. アクセシビリティテストケース

### TC-069-018: ボタンサイズがアクセシビリティ要件を満たす 🔵

- **テスト名**: ボタンサイズがアクセシビリティ要件を満たす
  - **何をテストするか**: REQ-5001のタップターゲットサイズ要件
  - **期待される動作**: すべてのボタンが44×44px以上
- **期待される結果**: 各ボタンのサイズが最小44×44px
- **テストの目的**: アクセシビリティ要件REQ-5001の確認

```dart
testWidgets('TC-069-018: ボタンサイズがアクセシビリティ要件を満たす', (tester) async {
  // 【結果検証】: 採用ボタンのサイズ確認
  final adoptButton = find.widgetWithText(ElevatedButton, '採用');
  final adoptSize = tester.getSize(adoptButton);
  expect(adoptSize.width, greaterThanOrEqualTo(44.0));
  expect(adoptSize.height, greaterThanOrEqualTo(44.0));

  // 再生成ボタンのサイズ確認
  final regenerateButton = find.widgetWithText(ElevatedButton, '再生成');
  final regenerateSize = tester.getSize(regenerateButton);
  expect(regenerateSize.width, greaterThanOrEqualTo(44.0));
  expect(regenerateSize.height, greaterThanOrEqualTo(44.0));

  // 元の文を使うボタンのサイズ確認
  final useOriginalButton = find.widgetWithText(ElevatedButton, '元の文を使う');
  final useOriginalSize = tester.getSize(useOriginalButton);
  expect(useOriginalSize.width, greaterThanOrEqualTo(44.0));
  expect(useOriginalSize.height, greaterThanOrEqualTo(44.0));
});
```

---

### TC-069-019: Semanticsラベルが正しく設定される 🟡

- **テスト名**: Semanticsラベルが正しく設定される
  - **何をテストするか**: スクリーンリーダー対応のラベル設定
  - **期待される動作**: ダイアログにセマンティクス情報が付与される
- **期待される結果**: Semanticsウィジェットにラベルが設定されている
- **テストの目的**: アクセシビリティ対応の確認

```dart
testWidgets('TC-069-019: Semanticsラベルが設定される', (tester) async {
  // 【結果検証】: Semanticsラベルが設定されていること
  final semantics = tester.widget<Semantics>(
    find.ancestor(
      of: find.byType(AlertDialog),
      matching: find.byType(Semantics),
    ),
  );
  expect(semantics.properties.label, contains('AI変換結果'));
});
```

---

## 5. テーマ対応テストケース

### TC-069-020: ライトモードで正しく表示される 🟡

- **テスト名**: ライトモードで正しく表示される
  - **何をテストするか**: ライトテーマでのUI表示
  - **期待される動作**: 適切なカラースキームで表示
- **入力値**: ThemeData.light()
- **期待される結果**: ダイアログが白背景で表示される
- **テストの目的**: ライトモード対応の確認

```dart
testWidgets('TC-069-020: ライトモードで正しく表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.light(),
      home: // ダイアログ表示
    ),
  );

  // 【結果検証】: ダイアログが正常に表示される
  expect(find.byType(AIConversionResultDialog), findsOneWidget);
});
```

---

### TC-069-021: ダークモードで正しく表示される 🟡

- **テスト名**: ダークモードで正しく表示される
  - **何をテストするか**: ダークテーマでのUI表示
  - **期待される動作**: 適切なカラースキームで表示
- **入力値**: ThemeData.dark()
- **期待される結果**: ダイアログがダーク背景で表示される
- **テストの目的**: ダークモード対応の確認

```dart
testWidgets('TC-069-021: ダークモードで正しく表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: ThemeData.dark(),
      home: // ダイアログ表示
    ),
  );

  // 【結果検証】: ダイアログが正常に表示される
  expect(find.byType(AIConversionResultDialog), findsOneWidget);
});
```

---

### TC-069-022: 高コントラストモードで正しく表示される 🟡

- **テスト名**: 高コントラストモードで正しく表示される
  - **何をテストするか**: 高コントラストテーマでのUI表示
  - **期待される動作**: WCAG 2.1 AA準拠のコントラスト比
- **入力値**: 高コントラストテーマ
- **期待される結果**: ダイアログが高コントラストで表示される
- **テストの目的**: アクセシビリティのコントラスト要件確認

```dart
testWidgets('TC-069-022: 高コントラストモードで正しく表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: AppThemes.highContrast, // プロジェクト定義のテーマ
      home: // ダイアログ表示
    ),
  );

  // 【結果検証】: ダイアログが正常に表示される
  expect(find.byType(AIConversionResultDialog), findsOneWidget);
});
```

---

## テストケースサマリー

| カテゴリ | テストケース数 | 信頼性 |
|---------|--------------|--------|
| 正常系 | 12 | 🔵 11 / 🟡 1 |
| 異常系 | 2 | 🔵 2 |
| 境界値 | 3 | 🟡 3 |
| アクセシビリティ | 2 | 🔵 1 / 🟡 1 |
| テーマ対応 | 3 | 🟡 3 |
| **合計** | **22** | - |

---

## 品質判定

### ✅ 高品質

- **テストケース分類**: 正常系・異常系・境界値・アクセシビリティ・テーマが網羅されている
- **期待値定義**: 各テストケースの期待値が明確
- **技術選択**: Dart + flutter_test で確定
- **実装可能性**: 既存のEmergencyConfirmationDialogテストパターンを参考に実装可能

---

## 次のステップ

次のお勧めステップ: `/tsumiki:tdd-red` でRedフェーズ（失敗テスト作成）を開始します。
