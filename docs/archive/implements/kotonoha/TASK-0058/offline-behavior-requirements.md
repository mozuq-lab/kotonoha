# TASK-0058: オフライン動作確認 - TDD要件定義書

## 機能概要

オフライン環境において、基本機能（文字盤入力、定型文選択、TTS読み上げ、大ボタン、緊急ボタン、ローカルストレージ）が正常動作し、AI変換機能が適切に無効化されることを検証・保証します。

**目的**: ネットワーク切断時にも、kotonohaアプリの主要コミュニケーション機能がシームレスに利用可能であることを確認し、オフライン時のユーザー体験を保証する。

**対象ユーザー**: 発話困難な方が、インターネット接続がない環境（病院、施設、移動中など）でもコミュニケーション手段を失わないようにする。

---

## 関連要件との対応表

| 要件ID | 要件内容 | 信頼性レベル | 実装範囲 |
|--------|---------|-------------|---------|
| **REQ-1001** | 文字盤入力・定型文・履歴・TTSをオフライン環境で利用可能にする | 🔵 青信号 | オフライン時の基本機能動作確認 |
| **REQ-1002** | オフライン時にAI変換が利用不可であることを明示する | 🔵 青信号 | AI変換ボタンの無効化・グレーアウト表示 |
| **REQ-1003** | オフライン時のAI変換ボタン押下時に、元の文をそのまま利用できるフォールバック動作を提供する | 🔵 青信号 | AI変換フォールバック動作の確認 |
| **REQ-3004** | ネットワーク接続がない状態にある場合、AI変換ボタンを無効化またはグレーアウト表示する | 🟡 黄信号 | AI変換ボタンの視覚的状態変更 |
| **NFR-303** | ネットワークエラー時にも基本機能（オフライン機能）が正常動作することを保証する | 🔵 青信号 | オフライン時のエラーハンドリング |
| **EDGE-001** | ネットワークタイムアウト時、分かりやすいエラーメッセージを表示し、再試行オプションを提供する | 🟡 黄信号 | オフライン表示・エラーメッセージ |

---

## 詳細要件

### 1. ネットワーク状態管理

#### 1.1 NetworkProvider統合
- **要件**: TASK-0057で実装されたNetworkProviderを活用し、ネットワーク状態（online/offline/checking）を全UIに反映する
- **根拠**: REQ-1002（オフライン時の明示）
- **実装内容**:
  - NetworkNotifierの`isAIConversionAvailable`ゲッターを使用
  - 状態変更時のリアルタイム反映
  - ProviderScopeでアプリ全体に状態を共有

#### 1.2 ネットワーク切断シミュレーション
- **要件**: テスト時にネットワーク切断をシミュレートし、オフライン状態を再現できる
- **根拠**: NFR-303（オフライン動作保証）
- **実装内容**:
  - `networkProvider.notifier.setOffline()`を使用した状態切り替え
  - 開発者向けデバッグメニューでのオフライン切り替え機能（オプション）
  - テストコードでのモック使用

---

### 2. オフライン時の基本機能動作確認

#### 2.1 文字盤入力
- **要件**: オフライン時も文字盤タップで文字入力が100ms以内に反映される
- **根拠**: REQ-1001, NFR-003（文字盤タップ応答100ms以内）
- **テスト項目**:
  - オフライン状態で五十音すべての文字が入力可能
  - タップから入力反映まで100ms以内
  - 削除・全消去ボタンが正常動作

#### 2.2 定型文選択・読み上げ
- **要件**: オフライン時も定型文一覧表示、選択、即座読み上げが動作する
- **根拠**: REQ-1001, REQ-101〜REQ-105
- **テスト項目**:
  - 定型文一覧が1秒以内に表示される
  - お気に入り優先表示が機能する
  - 定型文タップで即座読み上げが実行される
  - 定型文のCRUD操作（追加・編集・削除）が動作する

#### 2.3 大ボタン・状態ボタン
- **要件**: オフライン時も「はい」「いいえ」「わからない」および状態ボタンが即座読み上げを実行する
- **根拠**: REQ-1001, REQ-201〜REQ-204
- **テスト項目**:
  - 大ボタンタップで即座読み上げが実行される
  - 状態ボタンタップで即座読み上げが実行される
  - すべての画面で常時表示される

#### 2.4 緊急ボタン
- **要件**: オフライン時も緊急ボタンが2段階確認で動作し、緊急音・画面赤表示が実行される
- **根拠**: REQ-1001, REQ-301〜REQ-304
- **テスト項目**:
  - 緊急ボタンタップで確認ダイアログが表示される
  - 「はい」タップで緊急音が鳴る
  - 画面が赤く表示される
  - リセットボタンで通常画面に戻る

#### 2.5 TTS読み上げ
- **要件**: オフライン時もOS標準TTSが動作し、1秒以内に読み上げが開始される
- **根拠**: REQ-1001, REQ-401, NFR-001（TTS開始1秒以内）
- **テスト項目**:
  - 読み上げボタンタップで1秒以内に読み上げ開始
  - 読み上げ中断機能が動作する
  - TTS速度設定が反映される
  - OS音量0の場合に警告が表示される

#### 2.6 ローカルストレージ
- **要件**: オフライン時も定型文、設定、履歴がHive・shared_preferencesで保存・読み取りできる
- **根拠**: REQ-1001, REQ-5003（永続化機構）, NFR-101（端末内保存）
- **テスト項目**:
  - 定型文CRUD操作がHiveに保存される
  - 設定変更がshared_preferencesに保存される
  - アプリ再起動後もデータが保持される

---

### 3. AI変換ボタンの無効化

#### 3.1 視覚的無効化
- **要件**: オフライン時、AI変換ボタンがグレーアウト表示またはdisabled状態になる
- **根拠**: REQ-1002, REQ-3004
- **実装内容**:
  - NetworkProvider.isAIConversionAvailableがfalseの時、ボタンを無効化
  - グレーアウトスタイル適用（透明度0.5、色調低下）
  - タップ時に「オフライン中はAI変換を利用できません」というツールチップまたはSnackBar表示

#### 3.2 フォールバック動作
- **要件**: オフライン時にAI変換ボタンを押した場合、元の入力文をそのまま使用できる
- **根拠**: REQ-1003, REQ-2003
- **実装内容**:
  - AI変換ボタンタップ時に「オフラインです。入力テキストをそのまま使用しますか?」確認ダイアログ表示
  - 「はい」で入力文をそのまま採用
  - 「いいえ」でキャンセル

#### 3.3 AI変換UI非表示（オプション）
- **要件**: AI変換関連UI要素をオフライン時に非表示にしても良い
- **根拠**: REQ-1002（利用不可の明示）
- **実装内容**（オプション）:
  - AI変換ボタン自体を非表示にする（無効化よりも明確）
  - 「オフライン」バッジ表示

---

### 4. オフライン状態の明示表示

#### 4.1 オフライン表示インジケーター
- **要件**: ネットワーク切断時、画面上部またはステータスバーに「オフライン」インジケーターを表示する
- **根拠**: REQ-1002（オフライン時の明示）
- **実装内容**:
  - NetworkStateが`offline`の時、画面上部にSnackBarまたはBanner表示
  - 「オフライン」アイコン（WiFiオフマーク等）+ テキスト「オフライン - 基本機能のみ利用可能」
  - 控えめな色（グレー等）で常時表示、目障りにならない設計

#### 4.2 オンライン復帰通知
- **要件**: ネットワーク復帰時、「オンライン」状態に遷移し、AI変換が利用可能になったことを通知する
- **根拠**: EDGE-001（エラーメッセージと復旧方法）
- **実装内容**:
  - NetworkStateが`offline`→`online`に変化時、一時的にSnackBar表示
  - 「オンラインに戻りました。AI変換が利用可能です」メッセージ
  - 3秒後に自動で消える

---

### 5. エラーメッセージとユーザー通知

#### 5.1 分かりやすいエラーメッセージ
- **要件**: オフライン時のエラーメッセージは、ユーザーが理解しやすい日本語で表示する
- **根拠**: NFR-204（分かりやすいエラーメッセージ）
- **実装内容**:
  - エラーメッセージ例:
    - 「インターネットに接続されていません」
    - 「オフライン中はAI変換を利用できません」
    - 「基本機能（文字入力、定型文、読み上げ）は利用可能です」
  - 復旧方法の提示（WiFi設定を確認するなど）

#### 5.2 非侵襲的な通知
- **要件**: オフライン通知は、ユーザーのコミュニケーション操作を妨げない形で表示する
- **根拠**: NFR-203（主要機能を1画面でアクセス可能）
- **実装内容**:
  - モーダルダイアログではなく、SnackBarやBanner使用
  - 画面下部または上部に控えめに表示
  - ユーザーが閉じなくても操作可能

---

## 受け入れ基準

### 1. オフライン時の基本機能動作

- [ ] **AC-1.1**: オフライン状態で文字盤入力が100ms以内に反映される
- [ ] **AC-1.2**: オフライン状態で定型文一覧が1秒以内に表示される
- [ ] **AC-1.3**: オフライン状態で定型文タップで即座読み上げが実行される
- [ ] **AC-1.4**: オフライン状態で大ボタン・状態ボタンの即座読み上げが動作する
- [ ] **AC-1.5**: オフライン状態で緊急ボタンの2段階確認・緊急音が動作する
- [ ] **AC-1.6**: オフライン状態でTTS読み上げが1秒以内に開始される
- [ ] **AC-1.7**: オフライン状態で定型文CRUD操作がHiveに保存される
- [ ] **AC-1.8**: オフライン状態で設定変更がshared_preferencesに保存される

### 2. AI変換ボタンの無効化

- [ ] **AC-2.1**: オフライン時、AI変換ボタンがグレーアウト表示される
- [ ] **AC-2.2**: オフライン時、AI変換ボタンがタップ不可（disabled）になる
- [ ] **AC-2.3**: オフライン時、AI変換ボタンタップで「オフライン中は利用不可」メッセージが表示される
- [ ] **AC-2.4**: オフライン時、AI変換フォールバック動作（元の文をそのまま使用）が提供される
- [ ] **AC-2.5**: NetworkProvider.isAIConversionAvailableがfalseの時、UI要素が正しく無効化される

### 3. オフライン状態の明示

- [ ] **AC-3.1**: オフライン時、画面上部に「オフライン」インジケーターが表示される
- [ ] **AC-3.2**: オフライン時、「オフライン - 基本機能のみ利用可能」メッセージが表示される
- [ ] **AC-3.3**: オンライン復帰時、「オンラインに戻りました」通知が表示される
- [ ] **AC-3.4**: オフライン通知は、ユーザー操作を妨げない形（SnackBar/Banner）で表示される

### 4. エラーハンドリング

- [ ] **AC-4.1**: オフライン時のエラーメッセージが分かりやすい日本語で表示される
- [ ] **AC-4.2**: エラーメッセージに復旧方法（WiFi設定確認等）が提示される
- [ ] **AC-4.3**: オフライン状態でもアプリがクラッシュしない
- [ ] **AC-4.4**: ネットワーク切り替え（online↔offline）が5回以上連続しても正常動作する

### 5. テストカバレッジ

- [ ] **AC-5.1**: オフライン動作に関するテストカバレッジが90%以上
- [ ] **AC-5.2**: ネットワーク切断シミュレーションテストが実装されている
- [ ] **AC-5.3**: 基本機能（文字盤、定型文、TTS、緊急ボタン）のオフライン動作テストが実装されている
- [ ] **AC-5.4**: AI変換ボタン無効化テストが実装されている

---

## 制約事項

### 1. 技術的制約

- **ネットワーク監視の遅延**: ネットワーク状態の検出に1-2秒の遅延が生じる可能性がある
- **OS標準TTSの制約**: オフライン時のTTSはOS標準エンジンに依存し、カスタマイズに限界がある
- **Hiveの同期処理**: Hive保存操作は非同期だが、UI応答性を保つため適切なローディング表示が必要

### 2. 機能的制約

- **AI変換完全無効化**: オフライン時、AI変換機能は完全に利用不可（キャッシュ等も提供しない）
- **クラウド同期なし**: オフライン時の変更は端末内にのみ保存され、他端末に同期されない（MVP範囲外）
- **ネットワーク復旧の自動検出**: 定期的なネットワーク状態チェックは実装しない（TASK-0058範囲外、将来的にconnectivity_plus使用）

### 3. パフォーマンス制約

- **オフライン切り替え時の遅延**: ネットワーク状態変更からUI反映まで最大1秒の遅延を許容
- **ローカルストレージI/O**: Hive読み書きは非同期で実行し、UIブロッキングを避ける

---

## テストケース概要

### 1. ネットワーク切断シミュレーションテスト

```dart
testWidgets('ネットワーク切断時にオフライン状態に遷移', (tester) async {
  final container = ProviderContainer();
  final notifier = container.read(networkProvider.notifier);

  // オンライン状態
  await notifier.setOnline();
  expect(container.read(networkProvider), NetworkState.online);

  // オフライン状態に切り替え
  await notifier.setOffline();
  expect(container.read(networkProvider), NetworkState.offline);
});
```

### 2. オフライン時の基本機能動作テスト

```dart
testWidgets('オフライン時も文字盤入力が動作', (tester) async {
  // ネットワークをオフラインに設定
  final container = ProviderContainer();
  await container.read(networkProvider.notifier).setOffline();

  // 文字盤画面を表示
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );

  // 文字盤「あ」をタップ
  await tester.tap(find.text('あ'));
  await tester.pump(Duration(milliseconds: 100));

  // 入力バッファに「あ」が追加されることを確認
  expect(find.text('あ'), findsWidgets);
});
```

### 3. AI変換ボタン無効化テスト

```dart
testWidgets('オフライン時にAI変換ボタンが無効化', (tester) async {
  // ネットワークをオフラインに設定
  final container = ProviderContainer();
  await container.read(networkProvider.notifier).setOffline();

  // AI変換ボタンが含まれる画面を表示
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );

  // AI変換ボタンを検索
  final aiButton = find.byKey(Key('ai_conversion_button'));
  expect(aiButton, findsOneWidget);

  // ボタンが無効化されていることを確認
  final button = tester.widget<ElevatedButton>(aiButton);
  expect(button.enabled, false);
});
```

### 4. オフライン表示インジケーターテスト

```dart
testWidgets('オフライン時にインジケーターが表示される', (tester) async {
  // ネットワークをオフラインに設定
  final container = ProviderContainer();
  await container.read(networkProvider.notifier).setOffline();

  // アプリを表示
  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );
  await tester.pumpAndSettle();

  // オフラインインジケーターが表示されることを確認
  expect(find.textContaining('オフライン'), findsOneWidget);
  expect(find.textContaining('基本機能のみ利用可能'), findsOneWidget);
});
```

### 5. オンライン復帰通知テスト

```dart
testWidgets('オンライン復帰時に通知が表示される', (tester) async {
  final container = ProviderContainer();
  await container.read(networkProvider.notifier).setOffline();

  await tester.pumpWidget(
    UncontrolledProviderScope(
      container: container,
      child: MyApp(),
    ),
  );

  // オンラインに復帰
  await container.read(networkProvider.notifier).setOnline();
  await tester.pumpAndSettle();

  // オンライン復帰通知が表示されることを確認
  expect(find.textContaining('オンラインに戻りました'), findsOneWidget);
  expect(find.textContaining('AI変換が利用可能です'), findsOneWidget);
});
```

---

## 実装優先度

### 最優先（P0）

1. **ネットワーク状態管理統合**: NetworkProviderをアプリ全体に統合
2. **基本機能のオフライン動作確認**: 文字盤、定型文、TTS、緊急ボタンの動作テスト
3. **AI変換ボタン無効化**: グレーアウト表示・disabled状態の実装

### 高優先度（P1）

4. **オフライン表示インジケーター**: 画面上部にオフライン状態を明示
5. **エラーメッセージ改善**: 分かりやすい日本語メッセージの実装
6. **ローカルストレージ動作確認**: Hive・shared_preferencesのオフライン保存確認

### 中優先度（P2）

7. **オンライン復帰通知**: ネットワーク復帰時の通知表示
8. **AI変換フォールバック動作**: 元の文をそのまま使用するオプション提供
9. **テストカバレッジ90%達成**: オフライン動作に関する包括的なテスト実装

---

## 成果物

### 1. テストコード

- `test/features/network/offline_behavior_test.dart`: オフライン動作テスト
- `test/widgets/offline_ui_test.dart`: オフライン時のUI無効化テスト

### 2. 実装コード（必要に応じて）

- `lib/features/network/widgets/offline_indicator.dart`: オフラインインジケーターウィジェット
- `lib/features/ai_conversion/widgets/ai_button.dart`: AI変換ボタンの無効化ロジック追加

### 3. ドキュメント

- 本要件定義書（`offline-behavior-requirements.md`）
- テストケース仕様書（テストコード内のコメントで代替可）

---

## 参照ドキュメント

- **要件定義書**: `/Volumes/external/dev/kotonoha/docs/spec/kotonoha-requirements.md`
  - REQ-1001, REQ-1002, REQ-1003, REQ-3004
  - NFR-303, EDGE-001
- **技術設計書**: `/Volumes/external/dev/kotonoha/docs/design/kotonoha/architecture.md`
- **NetworkProvider実装**: `/Volumes/external/dev/kotonoha/frontend/kotonoha_app/lib/features/network/providers/network_provider.dart`
- **NetworkState定義**: `/Volumes/external/dev/kotonoha/frontend/kotonoha_app/lib/features/network/domain/models/network_state.dart`
- **タスクファイル**: `/Volumes/external/dev/kotonoha/docs/tasks/kotonoha-phase3.md`

---

## 備考

### TASK-0057との連携

- TASK-0057で実装されたNetworkProviderを活用し、ネットワーク状態管理を統合します
- `isAIConversionAvailable`ゲッターを使用してAI変換ボタンの有効/無効を切り替えます

### 将来拡張（TASK-0058範囲外）

- **connectivity_plus統合**: 実際のネットワーク接続を自動監視（Phase 4以降）
- **オフラインキャッシュ**: AI変換結果のローカルキャッシュ（MVP範囲外）
- **バックグラウンド同期**: オンライン復帰時の自動データ同期（MVP範囲外）

### デバッグサポート

- 開発者向けに、設定画面で「強制オフラインモード」切り替えを提供することを推奨（テスト容易化のため）

---

## 作成日時

- **作成日**: 2025-11-27
- **作成者**: Claude Code (Tsumiki TDD Requirements Phase)
- **関連タスク**: TASK-0058（オフライン動作確認）
- **フェーズ**: Phase 3 - Week 12 - Day 22
