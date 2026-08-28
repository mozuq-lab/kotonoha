# TASK-0015: go_routerナビゲーション設定・ルーティング実装 要件定義書

## 概要

**タスクID**: TASK-0015
**タスク名**: go_routerナビゲーション設定・ルーティング実装
**タスクタイプ**: TDD
**推定工数**: 8時間
**依存タスク**: TASK-0014（Hiveローカルストレージセットアップ・データモデル実装）

### 目的

Flutterアプリケーションにgo_routerを使用した宣言的ルーティングを導入し、画面遷移の基盤を構築する。発話困難な方が最小限の操作で必要な機能にアクセスできるよう、シンプルで効率的なナビゲーション構造を実現する。

### 関連要件

| 要件ID | 要件内容 | 信頼性 |
|--------|----------|--------|
| NFR-203 | 画面遷移を必要最小限に留め、主要機能を1画面でアクセス可能にする | 🟡 |
| REQ-5005 | タップ主体の操作で完結し、スワイプ等のジェスチャーへの依存を避ける | 🔵 |
| NFR-201 | 主要な操作を3タップ以内で完了できる | 🟡 |

---

## 機能要件

### FR-001: GoRouterプロバイダーの実装

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - アーキテクチャ設計書に基づく

システムはRiverpod Providerを使用してGoRouterインスタンスを提供しなければならない。

**詳細仕様**:
- `@riverpod`アノテーションを使用したプロバイダー定義
- シングルトンパターンでGoRouterインスタンスを管理
- `lib/core/router/app_router.dart`に実装
- コード生成（`app_router.g.dart`）に対応

**根拠**: アーキテクチャ設計書でRiverpod 2.xによる状態管理、go_routerによる宣言的ルーティングが規定されている。

---

### FR-002: 初期ルート設定

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - タスクファイルに基づく

システムはアプリケーション起動時に初期ルート「/」（ホーム画面）を表示しなければならない。

**詳細仕様**:
- `initialLocation: '/'`でホーム画面を初期表示
- ホーム画面（文字盤画面）を最初に表示することで、ユーザーが即座に入力を開始可能
- ディープリンク対応のため、明示的な初期ルート設定が必要

**根拠**: NFR-203（主要機能を1画面でアクセス可能）に基づき、文字盤画面をホームとする。

---

### FR-003: 主要ルート定義

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - タスクファイルに基づく

システムは以下の4つの主要ルートを定義しなければならない。

| ルートパス | ルート名 | 画面 | 説明 |
|-----------|----------|------|------|
| `/` | `home` | HomeScreen | 文字盤画面（メイン画面） |
| `/settings` | `settings` | SettingsScreen | 設定画面 |
| `/history` | `history` | HistoryScreen | 履歴画面 |
| `/favorites` | `favorites` | FavoritesScreen | お気に入り画面 |

**詳細仕様**:
- 各ルートに`name`パラメータを設定し、名前付きルーティングに対応
- `GoRoute`クラスを使用した宣言的ルート定義
- 各画面はStatelessWidgetとして実装（Phase 2以降で機能追加予定）

**根拠**: NFR-203（画面遷移を必要最小限に留める）に基づき、必要最小限の4画面構成。

---

### FR-004: エラーページ対応

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🟡 黄信号 - NFR-204から推測

システムは存在しないルートへのアクセス時にエラー画面を表示しなければならない。

**詳細仕様**:
- `errorBuilder`パラメータでErrorScreenを指定
- エラー情報（`GoRouterState.error`）をErrorScreenに渡す
- 分かりやすい日本語でエラーメッセージを表示
- ホーム画面への復帰ボタンを提供

**根拠**: NFR-204（エラーメッセージを分かりやすい日本語で表示し、復旧方法を示す）に基づく。

---

### FR-005: 画面スケルトン作成

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - タスクファイルに基づく

システムは以下の5つの画面スケルトンを作成しなければならない。

| 画面クラス | ファイルパス | 説明 |
|-----------|-------------|------|
| HomeScreen | `lib/features/character_board/presentation/home_screen.dart` | 文字盤画面 |
| SettingsScreen | `lib/features/settings/presentation/settings_screen.dart` | 設定画面 |
| HistoryScreen | `lib/features/history/presentation/history_screen.dart` | 履歴画面 |
| FavoritesScreen | `lib/features/favorites/presentation/favorites_screen.dart` | お気に入り画面 |
| ErrorScreen | `lib/core/router/error_screen.dart` | エラー画面 |

**詳細仕様**:
- 各画面はStatelessWidgetとして実装
- `const`コンストラクタを使用（パフォーマンス最適化）
- `key`パラメータを持つ（Flutter lints準拠）
- 最低限のScaffold構造（AppBar + Body）を持つ
- 画面識別用のテキストを表示（テスト用）

**根拠**: TASK-0015のタスクファイルで画面スケルトン作成が明示されている。

---

### FR-006: MaterialApp.routerとの統合

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - アーキテクチャ設計書に基づく

システムはMaterialApp.routerを使用してGoRouterを統合しなければならない。

**詳細仕様**:
- `app.dart`でConsumerWidgetを継承したKotonohaAppを実装
- `ref.watch(routerProvider)`でGoRouterインスタンスを取得
- `MaterialApp.router`の`routerConfig`パラメータにGoRouterを設定
- テーマ設定（lightTheme, darkTheme）を維持

**根拠**: アーキテクチャ設計書でRiverpod + go_routerの組み合わせが規定されている。

---

### FR-007: main.dartへのProviderScope統合

**要件種別**: 通常要件（SHALL）
**信頼性レベル**: 🔵 青信号 - Riverpod標準パターン

システムはmain.dartでProviderScopeを使用してRiverpodを初期化しなければならない。

**詳細仕様**:
- `runApp`で`ProviderScope`をルートに配置
- `ProviderScope`の子として`KotonohaApp`を配置
- 既存のHive初期化処理を維持

**根拠**: TASK-0013（Riverpod状態管理セットアップ）で確立されたパターンに従う。

---

## 非機能要件

### NFR-T001: ナビゲーション応答性能

**要件種別**: パフォーマンス要件
**信頼性レベル**: 🟡 黄信号 - NFR-003から推測

システムは画面遷移を100ms以内に完了しなければならない。

**計測方法**:
- ナビゲーション開始からウィジェットビルド完了までの時間
- Flutter DevToolsのパフォーマンスモニターで計測

**根拠**: NFR-003（文字盤タップから入力欄への反映が100ms以内）と同等の応答性を期待。

---

### NFR-T002: タップターゲットサイズ

**要件種別**: アクセシビリティ要件
**信頼性レベル**: 🔵 青信号 - REQ-5001に基づく

システムはナビゲーション要素（戻るボタン、メニューアイテムなど）のタップターゲットを44px x 44px以上としなければならない。

**詳細仕様**:
- AppBarの戻るボタン: 48dp以上（Material Designデフォルト）
- ナビゲーションメニューアイテム: 44px x 44px以上
- 推奨サイズ: 60px x 60px

**根拠**: REQ-5001（タップターゲットのサイズを44px x 44px以上）に基づく。

---

### NFR-T003: テストカバレッジ

**要件種別**: 品質要件
**信頼性レベル**: 🔵 青信号 - NFR-501に基づく

システムはgo_routerナビゲーション機能のテストカバレッジを80%以上としなければならない。

**計測方法**:
- `flutter test --coverage`でカバレッジ計測
- `app_router.dart`および関連画面のカバレッジを確認

**根拠**: NFR-501（コードカバレッジ80%以上のテストを維持）に基づく。

---

## 受け入れ基準

### AC-001: GoRouter設定完了

**シナリオ**: GoRouterプロバイダーの動作確認

**Given**: アプリケーションが起動可能な状態である
**When**: アプリケーションを起動する
**Then**:
- GoRouterプロバイダーが正常にインスタンス化される
- エラーなくルーティングが初期化される

**検証方法**:
- `flutter run`でアプリが正常起動すること
- コンソールにルーティング関連のエラーがないこと

---

### AC-002: 初期ルート表示

**シナリオ**: アプリ起動時の初期画面表示

**Given**: GoRouterが正常に設定されている
**When**: アプリケーションを起動する
**Then**:
- ホーム画面（HomeScreen）が表示される
- 「ホーム画面」または画面識別テキストが表示される

**検証方法**:
- ウィジェットテストで`find.text('ホーム画面')`が存在すること
- 手動テストで初期画面がHomeScreenであること

---

### AC-003: 設定画面へのナビゲーション

**シナリオ**: 設定画面への遷移

**Given**: ホーム画面が表示されている
**When**: `/settings`へナビゲートする
**Then**:
- 設定画面（SettingsScreen）が表示される
- 「設定画面」または画面識別テキストが表示される

**検証方法**:
- ウィジェットテストで`router.go('/settings')`後に`find.text('設定画面')`が存在すること

---

### AC-004: 履歴画面へのナビゲーション

**シナリオ**: 履歴画面への遷移

**Given**: ホーム画面が表示されている
**When**: `/history`へナビゲートする
**Then**:
- 履歴画面（HistoryScreen）が表示される
- 「履歴画面」または画面識別テキストが表示される

**検証方法**:
- ウィジェットテストで`router.go('/history')`後に`find.text('履歴画面')`が存在すること

---

### AC-005: お気に入り画面へのナビゲーション

**シナリオ**: お気に入り画面への遷移

**Given**: ホーム画面が表示されている
**When**: `/favorites`へナビゲートする
**Then**:
- お気に入り画面（FavoritesScreen）が表示される
- 「お気に入り画面」または画面識別テキストが表示される

**検証方法**:
- ウィジェットテストで`router.go('/favorites')`後に`find.text('お気に入り画面')`が存在すること

---

### AC-006: エラーページ表示

**シナリオ**: 存在しないルートへのアクセス

**Given**: GoRouterが正常に設定されている
**When**: 存在しないルート（例: `/unknown`）へナビゲートする
**Then**:
- エラー画面（ErrorScreen）が表示される
- エラーメッセージが日本語で表示される
- ホーム画面への復帰手段が提供される

**検証方法**:
- ウィジェットテストで`router.go('/unknown')`後にErrorScreenが表示されること
- エラーメッセージが存在すること

---

### AC-007: 名前付きルーティング動作

**シナリオ**: 名前でルートを指定したナビゲーション

**Given**: GoRouterが正常に設定されている
**When**: `context.goNamed('settings')`を実行する
**Then**:
- 設定画面へ正常に遷移する
- パスベースのナビゲーションと同じ結果になる

**検証方法**:
- ウィジェットテストで名前付きナビゲーションが機能すること

---

### AC-008: ProviderScope統合

**シナリオ**: Riverpod ProviderScopeの動作確認

**Given**: main.dartにProviderScopeが設定されている
**When**: アプリケーションを起動する
**Then**:
- Riverpodプロバイダーが正常に初期化される
- `ref.watch(routerProvider)`でGoRouterが取得できる

**検証方法**:
- アプリが正常起動すること
- プロバイダー関連のエラーがないこと

---

## テスト要件

### テストカテゴリ

| カテゴリ | 説明 | 優先度 |
|---------|------|--------|
| Unit Test | GoRouterプロバイダーのテスト | 高 |
| Widget Test | 各画面スケルトンのレンダリングテスト | 高 |
| Widget Test | ナビゲーション動作テスト | 高 |
| Integration Test | 画面遷移フローテスト | 中 |

### テストケース一覧

| TC-ID | テストケース名 | カテゴリ | 対応AC |
|-------|---------------|----------|--------|
| TC-001 | GoRouterプロバイダーのインスタンス化テスト | Unit | AC-001 |
| TC-002 | 初期ルートが「/」であることの確認テスト | Unit | AC-002 |
| TC-003 | HomeScreen表示テスト | Widget | AC-002 |
| TC-004 | SettingsScreen表示テスト | Widget | AC-003 |
| TC-005 | HistoryScreen表示テスト | Widget | AC-004 |
| TC-006 | FavoritesScreen表示テスト | Widget | AC-005 |
| TC-007 | ErrorScreen表示テスト | Widget | AC-006 |
| TC-008 | /settingsへのナビゲーションテスト | Widget | AC-003 |
| TC-009 | /historyへのナビゲーションテスト | Widget | AC-004 |
| TC-010 | /favoritesへのナビゲーションテスト | Widget | AC-005 |
| TC-011 | 不正ルートでのエラーページ表示テスト | Widget | AC-006 |
| TC-012 | 名前付きルーティングテスト（settings） | Widget | AC-007 |
| TC-013 | 名前付きルーティングテスト（history） | Widget | AC-007 |
| TC-014 | 名前付きルーティングテスト（favorites） | Widget | AC-007 |
| TC-015 | ProviderScope経由のRouter取得テスト | Unit | AC-008 |

### テストファイル構成

```
test/
├── core/
│   └── router/
│       ├── app_router_test.dart        # TC-001, TC-002, TC-015
│       └── error_screen_test.dart      # TC-007
├── features/
│   ├── character_board/
│   │   └── presentation/
│   │       └── home_screen_test.dart   # TC-003
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_screen_test.dart # TC-004
│   ├── history/
│   │   └── presentation/
│   │       └── history_screen_test.dart  # TC-005
│   └── favorites/
│       └── presentation/
│           └── favorites_screen_test.dart # TC-006
└── integration/
    └── navigation_test.dart            # TC-008〜TC-014
```

---

## 実装ファイル一覧

### 新規作成ファイル

| ファイルパス | 説明 |
|-------------|------|
| `lib/core/router/app_router.dart` | GoRouterプロバイダー定義（既存ファイル更新） |
| `lib/core/router/app_router.g.dart` | Riverpodコード生成ファイル |
| `lib/core/router/error_screen.dart` | エラー画面 |
| `lib/features/character_board/presentation/home_screen.dart` | ホーム画面スケルトン |
| `lib/features/settings/presentation/settings_screen.dart` | 設定画面スケルトン |
| `lib/features/history/presentation/history_screen.dart` | 履歴画面スケルトン |
| `lib/features/favorites/presentation/favorites_screen.dart` | お気に入り画面スケルトン |

### 更新ファイル

| ファイルパス | 更新内容 |
|-------------|---------|
| `lib/app.dart` | ConsumerWidget化、MaterialApp.router使用 |
| `lib/main.dart` | ProviderScope追加、KotonohaApp使用 |

---

## 制約・前提条件

### 技術的制約

1. **Flutter SDK**: 3.38.1以上
2. **go_router**: pubspec.yamlで定義されたバージョン（14.6.2）
3. **Riverpod**: flutter_riverpod 2.6.1、riverpod_annotation 2.6.1
4. **コード生成**: build_runner、riverpod_generatorを使用

### 前提条件

1. **TASK-0014完了**: Hiveローカルストレージセットアップが完了していること
2. **TASK-0013完了**: Riverpod状態管理セットアップが完了していること
3. **TASK-0012完了**: Flutter依存パッケージが追加されていること

### 実装上の注意事項

1. **コード生成**: 実装後に`flutter pub run build_runner build --delete-conflicting-outputs`を実行
2. **テスト実行**: すべてのテストケースが成功することを確認
3. **Lint準拠**: `flutter analyze`でエラーがないこと
4. **constコンストラクタ**: 可能な限り使用してパフォーマンス最適化

---

## 用語集

| 用語 | 説明 |
|------|------|
| go_router | Flutter向け宣言的ルーティングライブラリ |
| Riverpod | Flutter向け状態管理ライブラリ |
| Provider | Riverpodで状態を提供するオブジェクト |
| ディープリンク | 特定の画面に直接遷移するためのURL |
| 宣言的ルーティング | ルート構造をコードで宣言的に定義する方式 |

---

## 更新履歴

| 日付 | バージョン | 更新者 | 更新内容 |
|------|-----------|--------|---------|
| 2025-11-22 | 1.0 | Claude | 初版作成 |

---

## 関連ドキュメント

- [アーキテクチャ設計書](/Volumes/external/dev/kotonoha/docs/design/kotonoha/architecture.md)
- [要件定義書](/Volumes/external/dev/kotonoha/docs/spec/kotonoha-requirements.md)
- [Phase 1タスク一覧](/Volumes/external/dev/kotonoha/docs/tasks/kotonoha-phase1.md)
- [技術スタック定義](/Volumes/external/dev/kotonoha/docs/tech-stack.md)
