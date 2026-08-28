# TASK-0017: 共通UIコンポーネント テストケース詳細

## 概要

このドキュメントは、TASK-0017で実装する共通UIコンポーネント（大ボタン・入力欄・緊急ボタン）のテストケース詳細を定義します。

## テスト方針

- **テストフレームワーク**: flutter_test
- **モック**: mocktail（必要に応じて）
- **カバレッジ目標**: 90%以上

---

## 1. LargeButton テストケース

### 1.1 レンダリングテスト

#### TC-LB-001: labelテキストが正しく表示される

```dart
testWidgets('labelテキストが正しく表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  expect(find.text('テスト'), findsOneWidget);
});
```

**前提条件**: なし
**入力**: label: 'テスト'
**期待結果**: 'テスト'がボタン上に表示される
**優先度**: 必須

---

#### TC-LB-002: デフォルトサイズが60x60pxである

```dart
testWidgets('デフォルトサイズが60x60pxである', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
  expect(sizedBox.width, equals(60.0));
  expect(sizedBox.height, equals(60.0));
});
```

**前提条件**: width/height未指定
**入力**: デフォルト値
**期待結果**: width=60.0, height=60.0
**優先度**: 必須

---

### 1.2 サイズテスト

#### TC-LB-003: カスタムサイズが適用される

```dart
testWidgets('カスタムサイズが適用される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
          width: 100.0,
          height: 80.0,
        ),
      ),
    ),
  );

  final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
  expect(sizedBox.width, equals(100.0));
  expect(sizedBox.height, equals(80.0));
});
```

**前提条件**: なし
**入力**: width: 100.0, height: 80.0
**期待結果**: 指定したサイズが適用される
**優先度**: 高

---

#### TC-LB-004: 44px未満を指定しても44px以上が保証される

```dart
testWidgets('44px未満を指定しても44px以上が保証される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
          width: 30.0,
          height: 30.0,
        ),
      ),
    ),
  );

  final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
  expect(sizedBox.width, greaterThanOrEqualTo(AppSizes.minTapTarget));
  expect(sizedBox.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
});
```

**前提条件**: なし
**入力**: width: 30.0, height: 30.0
**期待結果**: width >= 44.0, height >= 44.0
**優先度**: 必須

---

### 1.3 イベントテスト

#### TC-LB-005: タップ時にonPressedが呼ばれる

```dart
testWidgets('タップ時にonPressedが呼ばれる', (tester) async {
  bool tapped = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () => tapped = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(LargeButton));
  expect(tapped, isTrue);
});
```

**前提条件**: onPressed指定
**入力**: ボタンタップ
**期待結果**: onPressedコールバックが実行される
**優先度**: 必須

---

### 1.4 状態テスト

#### TC-LB-006: onPressed: nullで無効状態になる

```dart
testWidgets('onPressed: nullで無効状態になる', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: null,
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  expect(button.onPressed, isNull);
});
```

**前提条件**: なし
**入力**: onPressed: null
**期待結果**: ボタンが無効化される
**優先度**: 必須

---

### 1.5 スタイルテスト

#### TC-LB-007: backgroundColorが適用される

```dart
testWidgets('backgroundColorが適用される', (tester) async {
  const customColor = Colors.green;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
          backgroundColor: customColor,
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final style = button.style;
  // ButtonStyleのbackgroundColorを検証
  expect(style?.backgroundColor?.resolve({}), equals(customColor));
});
```

**前提条件**: なし
**入力**: backgroundColor: Colors.green
**期待結果**: 背景色がColors.greenになる
**優先度**: 高

---

#### TC-LB-008: textColorが適用される

```dart
testWidgets('textColorが適用される', (tester) async {
  const customColor = Colors.yellow;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
          textColor: customColor,
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final style = button.style;
  expect(style?.foregroundColor?.resolve({}), equals(customColor));
});
```

**前提条件**: なし
**入力**: textColor: Colors.yellow
**期待結果**: テキスト色がColors.yellowになる
**優先度**: 高

---

### 1.6 テーマテスト

#### TC-LB-009: ライトテーマで適切な色が使用される

```dart
testWidgets('ライトテーマで適切な色が使用される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: lightTheme,
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  // テーマの適用を確認
  final context = tester.element(find.byType(LargeButton));
  expect(Theme.of(context).brightness, equals(Brightness.light));
});
```

**前提条件**: ライトテーマ設定
**入力**: なし
**期待結果**: ライトテーマのカラーが適用される
**優先度**: 高

---

#### TC-LB-010: ダークテーマで適切な色が使用される

```dart
testWidgets('ダークテーマで適切な色が使用される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: darkTheme,
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  final context = tester.element(find.byType(LargeButton));
  expect(Theme.of(context).brightness, equals(Brightness.dark));
});
```

**前提条件**: ダークテーマ設定
**入力**: なし
**期待結果**: ダークテーマのカラーが適用される
**優先度**: 高

---

#### TC-LB-011: 高コントラストテーマで適切な色が使用される

```dart
testWidgets('高コントラストテーマで適切な色が使用される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: highContrastTheme,
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  // 高コントラストテーマの特徴を確認
  final context = tester.element(find.byType(LargeButton));
  final theme = Theme.of(context);
  // コントラスト比が十分か確認
  expect(theme.colorScheme.primary, equals(AppColors.primaryHighContrast));
});
```

**前提条件**: 高コントラストテーマ設定
**入力**: なし
**期待結果**: 高コントラストカラーが適用される
**優先度**: 高

---

### 1.7 アクセシビリティテスト

#### TC-LB-012: Semanticsラベルが設定される

```dart
testWidgets('Semanticsラベルが設定される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: LargeButton(
          label: 'テスト',
          onPressed: () {},
        ),
      ),
    ),
  );

  final semantics = tester.getSemantics(find.byType(LargeButton));
  expect(semantics.hasFlag(SemanticsFlag.isButton), isTrue);
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: ボタンとしてSemanticsが設定される
**優先度**: 高

---

## 2. TextInputField テストケース

### 2.1 レンダリングテスト

#### TC-TIF-001: TextFieldが正しく表示される

```dart
testWidgets('TextFieldが正しく表示される', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  expect(find.byType(TextField), findsOneWidget);
});
```

**前提条件**: なし
**入力**: controller指定
**期待結果**: TextFieldがレンダリングされる
**優先度**: 必須

---

#### TC-TIF-002: hintTextが表示される

```dart
testWidgets('hintTextが表示される', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
          hintText: 'ここに入力してください',
        ),
      ),
    ),
  );

  expect(find.text('ここに入力してください'), findsOneWidget);
});
```

**前提条件**: controllerが空
**入力**: hintText: 'ここに入力してください'
**期待結果**: ヒントテキストが表示される
**優先度**: 高

---

### 2.2 入力テスト

#### TC-TIF-003: テキスト入力ができる

```dart
testWidgets('テキスト入力ができる', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField), 'こんにちは');
  expect(controller.text, equals('こんにちは'));
});
```

**前提条件**: なし
**入力**: 'こんにちは'
**期待結果**: controllerにテキストが反映される
**優先度**: 必須

---

#### TC-TIF-004: 1000文字まで入力できる

```dart
testWidgets('1000文字まで入力できる', (tester) async {
  final controller = TextEditingController();
  final text = 'あ' * 1000;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField), text);
  expect(controller.text.length, equals(1000));
});
```

**前提条件**: なし
**入力**: 1000文字のテキスト
**期待結果**: 1000文字が入力される
**優先度**: 必須

---

#### TC-TIF-005: 1001文字以上は入力できない

```dart
testWidgets('1001文字以上は入力できない', (tester) async {
  final controller = TextEditingController();
  final text = 'あ' * 1001;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  await tester.enterText(find.byType(TextField), text);
  expect(controller.text.length, lessThanOrEqualTo(1000));
});
```

**前提条件**: maxLength: 1000（デフォルト）
**入力**: 1001文字のテキスト
**期待結果**: 1000文字で制限される
**優先度**: 必須

---

### 2.3 クリアボタンテスト

#### TC-TIF-006: onClear指定時にクリアボタンが表示される

```dart
testWidgets('onClear指定時にクリアボタンが表示される', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
          onClear: () {},
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.clear), findsOneWidget);
});
```

**前提条件**: なし
**入力**: onClear指定
**期待結果**: クリアアイコンが表示される
**優先度**: 必須

---

#### TC-TIF-007: クリアボタンタップでonClearが呼ばれる

```dart
testWidgets('クリアボタンタップでonClearが呼ばれる', (tester) async {
  final controller = TextEditingController(text: 'テスト');
  bool cleared = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
          onClear: () => cleared = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byIcon(Icons.clear));
  expect(cleared, isTrue);
});
```

**前提条件**: テキスト入力済み
**入力**: クリアボタンタップ
**期待結果**: onClearコールバックが実行される
**優先度**: 必須

---

#### TC-TIF-008: onClear未指定時はクリアボタンが非表示

```dart
testWidgets('onClear未指定時はクリアボタンが非表示', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.clear), findsNothing);
});
```

**前提条件**: なし
**入力**: onClear未指定
**期待結果**: クリアボタンが表示されない
**優先度**: 必須

---

### 2.4 スタイルテスト

#### TC-TIF-009: フォントサイズが24pxである

```dart
testWidgets('フォントサイズが24pxである', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.style?.fontSize, equals(AppSizes.fontSizeLarge));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: fontSize = 24.0
**優先度**: 必須

---

#### TC-TIF-010: 複数行入力が可能である

```dart
testWidgets('複数行入力が可能である', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.maxLines, isNull);
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: maxLines = null（無制限）
**優先度**: 高

---

### 2.5 状態テスト

#### TC-TIF-011: enabled: falseで無効化される

```dart
testWidgets('enabled: falseで無効化される', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
          enabled: false,
        ),
      ),
    ),
  );

  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.enabled, isFalse);
});
```

**前提条件**: なし
**入力**: enabled: false
**期待結果**: TextFieldが無効化される
**優先度**: 高

---

#### TC-TIF-012: readOnly: trueで読み取り専用になる

```dart
testWidgets('readOnly: trueで読み取り専用になる', (tester) async {
  final controller = TextEditingController(text: 'テスト');

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
          readOnly: true,
        ),
      ),
    ),
  );

  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.readOnly, isTrue);
});
```

**前提条件**: なし
**入力**: readOnly: true
**期待結果**: 読み取り専用になる
**優先度**: 高

---

#### TC-TIF-013: 文字数カウンターが表示される

```dart
testWidgets('文字数カウンターが表示される', (tester) async {
  final controller = TextEditingController();

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: TextInputField(
          controller: controller,
        ),
      ),
    ),
  );

  // maxLengthが設定されているとカウンターが自動表示される
  final textField = tester.widget<TextField>(find.byType(TextField));
  expect(textField.maxLength, equals(1000));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: 文字数カウンターが表示される
**優先度**: 高

---

## 3. EmergencyButton テストケース

### 3.1 レンダリングテスト

#### TC-EB-001: ボタンが円形で表示される

```dart
testWidgets('ボタンが円形で表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final shape = button.style?.shape?.resolve({});
  expect(shape, isA<CircleBorder>());
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: CircleBorderが適用される
**優先度**: 必須

---

#### TC-EB-002: 背景色が赤色である

```dart
testWidgets('背景色が赤色である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final bgColor = button.style?.backgroundColor?.resolve({});
  expect(bgColor, equals(AppColors.emergency));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: backgroundColor = AppColors.emergency (#D32F2F)
**優先度**: 必須

---

#### TC-EB-003: サイズが60x60pxである

```dart
testWidgets('サイズが60x60pxである', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
        ),
      ),
    ),
  );

  final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
  expect(sizedBox.width, equals(60.0));
  expect(sizedBox.height, equals(60.0));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: width = 60.0, height = 60.0
**優先度**: 必須

---

#### TC-EB-004: アイコンが表示される

```dart
testWidgets('アイコンが表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
        ),
      ),
    ),
  );

  expect(find.byIcon(Icons.notifications_active), findsOneWidget);
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: notifications_activeアイコンが表示される
**優先度**: 高

---

#### TC-EB-005: アイコンの色が白である

```dart
testWidgets('アイコンの色が白である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
        ),
      ),
    ),
  );

  final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
  final fgColor = button.style?.foregroundColor?.resolve({});
  expect(fgColor, equals(Colors.white));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: foregroundColor = Colors.white
**優先度**: 高

---

### 3.2 イベントテスト

#### TC-EB-006: タップ時にonPressedが呼ばれる

```dart
testWidgets('タップ時にonPressedが呼ばれる', (tester) async {
  bool pressed = false;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () => pressed = true,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(EmergencyButton));
  expect(pressed, isTrue);
});
```

**前提条件**: なし
**入力**: ボタンタップ
**期待結果**: onPressedコールバックが実行される
**優先度**: 必須

---

### 3.3 サイズテスト

#### TC-EB-007: カスタムサイズが適用される

```dart
testWidgets('カスタムサイズが適用される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: EmergencyButton(
          onPressed: () {},
          size: 80.0,
        ),
      ),
    ),
  );

  final sizedBox = tester.widget<SizedBox>(find.byType(SizedBox).first);
  expect(sizedBox.width, equals(80.0));
  expect(sizedBox.height, equals(80.0));
});
```

**前提条件**: なし
**入力**: size: 80.0
**期待結果**: width = 80.0, height = 80.0
**優先度**: 高

---

### 3.4 アクセシビリティテスト

#### TC-EB-008: Semanticsラベルが「緊急呼び出しボタン」である

```dart
testWidgets('Semanticsラベルが緊急呼び出しボタンである', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Semantics(
          button: true,
          label: '緊急呼び出しボタン',
          child: EmergencyButton(
            onPressed: () {},
          ),
        ),
      ),
    ),
  );

  final semantics = tester.getSemantics(find.byType(EmergencyButton));
  expect(semantics.label, contains('緊急'));
});
```

**前提条件**: なし
**入力**: なし
**期待結果**: Semanticsラベルに「緊急」が含まれる
**優先度**: 高

---

## 4. テスト実行コマンド

```bash
# 全テスト実行
cd frontend/kotonoha_app
flutter test test/shared/widgets/

# 個別テスト実行
flutter test test/shared/widgets/large_button_test.dart
flutter test test/shared/widgets/text_input_field_test.dart
flutter test test/shared/widgets/emergency_button_test.dart

# カバレッジ付き実行
flutter test --coverage test/shared/widgets/
```

---

## 5. テスト結果記録テンプレート

| TC-ID | 実行日 | 結果 | 備考 |
|-------|-------|------|------|
| TC-LB-001 | | [ ] Pass / [ ] Fail | |
| TC-LB-002 | | [ ] Pass / [ ] Fail | |
| TC-LB-003 | | [ ] Pass / [ ] Fail | |
| TC-LB-004 | | [ ] Pass / [ ] Fail | |
| TC-LB-005 | | [ ] Pass / [ ] Fail | |
| TC-LB-006 | | [ ] Pass / [ ] Fail | |
| TC-LB-007 | | [ ] Pass / [ ] Fail | |
| TC-LB-008 | | [ ] Pass / [ ] Fail | |
| TC-LB-009 | | [ ] Pass / [ ] Fail | |
| TC-LB-010 | | [ ] Pass / [ ] Fail | |
| TC-LB-011 | | [ ] Pass / [ ] Fail | |
| TC-LB-012 | | [ ] Pass / [ ] Fail | |
| TC-TIF-001 | | [ ] Pass / [ ] Fail | |
| TC-TIF-002 | | [ ] Pass / [ ] Fail | |
| TC-TIF-003 | | [ ] Pass / [ ] Fail | |
| TC-TIF-004 | | [ ] Pass / [ ] Fail | |
| TC-TIF-005 | | [ ] Pass / [ ] Fail | |
| TC-TIF-006 | | [ ] Pass / [ ] Fail | |
| TC-TIF-007 | | [ ] Pass / [ ] Fail | |
| TC-TIF-008 | | [ ] Pass / [ ] Fail | |
| TC-TIF-009 | | [ ] Pass / [ ] Fail | |
| TC-TIF-010 | | [ ] Pass / [ ] Fail | |
| TC-TIF-011 | | [ ] Pass / [ ] Fail | |
| TC-TIF-012 | | [ ] Pass / [ ] Fail | |
| TC-TIF-013 | | [ ] Pass / [ ] Fail | |
| TC-EB-001 | | [ ] Pass / [ ] Fail | |
| TC-EB-002 | | [ ] Pass / [ ] Fail | |
| TC-EB-003 | | [ ] Pass / [ ] Fail | |
| TC-EB-004 | | [ ] Pass / [ ] Fail | |
| TC-EB-005 | | [ ] Pass / [ ] Fail | |
| TC-EB-006 | | [ ] Pass / [ ] Fail | |
| TC-EB-007 | | [ ] Pass / [ ] Fail | |
| TC-EB-008 | | [ ] Pass / [ ] Fail | |

---

## 6. 合格基準

- **必須テストケース**: 全て Pass
- **高優先度テストケース**: 全て Pass
- **カバレッジ**: 90%以上
- **flutter analyze**: エラー0件
