# TASK-0097: セキュリティ・プライバシー最終確認 - 要件定義書

## 概要

**タスクID**: TASK-0097
**タスク名**: セキュリティ・プライバシー最終確認
**タスクタイプ**: TDD
**推定工数**: 8時間
**信頼性レベル**: 🔵 青信号（NFR-101〜NFR-105に基づく）

## 参照要件・設計文書

### 参照したEARS要件
- **NFR-101**: システムは利用者の会話内容（定型文・履歴）を原則として端末内にのみ保存しなければならない
- **NFR-102**: システムはAI変換機能で会話内容を外部に送信する場合、その旨をアプリ内で分かりやすく説明しなければならない
- **NFR-103**: システムは履歴・お気に入りを利用者・支援者が任意に削除できる機能を提供しなければならない
- **NFR-104**: システムはHTTPS通信を使用し、API通信を暗号化しなければならない
- **NFR-105**: システムは環境変数をアプリ内にハードコードせず、安全に管理しなければならない

### 参照した設計文書
- `docs/design/kotonoha/architecture.md` - データ保存ポリシー
- `docs/design/kotonoha/api-endpoints.md` - HTTPS/TLS設定
- `docs/tech-stack.md` - セキュリティ設計

## 機能要件

### FR-097-001: ローカルストレージ保存確認 🔵
**根拠**: NFR-101, architecture.md

システムはユーザーデータを端末内ローカルストレージにのみ保存する:
- 定型文はHive（presetPhrases Box）に保存
- 履歴はHive（history Box）に保存
- お気に入りはHive（favorites Box）に保存
- 設定はshared_preferencesに保存
- クラウドへの自動同期は行わない

### FR-097-002: AI変換プライバシー通知 🔵
**根拠**: NFR-102, architecture.md

システムはAI変換機能の初回利用時に:
- 会話内容を外部API（Anthropic/OpenAI）に送信することを明示
- ユーザーの同意を取得
- プライバシーポリシーへのリンクを表示
- 同意なしにAI変換を実行しない

### FR-097-003: データ削除機能確認 🔵
**根拠**: NFR-103, REQ-604, REQ-704

システムは以下のデータ削除機能を提供:
- 履歴の個別削除
- 履歴の全削除
- お気に入りの個別削除（確認ダイアログ付き）
- お気に入りの全削除
- 定型文の削除（確認ダイアログ付き）

### FR-097-004: HTTPS通信確認 🔵
**根拠**: NFR-104, api-endpoints.md

システムはすべてのAPI通信を暗号化:
- TLS 1.2+を使用
- 本番環境ではHTTP通信を拒否
- 証明書検証を実施

### FR-097-005: 環境変数管理確認 🔵
**根拠**: NFR-105, tech-stack.md

システムは環境変数を安全に管理:
- APIキー（OPENAI_API_KEY, ANTHROPIC_API_KEY）をハードコードしない
- シークレットキー（SECRET_KEY）をハードコードしない
- データベース接続情報をハードコードしない
- `.env`ファイルを`.gitignore`に含める

## 非機能要件

### NFR-097-001: データ保護
- アプリ専用領域にデータを保存（他アプリからアクセス不可）
- アプリアンインストール時に全データ削除

### NFR-097-002: 通信セキュリティ
- JWT認証トークン使用（将来のユーザー管理用）
- bcryptによるパスワードハッシュ化（コスト係数12以上）

## テスト要件

### TC-097-001: ローカルストレージ保存テスト 🔵

```dart
// Frontend: test/features/security/local_storage_test.dart
group('NFR-101: ローカルストレージ保存', () {
  test('定型文がHiveに保存される', () async {
    // PresetPhraseRepositoryがHiveを使用することを確認
  });

  test('履歴がHiveに保存される', () async {
    // HistoryRepositoryがHiveを使用することを確認
  });

  test('お気に入りがHiveに保存される', () async {
    // FavoriteRepositoryがHiveを使用することを確認
  });

  test('設定がshared_preferencesに保存される', () async {
    // AppSettingsRepositoryがshared_preferencesを使用することを確認
  });

  test('クラウドへの自動同期が行われない', () async {
    // ネットワーク呼び出しがデータ保存時に発生しないことを確認
  });
});
```

### TC-097-002: AI変換プライバシー通知テスト 🔵

```dart
// Frontend: test/features/security/privacy_consent_test.dart
group('NFR-102: AI変換プライバシー通知', () {
  testWidgets('初回AI変換時にプライバシー通知が表示される', (tester) async {
    // プライバシー同意ダイアログの表示確認
  });

  testWidgets('同意前はAI変換が実行されない', (tester) async {
    // 同意フラグがfalseの場合、変換が実行されないことを確認
  });

  testWidgets('同意後はAI変換が実行される', (tester) async {
    // 同意フラグがtrueの場合、変換が実行されることを確認
  });

  testWidgets('プライバシーポリシーリンクが表示される', (tester) async {
    // リンクの存在確認
  });

  test('同意状態が永続化される', () async {
    // shared_preferencesに同意状態が保存されることを確認
  });
});
```

### TC-097-003: データ削除機能テスト 🔵

```dart
// Frontend: test/features/security/data_deletion_test.dart
group('NFR-103: データ削除機能', () {
  test('履歴を個別削除できる', () async {
    // HistoryRepository.delete()のテスト
  });

  test('履歴を全削除できる', () async {
    // HistoryRepository.deleteAll()のテスト
  });

  test('お気に入りを個別削除できる（確認ダイアログ後）', () async {
    // FavoriteRepository.delete()のテスト
  });

  test('お気に入りを全削除できる', () async {
    // FavoriteRepository.deleteAll()のテスト
  });

  test('定型文を削除できる（確認ダイアログ後）', () async {
    // PresetPhraseRepository.delete()のテスト
  });
});
```

### TC-097-004: HTTPS通信テスト 🔵

```dart
// Frontend: test/features/security/https_test.dart
group('NFR-104: HTTPS通信', () {
  test('APIクライアントがHTTPSを使用する（本番環境）', () {
    // 本番環境のbaseUrlがhttps://で始まることを確認
  });

  test('HTTP URLは本番環境で拒否される', () {
    // http://で始まるURLが拒否されることを確認
  });
});
```

```python
# Backend: tests/test_security/test_https.py
class TestHTTPSConfiguration:
    def test_cors_configuration_exists(self):
        # CORS設定が存在することを確認

    def test_tls_version_configured(self):
        # TLS設定が存在することを確認
```

### TC-097-005: 環境変数管理テスト 🔵

```python
# Backend: tests/test_security/test_env_variables.py
class TestEnvironmentVariables:
    def test_api_keys_not_hardcoded(self):
        # コードベースにAPIキーがハードコードされていないことを確認

    def test_secret_key_from_env(self):
        # SECRET_KEYが環境変数から読み込まれることを確認

    def test_database_credentials_from_env(self):
        # DB接続情報が環境変数から読み込まれることを確認

    def test_env_file_in_gitignore(self):
        # .envがgitignoreに含まれることを確認
```

```dart
// Frontend: test/features/security/env_variables_test.dart
group('NFR-105: 環境変数管理', () {
  test('APIベースURLが環境変数から取得される', () {
    // String.fromEnvironmentが使用されていることを確認
  });

  test('ハードコードされたAPIキーが存在しない', () {
    // ソースコードにAPIキーパターンが含まれないことを確認
  });
});
```

## 受け入れ基準

### AC-097-001: ローカルストレージ保存
- [ ] 定型文・履歴・お気に入りがHiveに保存される
- [ ] 設定がshared_preferencesに保存される
- [ ] クラウドへの自動同期が行われない
- [ ] テストがすべてパスする

### AC-097-002: AI変換プライバシー通知
- [ ] 初回AI変換時にプライバシー通知ダイアログが表示される
- [ ] 同意前はAI変換が実行されない
- [ ] 同意状態が永続化される
- [ ] テストがすべてパスする

### AC-097-003: データ削除機能
- [ ] 履歴の個別・全削除が動作する
- [ ] お気に入りの個別・全削除が動作する
- [ ] 定型文の削除が動作する
- [ ] テストがすべてパスする

### AC-097-004: HTTPS通信
- [ ] 本番環境でHTTPSが使用される
- [ ] CORS設定が正しく構成される
- [ ] テストがすべてパスする

### AC-097-005: 環境変数管理
- [ ] APIキーがハードコードされていない
- [ ] シークレットキーが環境変数から読み込まれる
- [ ] .envがgitignoreに含まれる
- [ ] テストがすべてパスする

## 実装上の注意事項

### プライバシー通知実装
- 初回AI変換時のみ通知表示
- 同意フラグは`shared_preferences`で管理
- `ai_privacy_consent`キーで保存

### HTTPS設定
- 開発環境: `http://localhost:8000`（許容）
- 本番環境: `https://api.kotonoha.app`（必須）
- 環境変数`API_BASE_URL`で切り替え

### 環境変数チェック
- 静的解析で機密情報のハードコードを検出
- CI/CDでの自動チェック推奨

## 関連タスク

- **TASK-0054**: Hive データベース初期化（完了）
- **TASK-0055**: 定型文ローカル保存（完了）
- **TASK-0056**: アプリ設定保存（完了）
- **TASK-0062**: 履歴管理機能（完了）
- **TASK-0065**: お気に入り管理機能（完了）

## 更新履歴

- **2025-12-03**: TASK-0097 要件定義書作成
