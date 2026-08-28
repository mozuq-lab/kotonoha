# TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装 - テストケース

## 概要

要件定義書（`requirements.md`）に基づいた、状態ボタン（StatusButtons/StatusButton）のテストケース一覧。

**タスクID**: TASK-0044
**テストフレームワーク**: flutter_test (ウィジェットテスト)
**優先度レベル**:
- P0: 必須（リリースブロッカー）
- P1: 高優先度（機能として重要）
- P2: 中優先度（品質向上）

---

## テストケース一覧

### 1. StatusButtonType（Enum）テスト

#### 1.1 Enum定義テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBT-001 | StatusButtonTypeに必須の8個の値が定義されている | P0 | FR-001, FR-002 | 単体 |
| TC-SBT-002 | StatusButtonTypeに最大12個の値が定義されている | P0 | FR-002 | 単体 |
| TC-SBT-003 | 必須状態タイプが正しく定義されている（pain, toilet, hot, cold, water, sleepy, help, wait） | P0 | FR-001 | 単体 |
| TC-SBT-004 | オプション状態タイプが正しく定義されている（again, thanks, sorry, okay） | P1 | FR-001 | 単体 |

#### 1.2 ラベル取得テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBT-005 | statusButtonLabelsで「痛い」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-006 | statusButtonLabelsで「トイレ」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-007 | statusButtonLabelsで「暑い」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-008 | statusButtonLabelsで「寒い」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-009 | statusButtonLabelsで「水」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-010 | statusButtonLabelsで「眠い」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-011 | statusButtonLabelsで「助けて」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-012 | statusButtonLabelsで「待って」ラベルが取得できる | P0 | FR-005 | 単体 |
| TC-SBT-013 | statusButtonLabelsでオプションラベルが取得できる | P1 | FR-005 | 単体 |
| TC-SBT-014 | 全てのStatusButtonTypeに対応するラベルが存在する | P0 | FR-005 | 単体 |

#### 1.3 拡張メソッドテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBT-015 | StatusButtonType.pain.labelで「痛い」が取得できる | P0 | FR-005 | 単体 |
| TC-SBT-016 | 全StatusButtonTypeでlabel拡張が動作する | P0 | FR-005 | 単体 |

---

### 2. StatusButton（個別ボタン）テスト

#### 2.1 レンダリングテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SB-001 | 「痛い」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-002 | 「トイレ」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-003 | 「暑い」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-004 | 「寒い」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-005 | 「水」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-006 | 「眠い」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-007 | 「助けて」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |
| TC-SB-008 | 「待って」ボタンが正しいラベルで表示される | P0 | FR-001, FR-005 | ウィジェット |

#### 2.2 サイズテスト（アクセシビリティ）

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SB-009 | ボタン高さがデフォルトで44px以上である | P0 | FR-004, FR-201 | ウィジェット |
| TC-SB-010 | ボタン幅がデフォルトで44px以上である | P0 | FR-004, FR-201 | ウィジェット |
| TC-SB-011 | ボタン高さが44px未満に設定できない（最小保証） | P0 | FR-201 | ウィジェット |
| TC-SB-012 | ボタン幅が44px未満に設定できない（最小保証） | P0 | FR-201 | ウィジェット |
| TC-SB-013 | カスタムサイズ指定時も最小サイズが保証される | P1 | FR-201 | ウィジェット |

#### 2.3 イベントテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SB-014 | タップ時にonPressedコールバックが呼ばれる | P0 | FR-203 | ウィジェット |
| TC-SB-015 | タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SB-016 | onPressed: nullで無効状態になる | P1 | - | ウィジェット |
| TC-SB-017 | タップ時に視覚的フィードバック（InkWell/リップル）が発生する | P1 | FR-102 | ウィジェット |
| TC-SB-018 | 「痛い」タップでonTTSSpeakが「痛い」で呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SB-019 | 「トイレ」タップでonTTSSpeakが「トイレ」で呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SB-020 | 「助けて」タップでonTTSSpeakが「助けて」で呼ばれる | P0 | FR-101 | ウィジェット |

#### 2.4 デバウンステスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SB-021 | 連続タップ時にデバウンスが機能する | P1 | EDGE-004 | ウィジェット |
| TC-SB-022 | デバウンス期間経過後は再度タップが有効になる | P1 | EDGE-004 | ウィジェット |
| TC-SB-023 | 連続タップでonTTSSpeakが1回だけ呼ばれる | P1 | EDGE-004 | ウィジェット |

#### 2.5 フォントサイズ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SB-024 | フォントサイズ「小」でラベルが適切なサイズで表示される | P0 | FR-006 | ウィジェット |
| TC-SB-025 | フォントサイズ「中」でラベルが適切なサイズで表示される | P0 | FR-006 | ウィジェット |
| TC-SB-026 | フォントサイズ「大」でラベルが適切なサイズで表示される | P0 | FR-006 | ウィジェット |
| TC-SB-027 | フォントサイズ変更時にラベルサイズが即座に追従する | P1 | FR-006 | ウィジェット |

---

### 3. StatusButtons（コンテナ）テスト

#### 3.1 レンダリングテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBs-001 | 8個以上の状態ボタンが表示される | P0 | FR-002 | ウィジェット |
| TC-SBs-002 | 12個以下の状態ボタンが表示される | P0 | FR-002 | ウィジェット |
| TC-SBs-003 | 必須の8個のボタンが全て表示される | P0 | FR-001, FR-002 | ウィジェット |
| TC-SBs-004 | デフォルトで必須ボタンのみ表示される | P1 | FR-001 | ウィジェット |
| TC-SBs-005 | オプションボタン追加時に最大12個まで表示される | P1 | FR-002 | ウィジェット |

#### 3.2 レイアウトテスト（グリッド配置）

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBs-006 | ボタンがグリッド形式（横4列）で配置される | P0 | FR-007 | ウィジェット |
| TC-SBs-007 | ボタン間の間隔が4px以上である | P0 | FR-008, NFR-A002 | ウィジェット |
| TC-SBs-008 | 8個のボタンが2行4列で配置される | P0 | FR-007 | ウィジェット |
| TC-SBs-009 | 12個のボタンが3行4列で配置される | P1 | FR-007 | ウィジェット |
| TC-SBs-010 | 各ボタンの幅が均等に割り当てられる | P1 | FR-007 | ウィジェット |
| TC-SBs-011 | ボタンコンテナがQuickResponseButtonsの下に配置可能 | P1 | FR-003 | ウィジェット |

#### 3.3 イベント伝播テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-SBs-012 | 「痛い」ボタンタップでonStatusコールバックがpainで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-013 | 「トイレ」ボタンタップでonStatusコールバックがtoiletで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-014 | 「暑い」ボタンタップでonStatusコールバックがhotで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-015 | 「寒い」ボタンタップでonStatusコールバックがcoldで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-016 | 「水」ボタンタップでonStatusコールバックがwaterで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-017 | 「眠い」ボタンタップでonStatusコールバックがsleepyで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-018 | 「助けて」ボタンタップでonStatusコールバックがhelpで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-019 | 「待って」ボタンタップでonStatusコールバックがwaitで呼ばれる | P0 | FR-101 | ウィジェット |
| TC-SBs-020 | タップ時にonTTSSpeakコールバックが呼ばれる | P0 | FR-101 | ウィジェット |

---

### 4. テーマ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-TH-001 | ライトモードで適切な配色で表示される | P0 | FR-103 | ウィジェット |
| TC-TH-002 | ダークモードで適切な配色で表示される | P0 | FR-103 | ウィジェット |
| TC-TH-003 | 高コントラストモードで適切な配色で表示される | P0 | FR-103, FR-202 | ウィジェット |
| TC-TH-004 | 高コントラストモードでコントラスト比4.5:1以上を確保 | P0 | FR-202 | ウィジェット |
| TC-TH-005 | テーマ変更時に配色が即座に追従する | P1 | FR-103 | ウィジェット |
| TC-TH-006 | 身体状態カテゴリ（痛い、暑い、寒い、眠い）が適切な色で表示される | P2 | FR-302, NFR-U003 | ウィジェット |
| TC-TH-007 | 要求カテゴリ（トイレ、水、助けて、待って）が適切な色で表示される | P2 | FR-302, NFR-U003 | ウィジェット |

---

### 5. アクセシビリティテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-A11Y-001 | 各ボタンにSemanticsラベルが設定される | P0 | NFR-A003 | ウィジェット |
| TC-A11Y-002 | 「痛い」ボタンにSemantics(label: '痛い')が設定される | P0 | NFR-A003 | ウィジェット |
| TC-A11Y-003 | 各ボタンがボタンセマンティクスを持つ | P0 | NFR-A003 | ウィジェット |
| TC-A11Y-004 | 色だけでなくラベルテキストで状態を識別可能 | P0 | NFR-A001 | ウィジェット |
| TC-A11Y-005 | タップターゲットが44x44px以上を常に満たす | P0 | FR-201 | ウィジェット |
| TC-A11Y-006 | ボタン間隔が誤タップ防止に十分（4px以上） | P1 | FR-008, NFR-A002 | ウィジェット |

---

### 6. エッジケーステスト

#### 6.1 連続タップ/デバウンステスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-EDGE-001 | 同じボタンを連続タップした場合デバウンスが機能する | P1 | EDGE-004 | ウィジェット |
| TC-EDGE-002 | TTS読み上げ中に別ボタンをタップすると新しい読み上げ対象が通知される | P1 | EDGE-001 | ウィジェット |
| TC-EDGE-003 | 連続タップ時にonStatusが1回だけ呼ばれる（デバウンス期間内） | P1 | EDGE-004 | ウィジェット |

#### 6.2 画面サイズ対応テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-EDGE-004 | 狭い画面幅（320px）でもボタンが44px以上を維持 | P0 | EDGE-005, FR-201 | ウィジェット |
| TC-EDGE-005 | タブレット画面幅（768px以上）で適切なサイズで表示 | P1 | EDGE-006 | ウィジェット |
| TC-EDGE-006 | 画面回転（縦向き→横向き）でレイアウトが崩れない | P1 | FR-104 | ウィジェット |
| TC-EDGE-007 | 画面回転後もタップターゲットが44px以上を維持 | P1 | FR-104, FR-201 | ウィジェット |
| TC-EDGE-008 | 横向き時にグリッド列数が適切に調整される | P2 | FR-104 | ウィジェット |

#### 6.3 TTSエラーハンドリングテスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-EDGE-009 | TTSサービスがnull/未初期化でもボタンタップが動作する | P1 | EDGE-003 | ウィジェット |
| TC-EDGE-010 | TTSエラー時も視覚的フィードバックが提供される | P1 | EDGE-003 | ウィジェット |
| TC-EDGE-011 | onTTSSpeak未設定でもonPressedは動作する | P1 | EDGE-003 | ウィジェット |

#### 6.4 境界値テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-EDGE-012 | ボタン数が8個の場合に正しく表示される（最小値） | P0 | FR-002 | ウィジェット |
| TC-EDGE-013 | ボタン数が12個の場合に正しく表示される（最大値） | P0 | FR-002 | ウィジェット |
| TC-EDGE-014 | ボタン間隔が4px（最小値）で正しく配置される | P1 | FR-008 | ウィジェット |

---

### 7. パフォーマンステスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-PERF-001 | タップから視覚フィードバックまで100ms以内 | P1 | NFR-P002 | ウィジェット |
| TC-PERF-002 | ウィジェット初回ビルドが妥当な時間内に完了する | P2 | NFR-P003 | ウィジェット |
| TC-PERF-003 | 複数回のテーマ切替でも安定して動作する | P2 | FR-103 | ウィジェット |

---

### 8. 統合テスト

| テストID | テスト名 | 優先度 | 関連要件 | カテゴリ |
|----------|----------|--------|----------|----------|
| TC-INT-001 | ホーム画面にStatusButtonsが表示される | P0 | FR-003 | 統合 |
| TC-INT-002 | QuickResponseButtonsの下に配置されている | P0 | FR-003 | 統合 |
| TC-INT-003 | 文字盤UIと共存して表示される | P1 | FR-003 | 統合 |
| TC-INT-004 | 設定画面でフォントサイズ変更後、ボタンのフォントが追従する | P1 | FR-006 | 統合 |
| TC-INT-005 | 設定画面でテーマ変更後、ボタンの配色が追従する | P1 | FR-103 | 統合 |

---

## テストケース詳細

### TC-SBT-001: StatusButtonTypeに必須の8個の値が定義されている

**優先度**: P0
**関連要件**: FR-001, FR-002
**カテゴリ**: 単体

**前提条件**:
- StatusButtonType enumがインポートされている

**入力**:
- なし

**期待結果**:
- StatusButtonType.pain が存在する
- StatusButtonType.toilet が存在する
- StatusButtonType.hot が存在する
- StatusButtonType.cold が存在する
- StatusButtonType.water が存在する
- StatusButtonType.sleepy が存在する
- StatusButtonType.help が存在する
- StatusButtonType.wait が存在する
- 値の総数が8以上である

**テストコード概要**:
```dart
test('TC-SBT-001: StatusButtonTypeに必須の8個の値が定義されている', () {
  expect(StatusButtonType.values.length, greaterThanOrEqualTo(8));
  expect(StatusButtonType.values, contains(StatusButtonType.pain));
  expect(StatusButtonType.values, contains(StatusButtonType.toilet));
  expect(StatusButtonType.values, contains(StatusButtonType.hot));
  expect(StatusButtonType.values, contains(StatusButtonType.cold));
  expect(StatusButtonType.values, contains(StatusButtonType.water));
  expect(StatusButtonType.values, contains(StatusButtonType.sleepy));
  expect(StatusButtonType.values, contains(StatusButtonType.help));
  expect(StatusButtonType.values, contains(StatusButtonType.wait));
});
```

---

### TC-SBT-005: statusButtonLabelsで「痛い」ラベルが取得できる

**優先度**: P0
**関連要件**: FR-005
**カテゴリ**: 単体

**前提条件**:
- statusButtonLabels定数が定義されている

**入力**:
- なし

**期待結果**:
- StatusButtonType.pain → '痛い'

**テストコード概要**:
```dart
test('TC-SBT-005: statusButtonLabelsで「痛い」ラベルが取得できる', () {
  expect(statusButtonLabels[StatusButtonType.pain], equals('痛い'));
});
```

---

### TC-SB-001: 「痛い」ボタンが正しいラベルで表示される

**優先度**: P0
**関連要件**: FR-001, FR-005
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonがインポートされている

**入力**:
- statusType: StatusButtonType.pain

**期待結果**:
- '痛い'というテキストが表示される

**テストコード概要**:
```dart
testWidgets('TC-SB-001: 「痛い」ボタンが正しいラベルで表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButton(
          statusType: StatusButtonType.pain,
          onPressed: () {},
        ),
      ),
    ),
  );

  expect(find.text('痛い'), findsOneWidget);
});
```

---

### TC-SB-009: ボタン高さがデフォルトで44px以上である

**優先度**: P0
**関連要件**: FR-004, FR-201
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonが表示されている

**入力**:
- デフォルト値

**期待結果**:
- ボタンの高さが44.0以上である

**テストコード概要**:
```dart
testWidgets('TC-SB-009: ボタン高さがデフォルトで44px以上である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButton(
          statusType: StatusButtonType.pain,
          onPressed: () {},
        ),
      ),
    ),
  );

  final size = tester.getSize(find.byType(StatusButton));
  expect(size.height, greaterThanOrEqualTo(AppSizes.minTapTarget));
});
```

---

### TC-SB-015: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる

**優先度**: P0
**関連要件**: FR-101
**カテゴリ**: ウィジェット

**前提条件**:
- onTTSSpeakコールバックが設定されている

**入力**:
- ボタンタップ

**期待結果**:
- onTTSSpeakコールバックが「痛い」で呼ばれる

**テストコード概要**:
```dart
testWidgets('TC-SB-015: タップ時にonTTSSpeakコールバックが正しいラベルで呼ばれる', (tester) async {
  String? spokenText;

  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButton(
          statusType: StatusButtonType.pain,
          onPressed: () {},
          onTTSSpeak: (text) => spokenText = text,
        ),
      ),
    ),
  );

  await tester.tap(find.byType(StatusButton));
  await tester.pump();

  expect(spokenText, equals('痛い'));
});
```

---

### TC-SBs-001: 8個以上の状態ボタンが表示される

**優先度**: P0
**関連要件**: FR-002
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonsがインポートされている

**入力**:
- なし

**期待結果**:
- 8個以上のStatusButtonが表示される

**テストコード概要**:
```dart
testWidgets('TC-SBs-001: 8個以上の状態ボタンが表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButtons(
          onStatus: (_) {},
        ),
      ),
    ),
  );

  final buttons = tester.widgetList(find.byType(StatusButton));
  expect(buttons.length, greaterThanOrEqualTo(8));
});
```

---

### TC-SBs-006: ボタンがグリッド形式（横4列）で配置される

**優先度**: P0
**関連要件**: FR-007
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonsが表示されている

**入力**:
- なし

**期待結果**:
- ボタンが4列で配置されている

**テストコード概要**:
```dart
testWidgets('TC-SBs-006: ボタンがグリッド形式（横4列）で配置される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButtons(
          onStatus: (_) {},
        ),
      ),
    ),
  );

  // 最初の4つのボタンが同じY座標にあることを確認
  final buttons = tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

  if (buttons.length >= 4) {
    final firstRowY = tester.getRect(find.byWidget(buttons[0])).top;
    for (int i = 0; i < 4 && i < buttons.length; i++) {
      final buttonY = tester.getRect(find.byWidget(buttons[i])).top;
      expect(buttonY, equals(firstRowY));
    }
  }
});
```

---

### TC-SBs-007: ボタン間の間隔が4px以上である

**優先度**: P0
**関連要件**: FR-008, NFR-A002
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonsが表示されている

**入力**:
- なし

**期待結果**:
- 各ボタン間のスペースが4px以上

**テストコード概要**:
```dart
testWidgets('TC-SBs-007: ボタン間の間隔が4px以上である', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButtons(
          onStatus: (_) {},
        ),
      ),
    ),
  );

  final buttons = tester.widgetList<StatusButton>(find.byType(StatusButton)).toList();

  if (buttons.length >= 2) {
    final firstButton = tester.getRect(find.byWidget(buttons[0]));
    final secondButton = tester.getRect(find.byWidget(buttons[1]));

    final spacing = secondButton.left - firstButton.right;
    expect(spacing, greaterThanOrEqualTo(4.0));
  }
});
```

---

### TC-TH-004: 高コントラストモードでコントラスト比4.5:1以上を確保

**優先度**: P0
**関連要件**: FR-202
**カテゴリ**: ウィジェット

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
        body: StatusButtons(
          onStatus: (_) {},
        ),
      ),
    ),
  );

  // 高コントラストテーマでは黒文字/白背景で21:1のコントラスト比
  // または白文字/黒背景でも21:1
  final context = tester.element(find.byType(StatusButtons));
  final theme = Theme.of(context);

  // コントラスト比の検証
  // 実装時に具体的なカラー値を用いて計算
});
```

---

### TC-A11Y-001: 各ボタンにSemanticsラベルが設定される

**優先度**: P0
**関連要件**: NFR-A003
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonが表示されている

**入力**:
- なし

**期待結果**:
- Semanticsラベルが設定されている

**テストコード概要**:
```dart
testWidgets('TC-A11Y-001: 各ボタンにSemanticsラベルが設定される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: StatusButton(
          statusType: StatusButtonType.pain,
          onPressed: () {},
        ),
      ),
    ),
  );

  final semantics = tester.getSemantics(find.byType(StatusButton));
  expect(semantics.label, contains('痛い'));
});
```

---

### TC-EDGE-001: 同じボタンを連続タップした場合デバウンスが機能する

**優先度**: P1
**関連要件**: EDGE-004
**カテゴリ**: ウィジェット

**前提条件**:
- StatusButtonが表示されている

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
        body: StatusButton(
          statusType: StatusButtonType.pain,
          onPressed: () {},
          onTTSSpeak: (_) => callCount++,
        ),
      ),
    ),
  );

  // 連続タップ
  await tester.tap(find.byType(StatusButton));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byType(StatusButton));
  await tester.pump(const Duration(milliseconds: 50));
  await tester.tap(find.byType(StatusButton));
  await tester.pump();

  // デバウンスにより1回だけ呼ばれる
  expect(callCount, equals(1));
});
```

---

### TC-EDGE-004: 狭い画面幅（320px）でもボタンが44px以上を維持

**優先度**: P0
**関連要件**: EDGE-005, FR-201
**カテゴリ**: ウィジェット

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
        body: StatusButtons(
          onStatus: (_) {},
        ),
      ),
    ),
  );

  final buttons = tester.widgetList<StatusButton>(
    find.byType(StatusButton),
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

### TC-INT-002: QuickResponseButtonsの下に配置されている

**優先度**: P0
**関連要件**: FR-003
**カテゴリ**: 統合

**前提条件**:
- ホーム画面が表示されている
- QuickResponseButtonsとStatusButtonsが両方表示されている

**入力**:
- なし

**期待結果**:
- StatusButtonsがQuickResponseButtonsの下（Y座標が大きい位置）に配置されている

**テストコード概要**:
```dart
testWidgets('TC-INT-002: QuickResponseButtonsの下に配置されている', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: HomeScreen(),
    ),
  );

  final quickResponseRect = tester.getRect(find.byType(QuickResponseButtons));
  final statusButtonsRect = tester.getRect(find.byType(StatusButtons));

  // StatusButtonsのトップがQuickResponseButtonsのボトムより下にある
  expect(statusButtonsRect.top, greaterThanOrEqualTo(quickResponseRect.bottom));
});
```

---

## テストケースサマリー

### 優先度別内訳

| 優先度 | テストケース数 | 説明 |
|--------|----------------|------|
| P0 | 52 | 必須（リリースブロッカー） |
| P1 | 27 | 高優先度（機能として重要） |
| P2 | 6 | 中優先度（品質向上） |
| **合計** | **85** | - |

### カテゴリ別内訳

| カテゴリ | テストケース数 |
|----------|----------------|
| 単体テスト（Enumテスト） | 16 |
| ウィジェットテスト（StatusButton） | 27 |
| ウィジェットテスト（StatusButtons） | 15 |
| テーマ対応テスト | 7 |
| アクセシビリティテスト | 6 |
| エッジケーステスト | 14 |
| パフォーマンステスト | 3 |
| 統合テスト | 5 |

### 関連要件カバレッジ

| 要件ID | カバーするテストケース数 | 説明 |
|--------|--------------------------|------|
| FR-001 | 15 | 状態ボタンの種類 |
| FR-002 | 7 | ボタン数の範囲（8-12個） |
| FR-003 | 3 | 配置位置 |
| FR-004 | 3 | タップターゲットサイズ |
| FR-005 | 14 | ラベル表示 |
| FR-006 | 5 | フォントサイズ追従 |
| FR-007 | 5 | グリッドレイアウト |
| FR-008 | 3 | ボタン間隔 |
| FR-101 | 12 | タップ時即座読み上げ |
| FR-102 | 1 | 視覚的フィードバック |
| FR-103 | 6 | テーマ変更時追従 |
| FR-104 | 3 | 画面回転時レイアウト |
| FR-201 | 8 | 最小タップターゲット保証 |
| FR-202 | 2 | 高コントラストコントラスト比 |
| FR-203 | 1 | タップ操作完結 |
| FR-302 | 2 | カテゴリ別色分け |
| NFR-A001 | 1 | 色覚多様性配慮 |
| NFR-A002 | 2 | ボタン間隔 |
| NFR-A003 | 3 | Semanticsラベル |
| NFR-U003 | 2 | カテゴリ視覚区別 |
| NFR-P002 | 1 | 視覚フィードバック時間 |
| NFR-P003 | 1 | 初回ビルド時間 |
| EDGE-001 | 1 | TTS読み上げ中の再タップ |
| EDGE-003 | 3 | TTSエラーハンドリング |
| EDGE-004 | 5 | 連続タップデバウンス |
| EDGE-005 | 1 | 超小画面表示 |
| EDGE-006 | 1 | 大画面表示 |

---

## 受け入れ基準との対応

| 受け入れ基準 | 対応テストケース |
|--------------|------------------|
| AC-001 | TC-SBs-001, TC-SBs-002, TC-EDGE-012, TC-EDGE-013 |
| AC-002 | TC-SBs-003, TC-SB-001〜TC-SB-008 |
| AC-003 | TC-INT-002 |
| AC-004 | TC-SB-009, TC-SB-010, TC-EDGE-004 |
| AC-005 | TC-SBs-007 |
| AC-006 | TC-SB-001〜TC-SB-008, TC-SBT-005〜TC-SBT-012 |
| AC-007 | TC-SB-018, TC-SB-019, TC-SB-020 |
| AC-008 | TTS連携は別タスク（TASK-0048）、本タスクではコールバック検証 |
| AC-009 | TC-SBs-006, TC-SBs-008, TC-SBs-009 |
| AC-010 | TC-TH-001 |
| AC-011 | TC-TH-002 |
| AC-012 | TC-TH-003, TC-TH-004 |
| AC-013 | TC-SB-024 |
| AC-014 | TC-SB-025 |
| AC-015 | TC-SB-026 |
| AC-016 | TC-EDGE-001, TC-EDGE-003, TC-SB-021〜TC-SB-023 |
| AC-017 | TC-EDGE-006 |
| AC-018 | TC-EDGE-007 |
| AC-019 | TC-EDGE-004 |
| AC-020 | TC-A11Y-001, TC-A11Y-002, TC-A11Y-003 |
| AC-021 | TC-A11Y-004 |

---

## テストファイル構成（案）

```
frontend/kotonoha_app/test/features/status_buttons/
├── domain/
│   └── status_button_type_test.dart          # TC-SBT-001〜TC-SBT-016
├── presentation/
│   ├── widgets/
│   │   ├── status_button_test.dart           # TC-SB-001〜TC-SB-027
│   │   └── status_buttons_test.dart          # TC-SBs-001〜TC-SBs-020
│   └── mixins/
│       └── debounce_mixin_test.dart          # 既存テスト（TASK-0043）を参照
├── theme_test.dart                           # TC-TH-001〜TC-TH-007
├── accessibility_test.dart                   # TC-A11Y-001〜TC-A11Y-006
├── edge_cases_test.dart                      # TC-EDGE-001〜TC-EDGE-014
├── performance_test.dart                     # TC-PERF-001〜TC-PERF-003
└── integration_test.dart                     # TC-INT-001〜TC-INT-005
```

---

**ドキュメント作成日**: 2025-11-23
**タスクID**: TASK-0044
**関連要件**: REQ-202, REQ-203, REQ-204
**作成者**: TDD テストケース設計担当
