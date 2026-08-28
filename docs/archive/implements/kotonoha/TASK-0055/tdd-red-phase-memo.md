# TDD Red Phase メモ - TASK-0055

## 概要
- **タスク**: 定型文ローカル保存（Hive）
- **フェーズ**: Red（失敗するテスト作成）
- **実行日時**: 2025-11-26

## 作成したテストファイル
- `test/features/preset_phrase/data/preset_phrase_repository_test.dart`

## テストケース一覧（12件）

### 正常系テスト（6件）
| テストID | テスト名 | 信頼性 |
|---------|---------|--------|
| TC-055-001 | Repository経由で定型文を1件保存できる | 🔵 |
| TC-055-002 | Repository経由で複数の定型文を保存できる（saveAll） | 🔵 |
| TC-055-003 | Repository経由で定型文を更新できる | 🔵 |
| TC-055-004 | Repository経由で定型文を削除できる | 🔵 |
| TC-055-005 | お気に入りフラグがHiveに正しく保存される | 🔵 |
| TC-055-006 | カテゴリ情報がHiveに正しく保存される | 🔵 |

### 境界値テスト（4件）
| テストID | テスト名 | 信頼性 |
|---------|---------|--------|
| TC-055-015 | 空文字の定型文を保存できる | 🟡 |
| TC-055-016 | 500文字の定型文を保存できる | 🔵 |
| TC-055-018 | 0件の状態でloadAll()を呼び出す | 🔵 |
| TC-055-019 | 100件の定型文を一括保存・読み込み | 🟡 |

### 異常系テスト（2件）
| テストID | テスト名 | 信頼性 |
|---------|---------|--------|
| TC-055-011 | 存在しないIDで削除しても例外が発生しない | 🟡 |
| TC-055-012 | getById()で存在しないIDを指定するとnullが返る | 🟡 |

### 永続化テスト（1件）
| テストID | テスト名 | 信頼性 |
|---------|---------|--------|
| TC-055-007 | アプリ再起動後も定型文が保持される | 🔵 |

## テスト失敗の確認

```
Error: Error when reading 'lib/features/preset_phrase/data/preset_phrase_repository.dart': No such file or directory

Error: 'PresetPhraseRepository' isn't a type.

Error: Method not found: 'PresetPhraseRepository'.
```

## 次のステップ
グリーンフェーズで `PresetPhraseRepository` クラスを実装する。

### 必要なメソッド
- `loadAll()`: 全定型文を取得
- `save(PresetPhrase phrase)`: 定型文を保存
- `delete(String id)`: 定型文を削除
- `saveAll(List<PresetPhrase> phrases)`: 複数定型文を一括保存
- `getById(String id)`: IDで定型文を取得
