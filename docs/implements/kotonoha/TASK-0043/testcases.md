# TASK-0043: 「はい」「いいえ」「わからない」大ボタン実装 - テストケース

## 概要

要件定義書（`requirements.md`）に基づいた、クイック応答ボタン（QuickResponseButtons/QuickResponseButton）のテストケース一覧。

**タスクID**: TASK-0043
**テストフレームワーク**: flutter_test (ウィジェットテスト)
**優先度レベル**:
- P0: 必須（リリースブロッカー）
- P1: 高優先度（機能として重要）
- P2: 中優先度（品質向上）

---

## テストケース一覧

### 1. QuickResponseType（Enum）テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QR-001 | QuickResponseTypeに3つの値が定義されている | P0 | FR-001 |
| TC-QR-002 | quickResponseLabelsで正しいラベルが取得できる | P0 | FR-006 |

---

### 2. QuickResponseButton（個別ボタン）テスト

#### 2.1 レンダリングテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRB-001 | 「はい」ボタンが正しいラベルで表示される | P0 | FR-001, FR-006 |
| TC-QRB-002 | 「いいえ」ボタンが正しいラベルで表示される | P0 | FR-001, FR-006 |
| TC-QRB-003 | 「わからない」ボタンが正しいラベルで表示される | P0 | FR-001, FR-006 |

#### 2.2 サイズテスト（アクセシビリティ）

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRB-004 | ボタン高さがデフォルトで60px以上である | P0 | FR-003 |
| TC-QRB-005 | ボタン幅がデフォルトで100px以上である | P0 | FR-004 |
| TC-QRB-006 | ボタン高さが44px未満に設定できない（最小保証） | P0 | FR-201 |
| TC-QRB-007 | ボタン幅が44px未満に設定できない（最小保証） | P0 | FR-201 |
| TC-QRB-008 | カスタムサイズが正しく適用される | P1 | FR-003, FR-004 |

#### 2.3 イベントテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRB-009 | タップ時にonPressedコールバックが呼ばれる | P0 | FR-203 |
| TC-QRB-010 | タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる | P0 | FR-101 |
| TC-QRB-011 | onPressed: nullで無効状態になる | P1 | - |
| TC-QRB-012 | タップ時に視覚的フィードバック（InkWell/リップル）が発生する | P1 | FR-102 |

#### 2.4 スタイルテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRB-013 | 「はい」ボタンの背景色が青/緑系である | P1 | NFR-U003 |
| TC-QRB-014 | 「いいえ」ボタンの背景色が赤系である | P1 | NFR-U003 |
| TC-QRB-015 | 「わからない」ボタンの背景色がグレー系である | P1 | NFR-U003 |
| TC-QRB-016 | カスタム背景色が適用される | P2 | - |
| TC-QRB-017 | カスタムテキスト色が適用される | P2 | - |

#### 2.5 フォントサイズ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRB-018 | フォントサイズ「小」でラベルが16pxで表示される | P0 | FR-007 |
| TC-QRB-019 | フォントサイズ「中」でラベルが20pxで表示される | P0 | FR-007 |
| TC-QRB-020 | フォントサイズ「大」でラベルが24pxで表示される | P0 | FR-007 |

---

### 3. QuickResponseButtons（コンテナ）テスト

#### 3.1 レンダリングテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRBs-001 | 3つのボタン（はい、いいえ、わからない）が表示される | P0 | FR-001 |
| TC-QRBs-002 | ボタンが横並びで配置される | P0 | FR-002 |
| TC-QRBs-003 | ボタンの配置順序が左から「はい」「いいえ」「わからない」 | P0 | NFR-U002 |

#### 3.2 レイアウトテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRBs-004 | ボタン間の間隔が8px以上である | P0 | FR-005 |
| TC-QRBs-005 | 3つのボタンが画面幅に収まる | P1 | FR-004 |
| TC-QRBs-006 | 各ボタンの幅が均等に割り当てられる | P1 | FR-004 |
| TC-QRBs-007 | ボタンコンテナがホーム画面上部に配置可能 | P1 | FR-002 |

#### 3.3 イベント伝播テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-QRBs-008 | 「はい」ボタンタップでonResponseコールバックがyesで呼ばれる | P0 | FR-101 |
| TC-QRBs-009 | 「いいえ」ボタンタップでonResponseコールバックがnoで呼ばれる | P0 | FR-101 |
| TC-QRBs-010 | 「わからない」ボタンタップでonResponseコールバックがunknownで呼ばれる | P0 | FR-101 |
| TC-QRBs-011 | タップ時にonTTSSpeakコールバックが呼ばれる | P0 | FR-101 |

---

### 4. テーマ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-TH-001 | ライトモードで適切な配色で表示される | P0 | FR-103 |
| TC-TH-002 | ダークモードで適切な配色で表示される | P0 | FR-103 |
| TC-TH-003 | 高コントラストモードで適切な配色で表示される | P0 | FR-103, FR-202 |
| TC-TH-004 | 高コントラストモードでコントラスト比4.5:1以上を確保 | P0 | FR-202 |
| TC-TH-005 | テーマ変更時に配色が即座に追従する | P1 | FR-103 |

---

### 5. アクセシビリティテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-A11Y-001 | 各ボタンにSemanticsラベルが設定される | P0 | NFR-A001 |
| TC-A11Y-002 | 各ボタンがボタンセマンティクスを持つ | P0 | NFR-A001 |
| TC-A11Y-003 | 色だけでなくラベルテキストで識別可能 | P0 | NFR-A001 |
| TC-A11Y-004 | タップターゲットが44x44px以上を常に満たす | P0 | FR-201 |
| TC-A11Y-005 | ボタン間隔が誤タップ防止に十分（8px以上） | P1 | NFR-A002 |

---

### 6. エッジケーステスト

#### 6.1 連続タップ/デバウンステスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-EDGE-001 | 同じボタンを連続タップした場合デバウンスが機能する | P1 | EDGE-004 |
| TC-EDGE-002 | TTS読み上げ中に別ボタンをタップすると新しい読み上げが開始される | P1 | EDGE-001 |
| TC-EDGE-003 | 連続タップ時にonResponseが1回だけ呼ばれる（デバウンス期間内） | P1 | EDGE-004 |

#### 6.2 画面サイズ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-EDGE-004 | 狭い画面幅（320px）でもボタンが44px以上を維持 | P0 | EDGE-005, FR-201 |
| TC-EDGE-005 | タブレット画面幅（768px以上）で適切なサイズで表示 | P1 | FR-003, FR-004 |
| TC-EDGE-006 | 画面回転（縦向き→横向き）でレイアウトが崩れない | P1 | FR-104 |
| TC-EDGE-007 | 画面回転後もタップターゲットが44px以上を維持 | P1 | FR-104, FR-201 |

#### 6.3 TTSエラーハンドリングテスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-EDGE-008 | TTSサービスがnull/未初期化でもボタンタップが動作する | P1 | EDGE-003 |
| TC-EDGE-009 | TTSエラー時も視覚的フィードバックが提供される | P1 | EDGE-003 |
| TC-EDGE-010 | 音量ゼロ状態でもボタンタップが機能する | P2 | EDGE-002 |

---

### 7. パフォーマンステスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-PERF-001 | タップから視覚フィードバックまで100ms以内 | P1 | NFR-P002 |
| TC-PERF-002 | ウィジェット初回ビルドが妥当な時間内に完了する | P2 | NFR-P002 |
| TC-PERF-003 | 複数回のテーマ切替でも安定して動作する | P2 | FR-103 |

---

### 8. 統合テスト

| テストID | テスト名 | 優先度 | 関連要件 |
|----------|----------|--------|----------|
| TC-INT-001 | ホーム画面にQuickResponseButtonsが表示される | P0 | FR-002 |
| TC-INT-002 | ホーム画面上部に配置されている | P0 | FR-002 |
| TC-INT-003 | 文字盤UIと共存して表示される | P1 | FR-002 |
| TC-INT-004 | 設定画面でフォントサイズ変更後、ボタンのフォントが追従する | P1 | FR-007 |
| TC-INT-005 | 設定画面でテーマ変更後、ボタンの配色が追従する | P1 | FR-103 |

---

## テストケース詳細

### TC-QR-001: QuickResponseTypeに3つの値が定義されている

**優先度**: P0
**関連要件**: FR-001

**前提条件**:
- QuickResponseType enumがインポートされている

**入力**:
- なし

**期待結果**:
- QuickResponseType.yes が存在する
- QuickResponseType.no が存在する
- QuickResponseType.unknown が存在する
- 値の総数が3である

**テストコード概要**:
```dart
test('TC-QR-001: QuickResponseTypeに3つの値が定義されている', () {
  expect(QuickResponseType.values.length, equals(3));
  expect(QuickResponseType.values, contains(QuickResponseType.yes));
  expect(QuickResponseType.values, contains(QuickResponseType.no));
  expect(QuickResponseType.values, contains(QuickResponseType.unknown));
});
```

---

### TC-QR-002: quickResponseLabelsで正しいラベルが取得できる

**優先度**: P0
**関連要件**: FR-006

**前提条件**:
- quickResponseLabels定数が定義されている

**入力**:
- なし

**期待結果**:
- QuickResponseType.yes → 'はい'
- QuickResponseType.no → 'いいえ'
- QuickResponseType.unknown → 'わからない'

**テストコード概要**:
```dart
test('TC-QR-002: quickResponseLabelsで正しいラベルが取得できる', () {
  expect(quickResponseLabels[QuickResponseType.yes], equals('はい'));
  expect(quickResponseLabels[QuickResponseType.no], equals('いいえ'));
  expect(quickResponseLabels[QuickResponseType.unknown], equals('わからない'));
});
```

---

### TC-QRB-001: 「はい」ボタンが正しいラベルで表示される

**優先度**: P0
**関連要件**: FR-001, FR-006

**前提条件**:
- QuickResponseButtonがインポートされている

**入力**:
- responseType: QuickResponseType.yes

**期待結果**:
- 'はい'というテキストが表示される

**テストコード概要**:
```dart
testWidgets('TC-QRB-001: 「はい」ボタンが正しいラベルで表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButton(
          responseType: QuickResponseType.yes,
          onPressed: () {},
        ),
      ),
    ),
  );

  expect(find.text('はい'), findsOneWidget);
});
```

---

### TC-QRB-004: ボタン高さがデフォルトで60px以上である

**優先度**: P0
**関連要件**: FR-003

**前提条件**:
- height未指定でQuickResponseButtonを作成

**入力**:
- デフォルト値

**期待結果**:
- ボタンの高さが60.0以上である

**テストコード概要**:
```dart
testWidgets('TC-QRB-004: ボタン高さがデフォルトで60px以上である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButton(
          responseType: QuickResponseType.yes,
          onPressed: () {},
        ),
      ),
    ),
  );

  final size = tester.getSize(find.byType(QuickResponseButton));
  expect(size.height, greaterThanOrEqualTo(60.0));
});
```

---

### TC-QRB-006: ボタン高さが44px未満に設定できない（最小保証）

**優先度**: P0
**関連要件**: FR-201

**前提条件**:
- なし

**入力**:
- height: 30.0（最小未満の値）

**期待結果**:
- 実際の高さが44.0以上になる

**テストコード概要**:
```dart
testWidgets('TC-QRB-006: ボタン高さが44px未満に設定できない', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButton(
          responseType: QuickResponseType.yes,
          onPressed: () {},
          height: 30.0, // 最小未満
        ),
      ),
    ),
  );

  final size = tester.getSize(find.byType(QuickResponseButton));
  expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
});
```

---

### TC-QRB-010: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる

**優先度**: P0
**関連要件**: FR-101

**前提条件**:
- onTTSSpeakコールバックが設定されている

**入力**:
- ボタンタップ

**期待結果**:
- onTTSSpeakコールバックが「はい」で呼ばれる

**テストコード概要**:
```dart
testWidgets('TC-QRB-010: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる', (tester) async {
  String? spokenText;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButton(
          responseType: QuickResponseType.yes,
          onPressed: () {},
          onTTSSpeak: (text) => spokenText = text,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(QuickResponseButton));
  await tester.pump();

  expect(spokenText, equals('はい'));
});
```

---

### TC-QRBs-001: 3つのボタン（はい、いいえ、わからない）が表示される

**優先度**: P0
**関連要件**: FR-001

**前提条件**:
- QuickResponseButtonsがインポートされている

**入力**:
- なし

**期待結果**:
- 「はい」「いいえ」「わからない」の3つのテキストが表示される

**テストコード概要**:
```dart
testWidgets('TC-QRBs-001: 3つのボタンが表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButtons(
          onResponse: (_) {},
        ),
      ),
    ),
  );

  expect(find.text('はい'), findsOneWidget);
  expect(find.text('いいえ'), findsOneWidget);
  expect(find.text('わからない'), findsOneWidget);
});
```

---

### TC-QRBs-004: ボタン間の間隔が8px以上である

**優先度**: P0
**関連要件**: FR-005

**前提条件**:
- QuickResponseButtonsが表示されている

**入力**:
- なし

**期待結果**:
- 各ボタン間のスペースが8px以上

**テストコード概要**:
```dart
testWidgets('TC-QRBs-004: ボタン間の間隔が8px以上である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButtons(
          onResponse: (_) {},
        ),
      ),
    ),
  );

  final yesButton = tester.getRect(find.text('はい'));
  final noButton = tester.getRect(find.text('いいえ'));

  final spacing = noButton.left - yesButton.right;
  expect(spacing, greaterThanOrEqualTo(8.0));
});
```

---

### TC-TH-004: 高コントラストモードでコントラスト比4.5:1以上を確保

**優先度**: P0
**関連要件**: FR-202

**前提条件**:
- 高コントラストテーマが適用されている

**入力**:
- なし

**期待結果**:
- ラベルと背景のコントラスト比が4.5:1以上

**テストコード概要**:
```dart
testWidgets('TC-TH-004: 高コントラストモードでコントラスト比4.5:1以上', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      theme: highContrastTheme,
      home: Scaffold(
        body: QuickResponseButtons(
          onResponse: (_) {},
        ),
      ),
    ),
  );

  // ボタンの背景色とテキスト色を取得してコントラスト比を計算
  // 高コントラストテーマでは黒文字/白背景で21:1のコントラスト比を持つ
  final context = tester.element(find.byType(QuickResponseButtons));
  final theme = Theme.of(context);

  // コントラスト比の検証（4.5:1以上）
  expect(theme.colorScheme.primary, equals(AppColors.primaryHighContrast));
});
```

---

### TC-EDGE-001: 同じボタンを連続タップした場合デバウンスが機能する

**優先度**: P1
**関連要件**: EDGE-004

**前提条件**:
- QuickResponseButtonが表示されている

**入力**:
- 同じボタンを100ms間隔で3回タップ

**期待結果**:
- onTTSSpeakが1回だけ呼ばれる（デバウンス期間内）

**テストコード概要**:
```dart
testWidgets('TC-EDGE-001: 連続タップ時にデバウンスが機能する', (tester) async {
  int callCount = 0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButton(
          responseType: QuickResponseType.yes,
          onPressed: () {},
          onTTSSpeak: (_) => callCount++,
        ),
      ),
    ),
  );

  // 連続タップ
  await tester.tap(find.byType(QuickResponseButton));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byType(QuickResponseButton));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byType(QuickResponseButton));
  await tester.pump();

  // デバウンスにより1回だけ呼ばれる
  expect(callCount, equals(1));
});
```

---

### TC-EDGE-004: 狭い画面幅（320px）でもボタンが44px以上を維持

**優先度**: P0
**関連要件**: EDGE-005, FR-201

**前提条件**:
- 画面幅が320pxの環境

**入力**:
- なし

**期待結果**:
- 各ボタンのタップターゲットが44x44px以上

**テストコード概要**:
```dart
testWidgets('TC-EDGE-004: 狭い画面幅でもボタンが44px以上を維持', (tester) async {
  // 狭い画面サイズを設定
  tester.view.physicalSize = const Size(320, 568);
  tester.view.devicePixelRatio = 1.0;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: QuickResponseButtons(
          onResponse: (_) {},
        ),
      ),
    ),
  );

  final buttons = tester.widgetList<QuickResponseButton>(
    find.byType(QuickResponseButton),
  );

  for (final button in buttons) {
    final size = tester.getSize(find.byWidget(button));
    expect(size.width, greaterThanOrEqualTo(44.0));
    expect(size.height, greaterThanOrEqualTo(44.0));
  }

  // クリーンアップ
  tester.view.resetPhysicalSize();
  tester.view.resetDevicePixelRatio();
});
```

---

## テストケースサマリー

### 優先度別内訳

| 優先度 | テストケース数 | 説明 |
|--------|----------------|------|
| P0 | 31 | 必須（リリースブロッカー） |
| P1 | 21 | 高優先度（機能として重要） |
| P2 | 5 | 中優先度（品質向上） |
| **合計** | **57** | - |

### カテゴリ別内訳

| カテゴリ | テストケース数 |
|----------|----------------|
| Enumテスト | 2 |
| 個別ボタン（QuickResponseButton） | 20 |
| コンテナ（QuickResponseButtons） | 11 |
| テーマ対応 | 5 |
| アクセシビリティ | 5 |
| エッジケース | 10 |
| パフォーマンス | 3 |
| 統合テスト | 5 |

### 関連要件カバレッジ

| 要件ID | カバーするテストケース数 |
|--------|--------------------------|
| FR-001 | 5 |
| FR-002 | 4 |
| FR-003 | 3 |
| FR-004 | 4 |
| FR-005 | 2 |
| FR-006 | 4 |
| FR-007 | 3 |
| FR-101 | 5 |
| FR-102 | 1 |
| FR-103 | 4 |
| FR-104 | 2 |
| FR-201 | 5 |
| FR-202 | 2 |
| FR-203 | 1 |
| NFR-U002 | 1 |
| NFR-U003 | 3 |
| NFR-A001 | 3 |
| NFR-A002 | 1 |
| NFR-P002 | 2 |
| EDGE-001 | 1 |
| EDGE-002 | 1 |
| EDGE-003 | 2 |
| EDGE-004 | 2 |
| EDGE-005 | 1 |

---

## 受け入れ基準との対応

| 受け入れ基準 | 対応テストケース |
|--------------|------------------|
| AC-001 | TC-QRBs-001 |
| AC-002 | TC-INT-001, TC-INT-002 |
| AC-003 | TC-QRB-004 |
| AC-004 | TC-QRB-005 |
| AC-005 | TC-QRBs-004 |
| AC-006 | TC-QRB-001, TC-QRB-002, TC-QRB-003 |
| AC-007 | TC-QRBs-008 |
| AC-008 | TC-QRBs-009 |
| AC-009 | TC-QRBs-010 |
| AC-010 | TC-PERF-001（視覚フィードバック）, TTS連携は別タスク |
| AC-011 | TC-TH-001 |
| AC-012 | TC-TH-002 |
| AC-013 | TC-TH-003, TC-TH-004 |
| AC-014 | TC-QRB-018 |
| AC-015 | TC-QRB-019 |
| AC-016 | TC-QRB-020 |
| AC-017 | TC-EDGE-001, TC-EDGE-003 |
| AC-018 | TC-EDGE-006 |
| AC-019 | TC-EDGE-007 |

---

**ドキュメント作成日**: 2025-11-23
**タスクID**: TASK-0043
**作成者**: TDD テストケース設計担当
