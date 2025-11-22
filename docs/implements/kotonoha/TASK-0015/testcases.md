# TASK-0015: go_routerナビゲーション設定・ルーティング実装 テストケース仕様書

## 概要

**タスクID**: TASK-0015
**対象機能**: go_routerナビゲーション設定・ルーティング実装
**テストフレームワーク**: flutter_test, flutter_riverpod
**作成日**: 2025-11-22

### テストファイル構成

```
test/
├── core/
│   └── router/
│       └── app_router_test.dart        # TC-001〜TC-005
├── features/
│   ├── character_board/
│   │   └── presentation/
│   │       └── home_screen_test.dart   # TC-006
│   ├── settings/
│   │   └── presentation/
│   │       └── settings_screen_test.dart # TC-007
│   ├── history/
│   │   └── presentation/
│   │       └── history_screen_test.dart  # TC-008
│   └── favorites/
│       └── presentation/
│           └── favorites_screen_test.dart # TC-009
└── integration/
    └── navigation_test.dart            # TC-010〜TC-015
```

---

## Unit Tests (app_router_test.dart)

### TC-001: routerProvider生成テスト

**テストカテゴリ**: Unit Test
**対応要件**: FR-001（GoRouterプロバイダーの実装）
**対応受け入れ基準**: AC-001, AC-008

#### テスト目的

Riverpod ProviderContainerを使用して`routerProvider`が正常にGoRouterインスタンスを生成することを確認する。

#### 前提条件

- `app_router.dart`が実装されている
- `@riverpod`アノテーションを使用したプロバイダーが定義されている
- コード生成（`app_router.g.dart`）が完了している

#### テスト手順

1. ProviderContainerを作成する
2. `container.read(routerProvider)`でGoRouterインスタンスを取得する
3. 取得したインスタンスがGoRouter型であることを検証する

#### 期待結果

- GoRouterインスタンスが正常に取得できる
- インスタンスがnullでない
- インスタンスがGoRouter型である

#### テストデータ

```dart
// 入力: なし
// 出力: GoRouterインスタンス
```

#### 検証コード例

```dart
test('routerProviderはGoRouterインスタンスを生成する', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);

  expect(router, isNotNull);
  expect(router, isA<GoRouter>());
});
```

---

### TC-002: 初期ルート設定テスト（/）

**テストカテゴリ**: Unit Test
**対応要件**: FR-002（初期ルート設定）
**対応受け入れ基準**: AC-002

#### テスト目的

GoRouterの初期ルートが「/」（ホーム画面）に設定されていることを確認する。

#### 前提条件

- `routerProvider`が正常に動作する
- GoRouterの`initialLocation`が設定されている

#### テスト手順

1. ProviderContainerを作成する
2. `routerProvider`からGoRouterインスタンスを取得する
3. GoRouterの`routerDelegate.currentConfiguration.uri.path`を確認する

#### 期待結果

- 初期ロケーションが「/」である
- アプリ起動時にホーム画面が表示される設定になっている

#### テストデータ

```dart
// 入力: なし
// 期待される初期ルート: '/'
```

#### 検証コード例

```dart
test('初期ルートは/（ホーム画面）である', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  final configuration = router.routerDelegate.currentConfiguration;

  expect(configuration.uri.path, equals('/'));
});
```

---

### TC-003: ルート定義数テスト（5ルート）

**テストカテゴリ**: Unit Test
**対応要件**: FR-003（主要ルート定義）, FR-004（エラーページ対応）
**対応受け入れ基準**: AC-003〜AC-006

#### テスト目的

GoRouterに定義されているルート数が正確に5つ（home, settings, history, favorites + errorBuilder）であることを確認する。

#### 前提条件

- `routerProvider`が正常に動作する
- 4つの主要ルート + エラーページが定義されている

#### テスト手順

1. ProviderContainerを作成する
2. `routerProvider`からGoRouterインスタンスを取得する
3. GoRouterの`configuration.routes`の数を確認する

#### 期待結果

- ルート定義数が4つ（主要ルート）である
- errorBuilderが設定されている

#### テストデータ

```dart
// 入力: なし
// 期待されるルート数: 4（/, /settings, /history, /favorites）
// 期待されるエラーハンドラー: errorBuilder設定済み
```

#### 検証コード例

```dart
test('4つの主要ルートが定義されている', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  final routes = router.configuration.routes;

  expect(routes.length, equals(4));
});
```

---

### TC-004: 名前付きルート確認テスト

**テストカテゴリ**: Unit Test
**対応要件**: FR-003（主要ルート定義）
**対応受け入れ基準**: AC-007

#### テスト目的

各ルートに名前（name）が正しく設定されており、名前付きルーティングが可能であることを確認する。

#### 前提条件

- `routerProvider`が正常に動作する
- 各GoRouteにnameパラメータが設定されている

#### テスト手順

1. ProviderContainerを作成する
2. `routerProvider`からGoRouterインスタンスを取得する
3. 各ルートのname属性を確認する
4. 期待されるルート名（home, settings, history, favorites）が存在することを検証する

#### 期待結果

以下のルート名が定義されている:
- `home`（/）
- `settings`（/settings）
- `history`（/history）
- `favorites`（/favorites）

#### テストデータ

```dart
// 入力: なし
// 期待されるルート名リスト: ['home', 'settings', 'history', 'favorites']
```

#### 検証コード例

```dart
test('名前付きルートが正しく定義されている', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);
  final routes = router.configuration.routes.whereType<GoRoute>().toList();
  final routeNames = routes.map((r) => r.name).toList();

  expect(routeNames, containsAll(['home', 'settings', 'history', 'favorites']));
});
```

---

### TC-005: 不正パスでエラービルダー呼び出しテスト

**テストカテゴリ**: Unit Test
**対応要件**: FR-004（エラーページ対応）
**対応受け入れ基準**: AC-006

#### テスト目的

存在しないルートへのナビゲーション時にerrorBuilderが呼び出され、ErrorScreenが生成されることを確認する。

#### 前提条件

- `routerProvider`が正常に動作する
- errorBuilderが設定されている

#### テスト手順

1. ProviderContainerを作成する
2. `routerProvider`からGoRouterインスタンスを取得する
3. GoRouterのerrorBuilder設定を確認する

#### 期待結果

- errorBuilderがnullでない
- 不正パスアクセス時にerrorBuilderが呼び出される設定になっている

#### テストデータ

```dart
// 入力: 不正パス '/unknown', '/invalid-route', '/abc123'
// 出力: ErrorScreenウィジェット
```

#### 検証コード例

```dart
test('errorBuilderが設定されている', () {
  final container = ProviderContainer();
  addTearDown(container.dispose);

  final router = container.read(routerProvider);

  expect(router.configuration.errorBuilder, isNotNull);
});
```

---

## Widget Tests (screens_test.dart)

### TC-006: HomeScreen表示確認テスト

**テストカテゴリ**: Widget Test
**対応要件**: FR-005（画面スケルトン作成）
**対応受け入れ基準**: AC-002

#### テスト目的

HomeScreenウィジェットが正常にレンダリングされ、必要な要素が表示されることを確認する。

#### 前提条件

- `HomeScreen`が`lib/features/character_board/presentation/home_screen.dart`に実装されている
- StatelessWidgetとして実装されている
- constコンストラクタを持つ

#### テスト手順

1. MaterialApp内でHomeScreenをレンダリングする
2. 画面が正常に表示されることを確認する
3. 画面識別テキスト（「ホーム画面」等）の存在を確認する
4. Scaffoldの基本構造（AppBar + Body）を確認する

#### 期待結果

- HomeScreenが正常にレンダリングされる
- 「ホーム画面」または画面識別テキストが表示される
- AppBarが存在する
- エラーなくウィジェットがビルドされる

#### テストデータ

```dart
// 入力: const HomeScreen()
// 期待されるテキスト: 'ホーム画面' または画面識別用テキスト
```

#### 検証コード例

```dart
testWidgets('HomeScreenが正常に表示される', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: HomeScreen(),
    ),
  );

  expect(find.byType(HomeScreen), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.text('ホーム画面'), findsOneWidget);
});
```

---

### TC-007: SettingsScreen表示確認テスト

**テストカテゴリ**: Widget Test
**対応要件**: FR-005（画面スケルトン作成）
**対応受け入れ基準**: AC-003

#### テスト目的

SettingsScreenウィジェットが正常にレンダリングされ、必要な要素が表示されることを確認する。

#### 前提条件

- `SettingsScreen`が`lib/features/settings/presentation/settings_screen.dart`に実装されている
- StatelessWidgetとして実装されている
- constコンストラクタを持つ

#### テスト手順

1. MaterialApp内でSettingsScreenをレンダリングする
2. 画面が正常に表示されることを確認する
3. 画面識別テキスト（「設定画面」等）の存在を確認する
4. Scaffoldの基本構造（AppBar + Body）を確認する

#### 期待結果

- SettingsScreenが正常にレンダリングされる
- 「設定画面」または画面識別テキストが表示される
- AppBarが存在する
- エラーなくウィジェットがビルドされる

#### テストデータ

```dart
// 入力: const SettingsScreen()
// 期待されるテキスト: '設定画面' または画面識別用テキスト
```

#### 検証コード例

```dart
testWidgets('SettingsScreenが正常に表示される', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: SettingsScreen(),
    ),
  );

  expect(find.byType(SettingsScreen), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.text('設定画面'), findsOneWidget);
});
```

---

### TC-008: HistoryScreen表示確認テスト

**テストカテゴリ**: Widget Test
**対応要件**: FR-005（画面スケルトン作成）
**対応受け入れ基準**: AC-004

#### テスト目的

HistoryScreenウィジェットが正常にレンダリングされ、必要な要素が表示されることを確認する。

#### 前提条件

- `HistoryScreen`が`lib/features/history/presentation/history_screen.dart`に実装されている
- StatelessWidgetとして実装されている
- constコンストラクタを持つ

#### テスト手順

1. MaterialApp内でHistoryScreenをレンダリングする
2. 画面が正常に表示されることを確認する
3. 画面識別テキスト（「履歴画面」等）の存在を確認する
4. Scaffoldの基本構造（AppBar + Body）を確認する

#### 期待結果

- HistoryScreenが正常にレンダリングされる
- 「履歴画面」または画面識別テキストが表示される
- AppBarが存在する
- エラーなくウィジェットがビルドされる

#### テストデータ

```dart
// 入力: const HistoryScreen()
// 期待されるテキスト: '履歴画面' または画面識別用テキスト
```

#### 検証コード例

```dart
testWidgets('HistoryScreenが正常に表示される', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: HistoryScreen(),
    ),
  );

  expect(find.byType(HistoryScreen), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.text('履歴画面'), findsOneWidget);
});
```

---

### TC-009: FavoritesScreen表示確認テスト

**テストカテゴリ**: Widget Test
**対応要件**: FR-005（画面スケルトン作成）
**対応受け入れ基準**: AC-005

#### テスト目的

FavoritesScreenウィジェットが正常にレンダリングされ、必要な要素が表示されることを確認する。

#### 前提条件

- `FavoritesScreen`が`lib/features/favorites/presentation/favorites_screen.dart`に実装されている
- StatelessWidgetとして実装されている
- constコンストラクタを持つ

#### テスト手順

1. MaterialApp内でFavoritesScreenをレンダリングする
2. 画面が正常に表示されることを確認する
3. 画面識別テキスト（「お気に入り画面」等）の存在を確認する
4. Scaffoldの基本構造（AppBar + Body）を確認する

#### 期待結果

- FavoritesScreenが正常にレンダリングされる
- 「お気に入り画面」または画面識別テキストが表示される
- AppBarが存在する
- エラーなくウィジェットがビルドされる

#### テストデータ

```dart
// 入力: const FavoritesScreen()
// 期待されるテキスト: 'お気に入り画面' または画面識別用テキスト
```

#### 検証コード例

```dart
testWidgets('FavoritesScreenが正常に表示される', (tester) async {
  await tester.pumpWidget(
    const MaterialApp(
      home: FavoritesScreen(),
    ),
  );

  expect(find.byType(FavoritesScreen), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.byType(AppBar), findsOneWidget);
  expect(find.text('お気に入り画面'), findsOneWidget);
});
```

---

### TC-010: ErrorScreen表示確認テスト

**テストカテゴリ**: Widget Test
**対応要件**: FR-004（エラーページ対応）, FR-005（画面スケルトン作成）
**対応受け入れ基準**: AC-006

#### テスト目的

ErrorScreenウィジェットが正常にレンダリングされ、エラーメッセージとホーム復帰ボタンが表示されることを確認する。

#### 前提条件

- `ErrorScreen`が`lib/core/router/error_screen.dart`に実装されている
- StatelessWidgetとして実装されている
- エラー情報を受け取るパラメータを持つ

#### テスト手順

1. MaterialApp内でErrorScreenをレンダリングする
2. 画面が正常に表示されることを確認する
3. エラーメッセージが日本語で表示されることを確認する
4. ホーム画面への復帰ボタンが存在することを確認する

#### 期待結果

- ErrorScreenが正常にレンダリングされる
- 日本語のエラーメッセージが表示される
- ホームへの復帰ボタン（「ホームに戻る」等）が表示される
- エラーなくウィジェットがビルドされる

#### テストデータ

```dart
// 入力: ErrorScreen(error: GoException('ページが見つかりません'))
// 期待されるテキスト: 'ページが見つかりません' または類似のエラーメッセージ
// 期待されるボタン: 'ホームに戻る' または類似のナビゲーションボタン
```

#### 検証コード例

```dart
testWidgets('ErrorScreenが正常に表示される', (tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: ErrorScreen(error: Exception('テストエラー')),
    ),
  );

  expect(find.byType(ErrorScreen), findsOneWidget);
  expect(find.byType(Scaffold), findsOneWidget);
  expect(find.textContaining('エラー'), findsWidgets);
  expect(find.text('ホームに戻る'), findsOneWidget);
});
```

---

## Integration Tests (navigation_test.dart)

### TC-011: /から/settingsへのナビゲーション

**テストカテゴリ**: Integration Test
**対応要件**: FR-003（主要ルート定義）
**対応受け入れ基準**: AC-003

#### テスト目的

ホーム画面（/）から設定画面（/settings）へのナビゲーションが正常に機能することを確認する。

#### 前提条件

- GoRouterが正常に設定されている
- HomeScreenとSettingsScreenが実装されている
- ProviderScopeが設定されている

#### テスト手順

1. ProviderScopeとMaterialApp.routerでアプリをレンダリングする
2. 初期表示がHomeScreenであることを確認する
3. `router.go('/settings')`を実行する
4. `pumpAndSettle()`で遷移完了を待つ
5. SettingsScreenが表示されることを確認する

#### 期待結果

- HomeScreenからSettingsScreenへ正常に遷移する
- SettingsScreenの画面識別テキストが表示される
- エラーなく遷移が完了する

#### テストデータ

```dart
// 入力: router.go('/settings')
// 期待される画面: SettingsScreen
// 期待されるテキスト: '設定画面'
```

#### 検証コード例

```dart
testWidgets('/から/settingsへナビゲートできる', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('ホーム画面'), findsOneWidget);

  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go('/settings');
  await tester.pumpAndSettle();

  expect(find.text('設定画面'), findsOneWidget);
});
```

---

### TC-012: /settingsから/へ戻るナビゲーション

**テストカテゴリ**: Integration Test
**対応要件**: FR-003（主要ルート定義）
**対応受け入れ基準**: AC-003

#### テスト目的

設定画面（/settings）からホーム画面（/）へ戻るナビゲーションが正常に機能することを確認する。

#### 前提条件

- GoRouterが正常に設定されている
- HomeScreenとSettingsScreenが実装されている
- ProviderScopeが設定されている

#### テスト手順

1. ProviderScopeとMaterialApp.routerでアプリをレンダリングする
2. `router.go('/settings')`で設定画面へ遷移する
3. SettingsScreenが表示されることを確認する
4. `router.go('/')`を実行する
5. `pumpAndSettle()`で遷移完了を待つ
6. HomeScreenが表示されることを確認する

#### 期待結果

- SettingsScreenからHomeScreenへ正常に遷移する
- HomeScreenの画面識別テキストが表示される
- エラーなく遷移が完了する

#### テストデータ

```dart
// 入力: router.go('/')（/settingsからの遷移）
// 期待される画面: HomeScreen
// 期待されるテキスト: 'ホーム画面'
```

#### 検証コード例

```dart
testWidgets('/settingsから/へ戻れる', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go('/settings');
  await tester.pumpAndSettle();

  expect(find.text('設定画面'), findsOneWidget);

  GoRouter.of(context).go('/');
  await tester.pumpAndSettle();

  expect(find.text('ホーム画面'), findsOneWidget);
});
```

---

### TC-013: /から/historyへのナビゲーション

**テストカテゴリ**: Integration Test
**対応要件**: FR-003（主要ルート定義）
**対応受け入れ基準**: AC-004

#### テスト目的

ホーム画面（/）から履歴画面（/history）へのナビゲーションが正常に機能することを確認する。

#### 前提条件

- GoRouterが正常に設定されている
- HomeScreenとHistoryScreenが実装されている
- ProviderScopeが設定されている

#### テスト手順

1. ProviderScopeとMaterialApp.routerでアプリをレンダリングする
2. 初期表示がHomeScreenであることを確認する
3. `router.go('/history')`を実行する
4. `pumpAndSettle()`で遷移完了を待つ
5. HistoryScreenが表示されることを確認する

#### 期待結果

- HomeScreenからHistoryScreenへ正常に遷移する
- HistoryScreenの画面識別テキストが表示される
- エラーなく遷移が完了する

#### テストデータ

```dart
// 入力: router.go('/history')
// 期待される画面: HistoryScreen
// 期待されるテキスト: '履歴画面'
```

#### 検証コード例

```dart
testWidgets('/から/historyへナビゲートできる', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('ホーム画面'), findsOneWidget);

  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go('/history');
  await tester.pumpAndSettle();

  expect(find.text('履歴画面'), findsOneWidget);
});
```

---

### TC-014: /から/favoritesへのナビゲーション

**テストカテゴリ**: Integration Test
**対応要件**: FR-003（主要ルート定義）
**対応受け入れ基準**: AC-005

#### テスト目的

ホーム画面（/）からお気に入り画面（/favorites）へのナビゲーションが正常に機能することを確認する。

#### 前提条件

- GoRouterが正常に設定されている
- HomeScreenとFavoritesScreenが実装されている
- ProviderScopeが設定されている

#### テスト手順

1. ProviderScopeとMaterialApp.routerでアプリをレンダリングする
2. 初期表示がHomeScreenであることを確認する
3. `router.go('/favorites')`を実行する
4. `pumpAndSettle()`で遷移完了を待つ
5. FavoritesScreenが表示されることを確認する

#### 期待結果

- HomeScreenからFavoritesScreenへ正常に遷移する
- FavoritesScreenの画面識別テキストが表示される
- エラーなく遷移が完了する

#### テストデータ

```dart
// 入力: router.go('/favorites')
// 期待される画面: FavoritesScreen
// 期待されるテキスト: 'お気に入り画面'
```

#### 検証コード例

```dart
testWidgets('/から/favoritesへナビゲートできる', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  expect(find.text('ホーム画面'), findsOneWidget);

  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go('/favorites');
  await tester.pumpAndSettle();

  expect(find.text('お気に入り画面'), findsOneWidget);
});
```

---

### TC-015: 不正パスアクセス時のエラー画面表示

**テストカテゴリ**: Integration Test
**対応要件**: FR-004（エラーページ対応）
**対応受け入れ基準**: AC-006

#### テスト目的

存在しないルートへのナビゲーション時にErrorScreenが表示されることを確認する。

#### 前提条件

- GoRouterが正常に設定されている
- errorBuilderが設定されている
- ErrorScreenが実装されている
- ProviderScopeが設定されている

#### テスト手順

1. ProviderScopeとMaterialApp.routerでアプリをレンダリングする
2. 初期表示がHomeScreenであることを確認する
3. `router.go('/unknown')`を実行する（存在しないルート）
4. `pumpAndSettle()`で遷移完了を待つ
5. ErrorScreenが表示されることを確認する
6. エラーメッセージが表示されることを確認する
7. ホーム復帰ボタンが表示されることを確認する

#### 期待結果

- ErrorScreenが正常に表示される
- 日本語のエラーメッセージが表示される
- ホーム画面への復帰ボタンが表示される
- エラーなく処理が完了する

#### テストデータ

```dart
// 入力: router.go('/unknown'), router.go('/invalid-route'), router.go('/abc123')
// 期待される画面: ErrorScreen
// 期待されるテキスト: エラーメッセージ（日本語）
// 期待されるボタン: 'ホームに戻る'
```

#### 検証コード例

```dart
testWidgets('不正パスでErrorScreenが表示される', (tester) async {
  await tester.pumpWidget(
    ProviderScope(
      child: Consumer(
        builder: (context, ref, _) {
          final router = ref.watch(routerProvider);
          return MaterialApp.router(
            routerConfig: router,
          );
        },
      ),
    ),
  );
  await tester.pumpAndSettle();

  final context = tester.element(find.byType(MaterialApp));
  GoRouter.of(context).go('/unknown');
  await tester.pumpAndSettle();

  expect(find.byType(ErrorScreen), findsOneWidget);
  expect(find.textContaining('エラー'), findsWidgets);
  expect(find.text('ホームに戻る'), findsOneWidget);
});
```

---

## 補足: 名前付きルーティングテスト

以下のテストは、TC-011〜TC-014の代替テストとして、名前付きルーティング（`goNamed`）を使用した場合のナビゲーションを検証します。

### TC-011a: goNamed('settings')でのナビゲーション

```dart
testWidgets('goNamed("settings")で設定画面へナビゲートできる', (tester) async {
  // ... セットアップ ...

  GoRouter.of(context).goNamed('settings');
  await tester.pumpAndSettle();

  expect(find.text('設定画面'), findsOneWidget);
});
```

### TC-013a: goNamed('history')でのナビゲーション

```dart
testWidgets('goNamed("history")で履歴画面へナビゲートできる', (tester) async {
  // ... セットアップ ...

  GoRouter.of(context).goNamed('history');
  await tester.pumpAndSettle();

  expect(find.text('履歴画面'), findsOneWidget);
});
```

### TC-014a: goNamed('favorites')でのナビゲーション

```dart
testWidgets('goNamed("favorites")でお気に入り画面へナビゲートできる', (tester) async {
  // ... セットアップ ...

  GoRouter.of(context).goNamed('favorites');
  await tester.pumpAndSettle();

  expect(find.text('お気に入り画面'), findsOneWidget);
});
```

---

## テスト実行コマンド

```bash
# 全テスト実行
cd frontend/kotonoha_app
flutter test

# 特定のテストファイル実行
flutter test test/core/router/app_router_test.dart
flutter test test/integration/navigation_test.dart

# カバレッジ計測
flutter test --coverage
genhtml coverage/lcov.info -o coverage/html

# 特定のテストグループ実行
flutter test --name "routerProvider"
flutter test --name "ナビゲーション"
```

---

## テストカバレッジ目標

| カテゴリ | 対象ファイル | 目標カバレッジ |
|---------|-------------|---------------|
| Router | app_router.dart | 90%以上 |
| Screens | home_screen.dart | 80%以上 |
| Screens | settings_screen.dart | 80%以上 |
| Screens | history_screen.dart | 80%以上 |
| Screens | favorites_screen.dart | 80%以上 |
| Screens | error_screen.dart | 90%以上 |

**全体目標**: 80%以上（NFR-501準拠）

---

## 更新履歴

| 日付 | バージョン | 更新者 | 更新内容 |
|------|-----------|--------|---------|
| 2025-11-22 | 1.0 | Claude | 初版作成 |

---

## 関連ドキュメント

- [TASK-0015 要件定義書](/Volumes/external/dev/kotonoha/docs/implements/kotonoha/TASK-0015/requirements.md)
- [アーキテクチャ設計書](/Volumes/external/dev/kotonoha/docs/design/kotonoha/architecture.md)
- [技術スタック定義](/Volumes/external/dev/kotonoha/docs/tech-stack.md)
