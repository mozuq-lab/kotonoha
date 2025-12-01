# TDD開発メモ: TTS・ローカルストレージ最適化

## 概要

- 機能名: TTS・ローカルストレージ最適化（Performance Optimization）
- 開発開始: 2025-12-01
- 現在のフェーズ: Red（失敗テスト作成）

## 関連ファイル

- 元タスクファイル: `docs/tasks/kotonoha-phase5.md`
- 要件定義: `docs/implements/kotonoha/TASK-0090/tts-localstorage-optimization-requirements.md`
- テストケース定義: `docs/implements/kotonoha/TASK-0090/tts-localstorage-optimization-testcases.md`
- 実装ファイル:
  - `lib/features/tts/domain/services/tts_service.dart`
  - `lib/features/tts/providers/tts_provider.dart`
  - `lib/features/preset_phrase/data/preset_phrase_repository.dart`
- テストファイル:
  - `test/features/tts/domain/services/tts_service_optimization_test.dart`
  - `test/features/preset_phrase/data/preset_phrase_repository_cache_test.dart`
  - `test/integration/performance_optimization_test.dart`

## Redフェーズ（失敗するテスト作成）

### 作成日時

2025-12-01

### テストケース

以下の14テストケースを実装:

#### TTS最適化テスト（tts_service_optimization_test.dart）
1. **TC-090-001**: TTS事前初期化のバックグラウンド実行確認 🔵
2. **TC-090-001a**: TTSNotifier生成時にバックグラウンド初期化が開始される 🔵
3. **TC-090-002**: TTS読み上げ開始時間の計測（事前初期化済み）🔵
4. **TC-090-003**: TTS自動初期化込みの読み上げ開始時間計測 🟡
5. **TC-090-004**: 連続読み上げのパフォーマンス確認 🟡
6. **TC-090-009**: TTS初期化失敗時のエラーハンドリング 🔵
7. **TC-090-011**: 初期化中のspeak()呼び出し処理 🟡
8. **TC-090-014**: 最小テキストでの読み上げ開始時間 🔵
9. **TC-090-015**: 最大テキストでの読み上げ開始時間 🔵

#### キャッシュ最適化テスト（preset_phrase_repository_cache_test.dart）
10. **TC-090-005**: 定型文100件読み込みパフォーマンス計測 🔵
11. **TC-090-006**: キャッシュによる読み込み高速化確認 🟡
12. **TC-090-007**: キャッシュ無効化と最新データ取得 🔵
13. **TC-090-008**: 保存時のキャッシュ自動無効化確認 🔵
14. **TC-090-010**: Hive読み込みエラー時のフォールバック 🟡
15. **TC-090-012**: 空データでの読み込みパフォーマンス 🔵
16. **TC-090-013**: 大量データでの読み込みパフォーマンス 🟡
17. **TC-090-013a**: キャッシュ構築後の大量データ読み込み高速化 🟡

#### 統合テスト（performance_optimization_test.dart）
18. E2E: 定型文選択から読み上げ開始までのパフォーマンス 🔵
19. 連続操作: 複数の定型文を連続選択・読み上げ 🟡
20. E2E: 500件の定型文からの選択・読み上げパフォーマンス 🟡
21. キャッシュ効果: 初回と2回目の読み込み時間比較 🟡

### テスト実行結果

#### TTSサービス最適化テスト
```
00:01 +7 -2: Some tests failed.
```

**失敗したテスト（想定通り）**:
1. TC-090-001: TTS事前初期化のバックグラウンド実行確認
   - 原因: バックグラウンド初期化が未実装（initialize()が自動呼び出しされない）
   - エラー: `No matching calls (actually, no calls at all).`

2. TC-090-001a: TTSNotifier生成時にバックグラウンド初期化が開始される
   - 原因: TTSNotifierコンストラクタでFuture.microtask()による初期化が未実装
   - エラー: `No matching calls (actually, no calls at all).`

**成功したテスト**:
- TC-090-002〜TC-090-004: 既存実装でパフォーマンス要件を満たす
- TC-090-009, TC-090-011: 異常系は既存実装で対応済み
- TC-090-014, TC-090-015: 境界値テストは既存実装で対応済み

#### キャッシュ最適化テスト
```
Error: The method 'invalidateCache' isn't defined for the type 'PresetPhraseRepository'.
Failed to compile
```

**コンパイルエラー（想定通り）**:
- TC-090-007で使用する`invalidateCache()`メソッドが未実装
- キャッシュ機能全体が未実装

### 期待される失敗

1. **TTS事前初期化（TC-090-001, TC-090-001a）**
   - 現状: TTSNotifier生成時にinitialize()が自動呼び出しされない
   - Greenフェーズで実装: `Future.microtask(() => _service.initialize())`

2. **キャッシュ機能（TC-090-006, TC-090-007, TC-090-008）**
   - 現状: PresetPhraseRepositoryにキャッシュ機能なし
   - Greenフェーズで実装: `_cache`フィールドと`invalidateCache()`メソッド

3. **キャッシュ自動無効化（TC-090-008）**
   - 現状: save()後もキャッシュが更新されない
   - Greenフェーズで実装: save()内で`invalidateCache()`を呼び出し

### 次のフェーズへの要求事項

#### Greenフェーズで実装すべき内容

1. **TTSNotifierの事前初期化**
   ```dart
   TTSNotifier({TTSService? service}) : super(TTSServiceState.initial()) {
     _service = service ?? ...;
     // バックグラウンドで事前初期化
     Future.microtask(() => _service.initialize());
   }
   ```

2. **PresetPhraseRepositoryのキャッシュ実装**
   ```dart
   class PresetPhraseRepository {
     List<PresetPhrase>? _cache;

     Future<List<PresetPhrase>> loadAll() async {
       if (_cache != null) return _cache!;
       _cache = _box.values.toList();
       return _cache!;
     }

     void invalidateCache() => _cache = null;

     Future<void> save(PresetPhrase phrase) async {
       await _box.put(phrase.id, phrase);
       invalidateCache(); // 自動無効化
     }
   }
   ```

3. **パフォーマンス目標**
   - TTS読み上げ開始: 1秒以内（NFR-001）
   - 定型文100件読み込み: 1秒以内（NFR-004）
   - キャッシュヒット時: 10ms以内

## Greenフェーズ（最小実装）

### 実装日時

[未実装]

### 実装方針

[Greenフェーズで記載]

### 実装コード

[Greenフェーズで記載]

### テスト結果

[Greenフェーズで記載]

### 課題・改善点

[Refactorフェーズで改善すべき点を記載]

## Refactorフェーズ（品質改善）

### リファクタ日時

[未実装]

### 改善内容

[Refactorフェーズで記載]

### セキュリティレビュー

[Refactorフェーズで記載]

### パフォーマンスレビュー

[Refactorフェーズで記載]

### 最終コード

[Refactorフェーズで記載]

### 品質評価

[Refactorフェーズで記載]
