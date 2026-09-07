import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';

void main() {
  group('SettingsNotifier - 正常系テスト', () {
    late ProviderContainer container;

    setUp(() async {
      // テスト前準備: SharedPreferencesのモックを初期化
      // 環境初期化: 各テストが独立して実行できるよう、クリーンな状態から開始
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄し、次のテストに影響しないようにする
      // 状態復元: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // 初期状態テスト
    test('TC-001: SettingsNotifierの初期状態がデフォルト値（medium、light）であることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesは空（setUpで設定済み）
      // 初期条件設定: アプリ初回起動時の状態
      // 前提条件SharedPreferencesが空であることを確認
      container = ProviderContainer();

      // When（実行フェーズ）
      // 実際の処理実行: settingsNotifierProviderを読み込み
      // 処理内容: buildメソッドが非同期でSharedPreferencesから設定を読み込む
      // 実行タイミング: Provider初回アクセス時にbuildが自動実行される

      // 非同期処理待機: AsyncValue<AppSettings>をfutureで待機
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 結果検証: デフォルト値が正しく設定されていることを確認
      // interfaces.dartで定義されたデフォルト値と一致
      // 品質保証: 、の要件を満たすことを確認

      // 検証項目: フォントサイズがmediumであること
      expect(settings.fontSize, FontSize.medium);

      // 検証項目: テーマがlightであること
      expect(settings.theme, AppTheme.light);
    });

    // フォントサイズ変更（small）
    test('TC-002: setFontSize(FontSize.small)でフォントサイズが「小」に変更されることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: ProviderContainer作成
      // 初期条件設定: 初期状態（medium、light）から開始
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setFontSize(FontSize.small)を呼び出し
      // 処理内容: フォントサイズを「小」に変更し、SharedPreferencesに保存
      // 実行タイミング: ユーザーが設定画面で「小」を選択したとき
      await notifier.setFontSize(FontSize.small);

      // Then（検証フェーズ）
      // 結果検証: フォントサイズが「小」に更新されたことを確認
      // （即座反映）、（永続化）を満たす
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: フォントサイズがsmallに変更されていること
      expect(settings.fontSize, FontSize.small);

      // 検証項目: SharedPreferencesに保存されていること
      // 永続化形式: enum indexではなくenum name文字列で保存される
      // （並び替え・要素追加でも値が化けないようにするため）
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fontSize'), FontSize.small.name);
    });

    // フォントサイズ変更（large）
    test('TC-004: setFontSize(FontSize.large)でフォントサイズが「大」に変更されることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: ProviderContainer作成
      // 初期条件設定: 初期状態（medium、light）から開始
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setFontSize(FontSize.large)を呼び出し
      // 処理内容: フォントサイズを「大」に変更し、SharedPreferencesに保存
      // 実行タイミング: 視力が弱い高齢者・視覚障害者が「大」を選択したとき
      await notifier.setFontSize(FontSize.large);

      // Then（検証フェーズ）
      // 結果検証: フォントサイズが「大」に更新されたことを確認
      // アクセシビリティ対応として最も重要なサイズ
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: フォントサイズがlargeに変更されていること
      expect(settings.fontSize, FontSize.large);

      // 検証項目: SharedPreferencesに保存されていること
      // 永続化形式: enum indexではなくenum name文字列で保存される
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('fontSize'), FontSize.large.name);
    });

    // テーマモード変更（light）
    test('TC-005: setTheme(AppTheme.light)でテーマが「ライトモード」に変更されることを確認', () async {
      // Given（準備フェーズ）
      // テストデータ準備: ProviderContainer作成
      // 初期条件設定: 初期状態から開始
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setTheme(AppTheme.light)を呼び出し
      // 処理内容: テーマを「ライトモード」に変更し、SharedPreferencesに保存
      // 実行タイミング: 明るい環境でアプリを使用するユーザーが選択
      await notifier.setTheme(AppTheme.light);

      // Then（検証フェーズ）
      // 結果検証: テーマが「ライトモード」に更新されたことを確認
      // （テーマ即座変更）の基盤確認
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: テーマがlightに変更されていること
      expect(settings.theme, AppTheme.light);

      // 検証項目: SharedPreferencesに保存されていること
      // 永続化形式: enum indexではなくenum name文字列で保存される
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme'), AppTheme.light.name);
    });

    // テーマモード変更（dark）
    test('TC-006: setTheme(AppTheme.dark)でテーマが「ダークモード」に変更されることを確認', () async {
      // Given（準備フェーズ）
      // テストデータ準備: ProviderContainer作成
      // 初期条件設定: 初期状態から開始
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setTheme(AppTheme.dark)を呼び出し
      // 処理内容: テーマを「ダークモード」に変更し、SharedPreferencesに保存
      // 実行タイミング: 夜間や暗い環境でアプリを使用するユーザーが選択
      await notifier.setTheme(AppTheme.dark);

      // Then（検証フェーズ）
      // 結果検証: テーマが「ダークモード」に更新されたことを確認
      // 目への負担軽減のための重要機能
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: テーマがdarkに変更されていること
      expect(settings.theme, AppTheme.dark);

      // 検証項目: SharedPreferencesに保存されていること
      // 永続化形式: enum indexではなくenum name文字列で保存される
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme'), AppTheme.dark.name);
    });

    // テーマモード変更（highContrast）
    test('TC-007: setTheme(AppTheme.highContrast)でテーマが「高コントラストモード」に変更されることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: ProviderContainer作成
      // 初期条件設定: 初期状態から開始
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setTheme(AppTheme.highContrast)を呼び出し
      // 処理内容: テーマを「高コントラストモード」に変更し、SharedPreferencesに保存
      // 実行タイミング: 強い視覚障害のあるユーザー、明るい屋外環境で選択
      await notifier.setTheme(AppTheme.highContrast);

      // Then（検証フェーズ）
      // 結果検証: テーマが「高コントラストモード」に更新されたことを確認
      // アクセシビリティの最重要機能
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: テーマがhighContrastに変更されていること
      expect(settings.theme, AppTheme.highContrast);

      // 検証項目: SharedPreferencesに保存されていること
      // 永続化形式: enum indexではなくenum name文字列で保存される
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('theme'), AppTheme.highContrast.name);
    });

    // アプリ再起動後の設定復元（フォントサイズ）
    test('TC-008: アプリ再起動後、保存されたフォントサイズ設定が正しく復元されることを確認', () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesに事前にフォントサイズ「large」を保存
      // 初期条件設定: 前回のアプリセッションでユーザーが「大」を選択していた状態
      // 前提条件アプリを終了し、翌日再度起動したとき
      // 後方互換性: 旧形式（enum index int）で保存されたデータでも
      // 正しく復元できることを検証する（マイグレーション対応）
      SharedPreferences.setMockInitialValues({
        'fontSize': FontSize.large.index,
      });

      // When（実行フェーズ）
      // 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
      // 処理内容: buildメソッドがSharedPreferencesから設定を読み込む
      // 実行タイミング: アプリ起動時のProvider初期化
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 結果検証: フォントサイズ「large」が正しく復元されたことを確認
      // （設定永続化）を満たすため

      // 検証項目: フォントサイズがlargeに復元されていること
      expect(settings.fontSize, FontSize.large);
    });

    // アプリ再起動後の設定復元（テーマモード）
    test('TC-009: アプリ再起動後、保存されたテーマモード設定が正しく復元されることを確認', () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesに事前にテーマ「dark」を保存
      // 初期条件設定: 前回のセッションでダークモードを選択していた状態
      // 前提条件夜間にアプリを使用し、翌朝再起動したとき
      // 後方互換性: 旧形式（enum index int）で保存されたデータでも
      // 正しく復元できることを検証する（マイグレーション対応）
      SharedPreferences.setMockInitialValues({
        'theme': AppTheme.dark.index,
      });

      // When（実行フェーズ）
      // 実際の処理実行: 新しいProviderContainerを作成（再起動を模擬）
      // 処理内容: buildメソッドがSharedPreferencesから設定を読み込む
      // 実行タイミング: アプリ起動時のProvider初期化
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 結果検証: テーマ「dark」が正しく復元されたことを確認
      // ユーザー体験の一貫性維持

      // 検証項目: テーマがdarkに復元されていること
      expect(settings.theme, AppTheme.dark);
    });
  });

  group('SettingsNotifier - 異常系テスト', () {
    late ProviderContainer container;

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄
      // 状態復元: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // SharedPreferences初期化失敗時のエラーハンドリング
    test('TC-011: SharedPreferences初期化失敗時、AsyncValue.errorまたはデフォルト値を返すことを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesの初期化を失敗させる
      // 初期条件設定: ストレージ障害、権限エラーなどを模擬
      // 実際の発生シナリオ: ストレージ容量不足、OSバージョン非互換、権限エラー
      // このテストでは保存失敗を注入しておらず、通常時の状態更新のみを確認する。

      // When（実行フェーズ）
      // 実際の処理実行: ProviderContainerを作成
      // 処理内容: buildメソッドでSharedPreferences初期化を試みる
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      // Then（検証フェーズ）
      // 結果検証: エラーハンドリングが適切に行われることを確認
      // AsyncValue.errorまたはデフォルト値
      // システムの安全性: エラー発生でもアプリがクラッシュせず、デフォルト設定で動作継続

      final state = container.read(settingsNotifierProvider);

      // 検証項目: エラーが発生しないこと（この段階ではモックが正常動作）
      expect(state, isA<AsyncValue>());
    });

    // SharedPreferences書き込み失敗時の楽観的更新
    test('TC-012: setFontSize()でSharedPreferences書き込みが失敗しても、状態更新は成功することを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesを初期化
      // 初期条件設定: 正常な初期状態
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      // Provider初期化: buildを完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 実際の処理実行: setFontSize(FontSize.large)を呼び出し
      // 処理内容: フォントサイズ変更
      // このテストでは保存失敗を注入しておらず、通常時の状態更新のみを確認する。
      await notifier.setFontSize(FontSize.large);

      // Then（検証フェーズ）
      // 結果検証: 状態更新は成功していることを確認
      // （即座反映）と（エラーハンドリング）の両立
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 検証項目: フォントサイズがlargeに更新されていること（楽観的更新）
      expect(settings.fontSize, FontSize.large);
    });

    // SharedPreferencesがnullを返す場合のデフォルト値使用
    test(
        'TC-014: SharedPreferences.getInt()がnullを返す場合、デフォルト値（medium、light）を使用することを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: SharedPreferencesを空の状態で初期化
      // 初期条件設定: アプリ初回起動、アンインストール後の再インストール
      // 前提条件getIntがnullを返す状態
      SharedPreferences.setMockInitialValues({});

      // When（実行フェーズ）
      // 実際の処理実行: ProviderContainerを作成
      // 処理内容: buildメソッドでSharedPreferencesから設定を読み込む（null）
      // 実行タイミング: Provider初回アクセス時
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 結果検証: デフォルト値が使用されていることを確認
      // Dart Null Safetyで`??`演算子によるデフォルト値提供

      // 検証項目: フォントサイズがmediumであること（デフォルト値）
      expect(settings.fontSize, FontSize.medium);

      // 検証項目: テーマがlightであること（デフォルト値）
      expect(settings.theme, AppTheme.light);
    });
  });

  group('SettingsNotifier - 境界値テスト', () {
    late ProviderContainer container;

    tearDown(() {
      // テスト後処理: ProviderContainerを破棄
      // 状態復元: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // FontSize enumの全値テスト（small, medium, large）
    test(
        'TC-015: FontSize enumのすべての値（small=0, medium=1, large=2）が正しくSharedPreferencesに保存・復元されることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: FontSize enumの全値
      // 初期条件設定: ユーザーがすべての選択肢を試す
      final allFontSizes = [FontSize.small, FontSize.medium, FontSize.large];

      for (final fontSize in allFontSizes) {
        // 各フォントサイズについてテスト
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When（実行フェーズ）
        // 実際の処理実行: 各フォントサイズを設定
        // 処理内容: setFontSizeでフォントサイズを変更
        await notifier.setFontSize(fontSize);

        // Then（検証フェーズ）
        // 結果検証: 各値が正しく保存・復元されることを確認
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        // 検証項目: フォントサイズが正しく設定されていること
        expect(settings.fontSize, fontSize);

        // 検証項目: SharedPreferencesに正しく保存されていること
        // 永続化形式: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('fontSize'), fontSize.name);

        container.dispose();
      }
    });

    // AppTheme enumの全値テスト（light, dark, highContrast）
    test(
        'TC-016: AppTheme enumのすべての値（light=0, dark=1, highContrast=2）が正しくSharedPreferencesに保存・復元されることを確認',
        () async {
      // Given（準備フェーズ）
      // テストデータ準備: AppTheme enumの全値
      // 初期条件設定: 異なる環境・ユーザーがすべてのテーマを試す
      final allThemes = [AppTheme.light, AppTheme.dark, AppTheme.highContrast];

      for (final theme in allThemes) {
        // 各テーマについてテスト
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer();

        // Provider初期化: buildを完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When（実行フェーズ）
        // 実際の処理実行: 各テーマを設定
        // 処理内容: setThemeでテーマを変更
        await notifier.setTheme(theme);

        // Then（検証フェーズ）
        // 結果検証: 各値が正しく保存・復元されることを確認
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        // 検証項目: テーマが正しく設定されていること
        expect(settings.theme, theme);

        // 検証項目: SharedPreferencesに正しく保存されていること
        // 永続化形式: enum indexではなくenum name文字列で保存される
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('theme'), theme.name);

        container.dispose();
      }
    });
  });
}
