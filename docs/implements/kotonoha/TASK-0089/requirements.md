# TASK-0089: 文字盤UI最適化 - 要件定義書

## タスク情報

- **タスクID**: TASK-0089
- **タスクタイプ**: TDD
- **推定工数**: 8時間
- **要件名**: kotonoha
- **関連要件**: NFR-003, REQ-5001, NFR-202
- **依存タスク**: TASK-0088（パフォーマンス計測・プロファイリング - 完了済み）
- **実行日**: 2025-12-01

## 1. 機能の概要

### 概要 🔵

文字盤UI最適化は、kotonohaアプリの中核機能である五十音文字盤ウィジェットのレンダリングパフォーマンスを最適化し、NFR-003（100ms以内のタップ応答）を確実に達成するためのタスクです。

- **何をする機能か**: 文字盤ウィジェットの再レンダリング最適化、constコンストラクタの活用、RepaintBoundaryの適切な配置、タップフィードバックアニメーションの最適化、メモリ使用量の削減
- **どのような問題を解決するか**: 不要な再レンダリングによるUIの遅延、メモリリーク、アニメーションのカクつきを排除し、ユーザーがストレスなく文字入力できる環境を提供
- **想定されるユーザー**: 発話困難な方（脳梗塞・ALS・筋疾患など）で、タブレットのタップ操作がある程度可能な方
- **システム内での位置づけ**: 文字入力機能のコアUIコンポーネント（CharacterBoardWidget、CharacterButton）

### 参照元 🔵

- **参照したEARS要件**:
  - NFR-003: 文字盤タップから入力欄への文字反映までの遅延を100ms以内
  - REQ-5001: タップターゲット44px × 44px以上
  - NFR-202: 推奨60px × 60px以上
  - REQ-001: 五十音配列の文字盤UI表示
  - REQ-002: 文字盤の文字をタップすると入力欄に文字を追加

- **参照した設計文書**:
  - `docs/design/kotonoha/architecture.md`「非機能要件への対応 - パフォーマンス」セクション
  - `docs/design/kotonoha/dataflow.md`「文字入力フロー」セクション

- **参照した既存実装**:
  - `frontend/kotonoha_app/lib/features/character_board/presentation/widgets/character_board_widget.dart`
  - `frontend/kotonoha_app/lib/features/character_board/domain/character_data.dart`
  - `frontend/kotonoha_app/lib/features/character_board/providers/input_buffer_provider.dart`

## 2. 現状分析

### 既存実装の構造 🔵

**CharacterBoardWidget** (StatefulWidget):
- 五十音カテゴリ（基本、濁音、半濁音、小文字、記号）のタブ切り替え
- GridView.builderによる文字ボタンのグリッド表示
- 各文字ボタンはCharacterButtonウィジェットで実装

**CharacterButton** (StatelessWidget):
- Material + InkWellによるタップフィードバック
- Semanticsによるアクセシビリティ対応
- フォントサイズ、有効/無効状態の管理

**InputBufferNotifier** (StateNotifier):
- 文字入力バッファの状態管理
- 同期的な状態更新でUI応答性を維持（100ms以内）

### 現状の課題 🔵

#### 1. 不要な再レンダリング
- カテゴリタブ切り替え時に全体が再レンダリング
- 入力バッファ更新時にCharacterBoardWidget全体が再レンダリング
- constコンストラクタが部分的にしか使用されていない

#### 2. アニメーション最適化の余地
- InkWellのsplash効果がパフォーマンスに影響する可能性
- タップフィードバックのアニメーション設定が最適化されていない

#### 3. メモリ最適化の確認不足
- 大量の文字ボタン（基本50個、濁音20個など）のメモリ使用状況が未検証
- ウィジェットツリーの深さによるメモリ使用量

#### 4. RepaintBoundaryの未使用
- 文字ボタン個別の再描画範囲が分離されていない
- GridView全体が再描画される可能性

## 3. 最適化要件

### REQ-OPT-001: constコンストラクタの活用 🔵

**要件**:
- CharacterButtonウィジェットでconstコンストラクタを最大限活用し、不要な再ビルドを防ぐ

**受け入れ基準**:
- CharacterDataの文字リストがconstで定義されている（既に実装済み）
- CharacterButton自体がconstで構築可能（状態を持たないStatelessWidget）
- 親ウィジェットの再ビルド時にCharacterButtonが再ビルドされない

**技術詳細**:
```dart
// 現状（改善前）
CharacterButton(
  key: ValueKey('character_button_$character'),
  character: character,
  onTap: widget.isEnabled ? () => widget.onCharacterTap(character) : null,
  size: buttonSize,
  isEnabled: widget.isEnabled,
  fontSize: widget.fontSize,
)

// 改善後（const使用）
// onTapがクロージャのためconstにできないが、
// 他の不変パラメータを明示的にconstとする
```

### REQ-OPT-002: RepaintBoundaryの適切な配置 🔵

**要件**:
- CharacterButtonを個別のRepaintBoundaryで囲み、タップ時のリペイント範囲を限定する
- カテゴリタブ部分とグリッド部分を分離してリペイント範囲を最小化

**受け入れ基準**:
- 1つのCharacterButtonをタップしても他のボタンが再描画されない
- カテゴリタブ切り替え時にグリッド部分のみが再描画される
- Flutter DevToolsのRepaint Rainbowで検証できる

**技術詳細**:
```dart
// GridView.builderのitemBuilder内
itemBuilder: (context, index) {
  final character = characters[index];
  if (character.isEmpty) {
    return const SizedBox.shrink();
  }
  return RepaintBoundary(
    child: CharacterButton(
      // ... パラメータ
    ),
  );
}
```

### REQ-OPT-003: ウィジェットツリーの最適化 🔵

**要件**:
- ウィジェットツリーの深さを最小化し、レンダリングコストを削減
- 不要なContainerやColumnを削除

**受け入れ基準**:
- CharacterButton内のウィジェット階層が5層以内
- 不要なSemanticsラッパーの削除（必要最小限のみ使用）
- Flutter DevToolsのWidget Inspectorで検証

### REQ-OPT-004: タップフィードバックアニメーションの最適化 🔵

**要件**:
- InkWellのsplash効果を軽量化し、100ms応答を確保
- タップフィードバックの視覚効果を維持しつつパフォーマンスを最適化

**受け入れ基準**:
- タップから入力欄反映まで100ms以内（NFR-003）
- splash半径、アニメーション時間の最適化
- ユーザビリティを損なわない視覚フィードバック

**技術詳細**:
```dart
InkWell(
  onTap: isEnabled ? onTap : null,
  borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
  splashFactory: InkRipple.splashFactory, // デフォルトから変更しない
  // splashColorやhighlightColorは必要に応じて調整
  child: Container(
    // ...
  ),
)
```

### REQ-OPT-005: メモリ使用量の確認・最適化 🔵

**要件**:
- 文字盤ウィジェット（基本50個、濁音20個など）のメモリ使用量を計測
- メモリリークがないことを確認
- 不要なオブジェクトの保持を排除

**受け入れ基準**:
- Flutter DevToolsのMemory Profilerでメモリリークがない
- カテゴリ切り替え前後でメモリ使用量が安定している
- 文字盤表示中のメモリ使用量が合理的な範囲内（10MB以下）

### REQ-OPT-006: Riverpod状態管理の最適化 🔵

**要件**:
- inputBufferProviderの変更が文字盤ウィジェットを不要に再ビルドしない
- ConsumerWidgetの使用を最小限にし、必要な部分のみwatch

**受け入れ基準**:
- CharacterBoardWidgetがinputBufferProviderをwatchしていない
- 入力バッファ更新時にCharacterBoardWidgetが再ビルドされない
- 文字タップ時のonCharacterTapコールバックのみが実行される

**現状確認**:
- CharacterBoardWidgetは現在StatefulWidgetで、Riverpodを直接使用していない（良好）
- 親ウィジェット側でinputBufferProviderをwatchして、onCharacterTapコールバックを渡す設計

## 4. 制約条件

### パフォーマンス要件 🔵

| 要件 | 説明 | 参照 |
|------|------|------|
| NFR-003 | 文字盤タップから入力欄反映まで100ms以内 | kotonoha-requirements.md |
| REQ-5001 | タップターゲット44px × 44px以上 | kotonoha-requirements.md |
| NFR-202 | 推奨タップターゲット60px × 60px以上 | kotonoha-requirements.md |

### アーキテクチャ制約 🔵

- **Flutter 3.38.1**: 最新のパフォーマンス最適化機能を活用
- **Riverpod 2.x**: StateNotifierによる同期的な状態管理
- **OS標準TTS**: ローカル処理で低遅延
- **ネイティブFlutterウィジェット**: WebViewなどを使用しない

### コーディング規約 🔵

- **Null Safety有効**
- **constコンストラクタを可能な限り使用**
- **ウィジェットはkeyパラメータを持つ**
- **flutter_lints準拠**

### テスト制約 🟡

- **integration_test**: パフォーマンス計測にはStopwatchを使用
- **推奨環境**: iOS Simulator / Android Emulator / 実機
- **計測精度**: ミリ秒単位

## 5. 想定される使用例

### UC-001: 文字盤タップ応答の最適化 🔵

**前提条件**:
- アプリが起動し、文字盤が表示されている
- 基本カテゴリ（あ〜ん）が選択されている

**操作**:
1. ユーザーが「あ」の文字ボタンをタップ
2. システムが入力バッファに「あ」を追加
3. 入力欄に「あ」が表示される

**期待結果**:
- タップから入力欄反映まで100ms以内
- 他の文字ボタンは再描画されない
- タップフィードバック（splash効果）が視認できる
- メモリ使用量が増加しない

### UC-002: カテゴリ切り替え時の最適化 🔵

**前提条件**:
- アプリが起動し、基本カテゴリが表示されている

**操作**:
1. ユーザーが「濁音」タブをタップ
2. システムが濁音カテゴリの文字を表示

**期待結果**:
- カテゴリタブ切り替え時にグリッド部分のみが再描画される
- タブ部分は再描画されない
- 切り替えがスムーズ（カクつきがない）
- メモリ使用量が安定している

### UC-003: 連続タップ時の最適化 🔵

**前提条件**:
- アプリが起動し、文字盤が表示されている

**操作**:
1. ユーザーが「あ」「い」「う」「え」「お」を連続でタップ

**期待結果**:
- 各タップが100ms以内で応答
- 連続タップ時もパフォーマンスが低下しない
- アニメーションがスキップされずに表示される
- メモリリークが発生しない

## 6. 最適化手法

### 6.1. constコンストラクタの活用 🔵

**対象**:
- CharacterData: 既にconstで定義済み ✅
- CharacterButton: constコンストラクタで構築（onTap以外）

**効果**:
- 不要な再ビルドの削減
- メモリ使用量の削減（同じインスタンスを再利用）

### 6.2. RepaintBoundaryの配置 🔵

**配置箇所**:
1. CharacterButton個別
2. カテゴリタブ部分とグリッド部分の境界

**効果**:
- リペイント範囲の限定
- タップ時の再描画コスト削減

### 6.3. ウィジェットツリーの最適化 🔵

**手法**:
- 不要なContainerの削除
- SizedBox.shrink()の活用（空要素）
- Semanticsの最適化（必要最小限）

**効果**:
- レンダリングコストの削減
- ウィジェットツリーの深さ削減

### 6.4. タップフィードバックの最適化 🔵

**手法**:
- InkWellのsplash設定調整
- Material elevationの最適化
- borderRadiusの再利用

**効果**:
- タップ応答の高速化
- 視覚フィードバックの維持

### 6.5. メモリ最適化 🔵

**手法**:
- ValueKeyの最適化（必要最小限）
- 不要なオブジェクト保持の削除
- Stateless/Statefulの適切な選択

**効果**:
- メモリ使用量の削減
- メモリリークの防止

## 7. EARS要件・設計文書との対応関係

### 参照したEARS要件

| 要件ID | 要件名 | 信頼性 |
|--------|--------|--------|
| NFR-003 | 文字盤タップ応答100ms以内 | 🔵 |
| REQ-001 | 五十音配列の文字盤UI表示 | 🔵 |
| REQ-002 | タップで入力欄に文字追加 | 🔵 |
| REQ-5001 | タップターゲット44px以上 | 🔵 |
| NFR-202 | 推奨タップターゲット60px以上 | 🔵 |

### 参照した設計文書

| 文書 | 該当セクション | 信頼性 |
|------|---------------|--------|
| architecture.md | 非機能要件への対応 - パフォーマンス | 🔵 |
| architecture.md | コンポーネント構成 - フロントエンド | 🔵 |
| dataflow.md | 文字入力フロー | 🔵 |

### 既存実装との整合性

| ファイル | 内容 | 関連性 |
|----------|------|--------|
| `character_board_widget.dart` | 五十音文字盤ウィジェット | ✅ 最適化対象 |
| `character_data.dart` | 文字データ定義（constで定義済み） | ✅ 既に最適化済み |
| `input_buffer_provider.dart` | 入力バッファ状態管理 | ✅ 同期的な状態更新 |
| `app_sizes.dart` | サイズ定数定義 | ✅ 最適化に使用 |

## 8. 受け入れ基準

### AC-001: constコンストラクタの活用 🔵

- [ ] CharacterButtonがconstコンストラクタで構築可能（onTap以外）
- [ ] CharacterDataが既にconstで定義されている ✅
- [ ] 親ウィジェットの再ビルド時にCharacterButtonが再ビルドされない

### AC-002: RepaintBoundaryの適切な配置 🔵

- [ ] CharacterButton個別にRepaintBoundaryが配置されている
- [ ] カテゴリタブとグリッドが分離されている
- [ ] Flutter DevToolsのRepaint Rainbowで検証済み

### AC-003: ウィジェットツリーの最適化 🔵

- [ ] CharacterButton内のウィジェット階層が5層以内
- [ ] 不要なContainerが削除されている
- [ ] Flutter DevToolsのWidget Inspectorで検証済み

### AC-004: タップフィードバックアニメーションの最適化 🔵

- [ ] タップから入力欄反映まで100ms以内（NFR-003）
- [ ] splash効果が軽量化されている
- [ ] ユーザビリティを損なわない視覚フィードバック

### AC-005: メモリ使用量の確認・最適化 🔵

- [ ] Flutter DevToolsのMemory Profilerでメモリリークがない
- [ ] カテゴリ切り替え前後でメモリ使用量が安定している
- [ ] 文字盤表示中のメモリ使用量が10MB以下

### AC-006: パフォーマンステスト合格 🔵

- [ ] integration_testで文字盤タップ応答が100ms以内
- [ ] 10文字連続入力でも各タップが100ms以内
- [ ] カテゴリ切り替えがスムーズ（カクつきなし）

### AC-007: コード品質 🔵

- [ ] flutter_lints準拠
- [ ] constコンストラクタを可能な限り使用
- [ ] ウィジェットがkeyパラメータを持つ

## 9. 品質判定

### 判定結果: ✅ 高品質

| 評価項目 | ステータス |
|----------|------------|
| 要件の曖昧さ | なし（NFR-003で明確に定義） |
| 入出力定義 | 完全（既存実装を基に最適化要件が明確） |
| 制約条件 | 明確（パフォーマンス数値が具体的） |
| 実装可能性 | 確実（Flutter標準の最適化手法を活用） |

## 10. 技術的補足

### Flutter パフォーマンス最適化のベストプラクティス 🔵

#### 1. constコンストラクタ
- ビルド時に不変なウィジェットをキャッシュ
- 再ビルド時に新しいインスタンスを作成しない
- メモリ使用量とCPU使用量を削減

#### 2. RepaintBoundary
- ウィジェットの再描画範囲を限定
- タップ時のリペイントを1つのボタンに限定
- 大量のウィジェットがある場合に効果的

#### 3. const Key vs ValueKey
- constで構築可能な場合はKeyも不要
- 動的リストの場合はValueKeyを使用
- 文字盤の場合: 文字は固定なのでValueKeyが適切

#### 4. StatelessWidget vs StatefulWidget
- CharacterButton: StatelessWidget（状態を持たない）
- CharacterBoardWidget: StatefulWidget（カテゴリ選択状態を持つ）

#### 5. GridView.builder
- 既にbuilderパターンを使用（遅延ロード）
- 画面外のウィジェットは構築されない
- パフォーマンスに優れている ✅

### パフォーマンス計測方法 🔵

#### Flutter DevTools
1. **Performance Overlay**: FPS表示、ジャンクの検出
2. **Repaint Rainbow**: リペイント範囲の可視化
3. **Widget Inspector**: ウィジェットツリーの確認
4. **Memory Profiler**: メモリ使用量、リークの検出

#### integration_test
```dart
final stopwatch = Stopwatch()..start();
await tester.tap(find.byKey(Key('character_button_あ')));
await tester.pumpAndSettle();
stopwatch.stop();
expect(stopwatch.elapsedMilliseconds, lessThan(100));
```

## 信頼性レベル

🔵 青信号 - EARS要件定義書（NFR-003, REQ-5001, NFR-202）および既存実装に基づく確実な要件

---

次のお勧めステップ: `/tsumiki:tdd-testcases` でテストケースの洗い出しを行います。
