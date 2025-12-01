# TASK-0090: TTS・ローカルストレージ最適化 - Redフェーズ設計書

## 概要

### 作成日時
2025-12-01

### 対象テストケース
TC-090-001〜TC-090-015（全14テストケース + 追加テスト7件）

---

## 1. テストファイル構成

```
frontend/kotonoha_app/test/
├── features/
│   ├── tts/
│   │   └── domain/services/
│   │       └── tts_service_optimization_test.dart  # 9テストケース
│   └── preset_phrase/
│       └── data/
│           └── preset_phrase_repository_cache_test.dart  # 8テストケース
└── integration/
    └── performance_optimization_test.dart  # 4テストケース
```

---

## 2. TTS最適化テスト設計

### 2.1 テストファイル
`test/features/tts/domain/services/tts_service_optimization_test.dart`

### 2.2 テストグループ構成

#### グループ1: 正常系テストケース
- TC-090-001: TTS事前初期化のバックグラウンド実行確認
- TC-090-002: TTS読み上げ開始時間の計測（事前初期化済み）
- TC-090-003: TTS自動初期化込みの読み上げ開始時間計測
- TC-090-004: 連続読み上げのパフォーマンス確認

#### グループ2: 異常系テストケース
- TC-090-009: TTS初期化失敗時のエラーハンドリング
- TC-090-011: 初期化中のspeak()呼び出し処理

#### グループ3: 境界値テストケース
- TC-090-014: 最小テキストでの読み上げ開始時間
- TC-090-015: 最大テキストでの読み上げ開始時間

#### グループ4: TTSNotifier事前初期化テスト
- TC-090-001a: TTSNotifier生成時にバックグラウンド初期化が開始される

### 2.3 モック設定

```dart
late MockFlutterTts mockFlutterTts;

setUp(() {
  mockFlutterTts = MockFlutterTts();

  when(() => mockFlutterTts.setLanguage(any())).thenAnswer((_) async => 1);
  when(() => mockFlutterTts.setSpeechRate(any())).thenAnswer((_) async => 1);
  when(() => mockFlutterTts.speak(any())).thenAnswer((_) async => 1);
  when(() => mockFlutterTts.stop()).thenAnswer((_) async => 1);
});
```

### 2.4 パフォーマンス計測パターン

```dart
final stopwatch = Stopwatch()..start();
await service.speak(testText);
stopwatch.stop();

expect(
  stopwatch.elapsedMilliseconds,
  lessThanOrEqualTo(1000),
);
```

---

## 3. キャッシュ最適化テスト設計

### 3.1 テストファイル
`test/features/preset_phrase/data/preset_phrase_repository_cache_test.dart`

### 3.2 テストグループ構成

#### グループ1: 正常系テストケース
- TC-090-005: 定型文100件読み込みパフォーマンス計測
- TC-090-006: キャッシュによる読み込み高速化確認
- TC-090-007: キャッシュ無効化と最新データ取得
- TC-090-008: 保存時のキャッシュ自動無効化確認

#### グループ2: 異常系テストケース
- TC-090-010: Hive読み込みエラー時のフォールバック

#### グループ3: 境界値テストケース
- TC-090-012: 空データでの読み込みパフォーマンス
- TC-090-013: 大量データでの読み込みパフォーマンス
- TC-090-013a: キャッシュ構築後の大量データ読み込み高速化

### 3.3 Hiveセットアップパターン

```dart
late Directory tempDir;
late Box<PresetPhrase> presetBox;
late PresetPhraseRepository repository;

setUp(() async {
  await Hive.close();
  tempDir = await Directory.systemTemp.createTemp('hive_cache_test_');
  Hive.init(tempDir.path);

  if (!Hive.isAdapterRegistered(1)) {
    Hive.registerAdapter(PresetPhraseAdapter());
  }

  presetBox = await Hive.openBox<PresetPhrase>('test_cache_presetPhrases');
  repository = PresetPhraseRepository(box: presetBox);
});

tearDown(() async {
  await presetBox.close();
  await Hive.deleteBoxFromDisk('test_cache_presetPhrases');
  await Hive.close();

  if (tempDir.existsSync()) {
    await tempDir.delete(recursive: true);
  }
});
```

### 3.4 テストデータ生成パターン

```dart
final phrases = List.generate(
  100,
  (i) => PresetPhrase(
    id: 'perf-$i',
    content: '定型文$i',
    category: ['daily', 'health', 'other'][i % 3],
    isFavorite: i % 5 == 0,
    displayOrder: i,
    createdAt: DateTime.now(),
    updatedAt: DateTime.now(),
  ),
);
```

---

## 4. 統合パフォーマンステスト設計

### 4.1 テストファイル
`test/integration/performance_optimization_test.dart`

### 4.2 テストケース

1. **E2E: 定型文選択から読み上げ開始までのパフォーマンス**
   - 100件読み込み + TTS読み上げ開始の合計時間 ≤ 1秒

2. **連続操作: 複数の定型文を連続選択・読み上げ**
   - 5回連続操作で各回 ≤ 100ms

3. **E2E: 500件の定型文からの選択・読み上げパフォーマンス**
   - スケーラビリティ検証

4. **キャッシュ効果: 初回と2回目の読み込み時間比較**
   - 2回目 ≤ 初回の50%

---

## 5. 期待される失敗パターン

### 5.1 コンパイルエラー

| テストケース | エラー内容 | 未実装機能 |
|-------------|-----------|-----------|
| TC-090-007 | `invalidateCache()` is not defined | キャッシュ無効化メソッド |

### 5.2 テスト失敗

| テストケース | エラー内容 | 未実装機能 |
|-------------|-----------|-----------|
| TC-090-001 | No matching calls | バックグラウンド初期化 |
| TC-090-001a | No matching calls | TTSNotifier事前初期化 |
| TC-090-006 | 時間超過 | キャッシュ読み込み |
| TC-090-008 | データ不整合 | 自動キャッシュ無効化 |

---

## 6. Greenフェーズ実装項目

### 6.1 TTSNotifier修正

**ファイル**: `lib/features/tts/providers/tts_provider.dart`

**変更点**:
```dart
TTSNotifier({TTSService? service}) : super(TTSServiceState.initial()) {
  _service = service ?? TTSService(
    tts: FlutterTts(),
    onStateChanged: _onServiceStateChanged,
  );

  // 🔵 追加: バックグラウンドで事前初期化
  Future.microtask(() => initialize());
}
```

### 6.2 PresetPhraseRepositoryキャッシュ実装

**ファイル**: `lib/features/preset_phrase/data/preset_phrase_repository.dart`

**変更点**:
```dart
class PresetPhraseRepository {
  final Box<PresetPhrase> _box;

  // 🔵 追加: メモリキャッシュ
  List<PresetPhrase>? _cache;

  PresetPhraseRepository({required Box<PresetPhrase> box}) : _box = box;

  Future<List<PresetPhrase>> loadAll() async {
    // 🔵 追加: キャッシュヒット処理
    if (_cache != null) return _cache!;
    _cache = _box.values.toList();
    return _cache!;
  }

  // 🔵 追加: キャッシュ無効化メソッド
  void invalidateCache() => _cache = null;

  Future<void> save(PresetPhrase phrase) async {
    await _box.put(phrase.id, phrase);
    invalidateCache(); // 🔵 追加: 自動無効化
  }

  Future<void> delete(String id) async {
    await _box.delete(id);
    invalidateCache(); // 🔵 追加: 自動無効化
  }

  Future<void> saveAll(List<PresetPhrase> phrases) async {
    final map = {for (final p in phrases) p.id: p};
    await _box.putAll(map);
    invalidateCache(); // 🔵 追加: 自動無効化
  }
}
```

---

## 7. 品質判定

### ✅ 高品質

| 項目 | 状況 |
|------|------|
| テスト実行 | 成功（失敗することを確認） |
| 期待値 | 明確で具体的（時間制限、状態遷移） |
| アサーション | 適切（lessThanOrEqualTo, verify） |
| 実装方針 | 明確（キャッシュ、事前初期化） |

---

## 8. テスト実行コマンド

```bash
# TTS最適化テスト実行
flutter test test/features/tts/domain/services/tts_service_optimization_test.dart

# キャッシュ最適化テスト実行（コンパイルエラー発生）
flutter test test/features/preset_phrase/data/preset_phrase_repository_cache_test.dart

# 統合パフォーマンステスト実行
flutter test test/integration/performance_optimization_test.dart

# 全TASK-0090関連テスト実行
flutter test --name "最適化"
```

---

## 更新履歴

- **2025-12-01**: Redフェーズ完了
  - 21テストケースを3ファイルに実装
  - TTS事前初期化テスト: 2件失敗（想定通り）
  - キャッシュテスト: コンパイルエラー（想定通り）
  - パフォーマンステスト: 一部失敗予定
