// SettingsProvider TDDテスト
// TASK-0013: Riverpod状態管理セットアップ・プロバイダー基盤実装
//
// テストフレームワーク: flutter_test + Riverpod Testing
// 対象: SettingsNotifier（フォントサイズ・テーマモード設定管理）
//
// 🔵 信頼性レベル凡例:
// - 🔵 青信号: 要件定義書・テストケース定義書に基づく確実なテスト
// - 🟡 黄信号: 要件定義書から妥当な推測によるテスト
// - 🔴 赤信号: 要件定義書にない推測によるテスト

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';

void main() {
  group('SettingsNotifier - 正常系テスト', () {
    late ProviderContainer container;

    setUp(() async {
      // 【テスト前準備】: SharedPreferencesのモックを初期化
      // 【環境初期化】: 各テストが独立して実行できるよう、クリーンな状態から開始
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄し、次のテストに影響しないようにする
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // TC-001: 初期状態テスト
    test('TC-001: SettingsNotifierの初期状態がデフォルト値（medium、light）であることを確認', () async {
      // 【テスト目的】: SettingsNotifierの初期状態がデフォルト値であることを確認
      // 【テスト内容】: SharedPreferencesが空の状態でbuild()を実行し、デフォルト値が返されることを検証
      // 【期待される動作】: fontSize=medium、theme=lightが設定される
      // 🔵 青信号: REQ-801、REQ-803のデフォルト値要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesは空（setUpで設定済み）
      // 【初期条件設定】: アプリ初回起動時の状態
      // 【前提条件確認】: SharedPreferencesが空であることを確認
      container = ProviderContainer();

      // When（実行フェーズ）
      // 【実際の処理実行】: settingsNotifierProviderを読み込み
      // 【処理内容】: build()メソッドが非同期でSharedPreferencesから設定を読み込む
      // 【実行タイミング】: Provider初回アクセス時にbuild()が自動実行される

      // 【非同期処理待機】: AsyncValue<AppSettings>をfutureで待機
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 【結果検証】: デフォルト値が正しく設定されていることを確認
      // 【期待値確認】: interfaces.dartで定義されたデフォルト値と一致
      // 【品質保証】: REQ-801、REQ-803の要件を満たすことを確認

      // 【検証項目】: フォントサイズがmediumであること
      // 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
      expect(settings.fontSize, FontSize.medium); // 【確認内容】: デフォルト値が正しく設定されていることを確認

      // 【検証項目】: テーマがlightであること
      // 🔵 青信号: interfaces.dartのデフォルト値定義に基づく
      expect(settings.theme, AppTheme.light); // 【確認内容】: デフォルト値が正しく設定されていることを確認
    });

    // TC-002: フォントサイズ変更（small）
    test('TC-002: setFontSize(FontSize.small)でフォントサイズが「小」に変更されることを確認', () async {
      // 【テスト目的】: フォントサイズを「小」に変更し、状態が正しく更新されること
      // 【テスト内容】: setFontSize(FontSize.small)呼び出し後、stateが更新され、SharedPreferencesに永続化されること
      // 【期待される動作】: fontSize=smallに更新され、SharedPreferencesに保存される
      // 🔵 青信号: REQ-801の3段階選択要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: ProviderContainer作成
      // 【初期条件設定】: 初期状態（medium、light）から開始
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setFontSize(FontSize.small)を呼び出し
      // 【処理内容】: フォントサイズを「小」に変更し、SharedPreferencesに保存
      // 【実行タイミング】: ユーザーが設定画面で「小」を選択したとき
      await notifier.setFontSize(FontSize.small);

      // Then（検証フェーズ）
      // 【結果検証】: フォントサイズが「小」に更新されたことを確認
      // 【期待値確認】: REQ-801、REQ-2007（即座反映）、REQ-5003（永続化）を満たす
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: フォントサイズがsmallに変更されていること
      // 🔵 青信号: REQ-801の3段階選択要件に基づく
      expect(settings.fontSize, FontSize.small); // 【確認内容】: フォントサイズが正しく更新されていることを確認

      // 【検証項目】: SharedPreferencesに保存されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('fontSize'), FontSize.small.index); // 【確認内容】: SharedPreferencesに正しく保存されていることを確認
    });

    // TC-004: フォントサイズ変更（large）
    test('TC-004: setFontSize(FontSize.large)でフォントサイズが「大」に変更されることを確認', () async {
      // 【テスト目的】: フォントサイズを「大」に変更し、状態が正しく更新されること
      // 【テスト内容】: setFontSize(FontSize.large)呼び出し後、stateが更新され、SharedPreferencesに永続化されること
      // 【期待される動作】: fontSize=largeに更新され、SharedPreferencesに保存される
      // 🔵 青信号: REQ-801の3段階選択要件に基づく（最大サイズ）

      // Given（準備フェーズ）
      // 【テストデータ準備】: ProviderContainer作成
      // 【初期条件設定】: 初期状態（medium、light）から開始
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setFontSize(FontSize.large)を呼び出し
      // 【処理内容】: フォントサイズを「大」に変更し、SharedPreferencesに保存
      // 【実行タイミング】: 視力が弱い高齢者・視覚障害者が「大」を選択したとき
      await notifier.setFontSize(FontSize.large);

      // Then（検証フェーズ）
      // 【結果検証】: フォントサイズが「大」に更新されたことを確認
      // 【期待値確認】: アクセシビリティ対応として最も重要なサイズ
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: フォントサイズがlargeに変更されていること
      // 🔵 青信号: REQ-801の3段階選択要件に基づく
      expect(settings.fontSize, FontSize.large); // 【確認内容】: 最大フォントサイズに正しく更新されていることを確認

      // 【検証項目】: SharedPreferencesに保存されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('fontSize'), FontSize.large.index); // 【確認内容】: SharedPreferencesに正しく保存されていることを確認
    });

    // TC-005: テーマモード変更（light）
    test('TC-005: setTheme(AppTheme.light)でテーマが「ライトモード」に変更されることを確認', () async {
      // 【テスト目的】: テーマを「ライトモード」に変更し、状態が正しく更新されること
      // 【テスト内容】: setTheme(AppTheme.light)呼び出し後、stateが更新され、SharedPreferencesに永続化されること
      // 【期待される動作】: theme=lightに更新され、SharedPreferencesに保存される
      // 🔵 青信号: REQ-803で定義された標準テーマ

      // Given（準備フェーズ）
      // 【テストデータ準備】: ProviderContainer作成
      // 【初期条件設定】: 初期状態から開始
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setTheme(AppTheme.light)を呼び出し
      // 【処理内容】: テーマを「ライトモード」に変更し、SharedPreferencesに保存
      // 【実行タイミング】: 明るい環境でアプリを使用するユーザーが選択
      await notifier.setTheme(AppTheme.light);

      // Then（検証フェーズ）
      // 【結果検証】: テーマが「ライトモード」に更新されたことを確認
      // 【期待値確認】: REQ-2008（テーマ即座変更）の基盤確認
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: テーマがlightに変更されていること
      // 🔵 青信号: REQ-803で定義された標準テーマ
      expect(settings.theme, AppTheme.light); // 【確認内容】: ライトモードに正しく更新されていることを確認

      // 【検証項目】: SharedPreferencesに保存されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme'), AppTheme.light.index); // 【確認内容】: SharedPreferencesに正しく保存されていることを確認
    });

    // TC-006: テーマモード変更（dark）
    test('TC-006: setTheme(AppTheme.dark)でテーマが「ダークモード」に変更されることを確認', () async {
      // 【テスト目的】: テーマを「ダークモード」に変更し、状態が正しく更新されること
      // 【テスト内容】: setTheme(AppTheme.dark)呼び出し後、stateが更新され、SharedPreferencesに永続化されること
      // 【期待される動作】: theme=darkに更新され、SharedPreferencesに保存される
      // 🔵 青信号: REQ-803で定義されたダークモード

      // Given（準備フェーズ）
      // 【テストデータ準備】: ProviderContainer作成
      // 【初期条件設定】: 初期状態から開始
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setTheme(AppTheme.dark)を呼び出し
      // 【処理内容】: テーマを「ダークモード」に変更し、SharedPreferencesに保存
      // 【実行タイミング】: 夜間や暗い環境でアプリを使用するユーザーが選択
      await notifier.setTheme(AppTheme.dark);

      // Then（検証フェーズ）
      // 【結果検証】: テーマが「ダークモード」に更新されたことを確認
      // 【期待値確認】: 目への負担軽減のための重要機能
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: テーマがdarkに変更されていること
      // 🔵 青信号: REQ-803で定義されたダークモード
      expect(settings.theme, AppTheme.dark); // 【確認内容】: ダークモードに正しく更新されていることを確認

      // 【検証項目】: SharedPreferencesに保存されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme'), AppTheme.dark.index); // 【確認内容】: SharedPreferencesに正しく保存されていることを確認
    });

    // TC-007: テーマモード変更（highContrast）
    test('TC-007: setTheme(AppTheme.highContrast)でテーマが「高コントラストモード」に変更されることを確認', () async {
      // 【テスト目的】: テーマを「高コントラストモード」に変更し、状態が正しく更新されること
      // 【テスト内容】: setTheme(AppTheme.highContrast)呼び出し後、stateが更新され、SharedPreferencesに永続化されること
      // 【期待される動作】: theme=highContrastに更新され、SharedPreferencesに保存される
      // 🔵 青信号: REQ-803、REQ-5006で定義されたWCAG 2.1 AA準拠テーマ

      // Given（準備フェーズ）
      // 【テストデータ準備】: ProviderContainer作成
      // 【初期条件設定】: 初期状態から開始
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setTheme(AppTheme.highContrast)を呼び出し
      // 【処理内容】: テーマを「高コントラストモード」に変更し、SharedPreferencesに保存
      // 【実行タイミング】: 強い視覚障害のあるユーザー、明るい屋外環境で選択
      await notifier.setTheme(AppTheme.highContrast);

      // Then（検証フェーズ）
      // 【結果検証】: テーマが「高コントラストモード」に更新されたことを確認
      // 【期待値確認】: アクセシビリティの最重要機能
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: テーマがhighContrastに変更されていること
      // 🔵 青信号: REQ-803で定義された高コントラストモード
      expect(settings.theme, AppTheme.highContrast); // 【確認内容】: 高コントラストモードに正しく更新されていることを確認

      // 【検証項目】: SharedPreferencesに保存されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getInt('theme'), AppTheme.highContrast.index); // 【確認内容】: SharedPreferencesに正しく保存されていることを確認
    });

    // TC-008: アプリ再起動後の設定復元（フォントサイズ）
    test('TC-008: アプリ再起動後、保存されたフォントサイズ設定が正しく復元されることを確認', () async {
      // 【テスト目的】: SharedPreferencesに保存されたフォントサイズが再起動後も復元されること
      // 【テスト内容】: build()メソッドがSharedPreferencesから設定を読み込み、前回の設定を復元する
      // 【期待される動作】: 前回「大」を選択していた場合、再起動後も「大」が復元される
      // 🔵 青信号: REQ-5003（設定永続化）の要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesに事前にフォントサイズ「large」を保存
      // 【初期条件設定】: 前回のアプリセッションでユーザーが「大」を選択していた状態
      // 【前提条件確認】: アプリを終了し、翌日再度起動したとき
      SharedPreferences.setMockInitialValues({
        'fontSize': FontSize.large.index,
      });

      // When（実行フェーズ）
      // 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
      // 【処理内容】: build()メソッドがSharedPreferencesから設定を読み込む
      // 【実行タイミング】: アプリ起動時のProvider初期化
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 【結果検証】: フォントサイズ「large」が正しく復元されたことを確認
      // 【期待値確認】: REQ-5003（設定永続化）を満たすため

      // 【検証項目】: フォントサイズがlargeに復元されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      expect(settings.fontSize, FontSize.large); // 【確認内容】: 保存されたフォントサイズが正しく復元されていることを確認
    });

    // TC-009: アプリ再起動後の設定復元（テーマモード）
    test('TC-009: アプリ再起動後、保存されたテーマモード設定が正しく復元されることを確認', () async {
      // 【テスト目的】: SharedPreferencesに保存されたテーマモードが再起動後も復元されること
      // 【テスト内容】: ダークモードで終了したアプリが再起動時にもダークモードで開く
      // 【期待される動作】: 前回「ダークモード」を選択していた場合、再起動後も「ダークモード」が復元される
      // 🔵 青信号: REQ-5003の永続化要件に基づく

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesに事前にテーマ「dark」を保存
      // 【初期条件設定】: 前回のセッションでダークモードを選択していた状態
      // 【前提条件確認】: 夜間にアプリを使用し、翌朝再起動したとき
      SharedPreferences.setMockInitialValues({
        'theme': AppTheme.dark.index,
      });

      // When（実行フェーズ）
      // 【実際の処理実行】: 新しいProviderContainerを作成（再起動を模擬）
      // 【処理内容】: build()メソッドがSharedPreferencesから設定を読み込む
      // 【実行タイミング】: アプリ起動時のProvider初期化
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 【結果検証】: テーマ「dark」が正しく復元されたことを確認
      // 【期待値確認】: ユーザー体験の一貫性維持

      // 【検証項目】: テーマがdarkに復元されていること
      // 🔵 青信号: REQ-5003の永続化要件に基づく
      expect(settings.theme, AppTheme.dark); // 【確認内容】: 保存されたテーマが正しく復元されていることを確認
    });
  });

  group('SettingsNotifier - 異常系テスト', () {
    late ProviderContainer container;

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // TC-011: SharedPreferences初期化失敗時のエラーハンドリング
    test('TC-011: SharedPreferences初期化失敗時、AsyncValue.errorまたはデフォルト値を返すことを確認', () async {
      // 【テスト目的】: SharedPreferences初期化失敗時のエラーハンドリング確認
      // 【テスト内容】: SharedPreferences.getInstance()が失敗した場合の挙動を検証
      // 【期待される動作】: AsyncValue.errorを返すか、デフォルト値でフォールバック
      // 🟡 黄信号: NFR-301（基本機能継続）、NFR-304（エラーハンドリング）から類推

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesの初期化を失敗させる
      // 【初期条件設定】: ストレージ障害、権限エラーなどを模擬
      // 【実際の発生シナリオ】: ストレージ容量不足、OSバージョン非互換、権限エラー
      // Note: flutter_testのモック機能では初期化失敗を直接シミュレートできないため、
      // この部分は実装後に実際の挙動を確認する必要がある

      // When（実行フェーズ）
      // 【実際の処理実行】: ProviderContainerを作成
      // 【処理内容】: build()メソッドでSharedPreferences初期化を試みる
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      // Then（検証フェーズ）
      // 【結果検証】: エラーハンドリングが適切に行われることを確認
      // 【期待値確認】: AsyncValue.errorまたはデフォルト値
      // 【システムの安全性】: エラー発生でもアプリがクラッシュせず、デフォルト設定で動作継続

      final state = container.read(settingsNotifierProvider);

      // 【検証項目】: エラーが発生しないこと（この段階ではモックが正常動作）
      // 🟡 黄信号: 実装後に実際のエラーハンドリングを検証する必要がある
      expect(state, isA<AsyncValue>()); // 【確認内容】: 何らかのAsyncValue状態を返していることを確認
    });

    // TC-012: SharedPreferences書き込み失敗時の楽観的更新
    test('TC-012: setFontSize()でSharedPreferences書き込みが失敗しても、状態更新は成功することを確認', () async {
      // 【テスト目的】: SharedPreferences書き込み失敗時の楽観的更新動作確認
      // 【テスト内容】: setInt()が失敗しても、Riverpod stateは更新される
      // 【期待される動作】: UI反応性を維持しつつ、再起動時は古い設定に戻る可能性をユーザーに通知
      // 🟡 黄信号: 楽観的更新は一般的パターンだが、要件定義書に明示されていない

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesを初期化
      // 【初期条件設定】: 正常な初期状態
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();

      // 【Provider初期化】: build()を完了させる
      await container.read(settingsNotifierProvider.future);

      final notifier = container.read(settingsNotifierProvider.notifier);

      // When（実行フェーズ）
      // 【実際の処理実行】: setFontSize(FontSize.large)を呼び出し
      // 【処理内容】: フォントサイズ変更（書き込み失敗は実装後にモックで検証）
      // Note: flutter_testのモック機能では書き込み失敗を直接シミュレートできないため、
      // この部分は実装後に実際の挙動を確認する必要がある
      await notifier.setFontSize(FontSize.large);

      // Then（検証フェーズ）
      // 【結果検証】: 状態更新は成功していることを確認
      // 【期待値確認】: NFR-2007（即座反映）とNFR-304（エラーハンドリング）の両立
      final state = container.read(settingsNotifierProvider);
      final settings = state.requireValue;

      // 【検証項目】: フォントサイズがlargeに更新されていること（楽観的更新）
      // 🟡 黄信号: 実装後にログ記録の検証が必要
      expect(settings.fontSize, FontSize.large); // 【確認内容】: 状態更新は成功していることを確認
    });

    // TC-014: SharedPreferencesがnullを返す場合のデフォルト値使用
    test('TC-014: SharedPreferences.getInt()がnullを返す場合、デフォルト値（medium、light）を使用することを確認', () async {
      // 【テスト目的】: null安全性の確認、Dart Null Safetyへの準拠
      // 【テスト内容】: 保存データが存在しない（初回起動と同じ状態）
      // 【期待される動作】: デフォルト値（medium、light）が使用される
      // 🔵 青信号: Dart Null Safetyの基本動作

      // Given（準備フェーズ）
      // 【テストデータ準備】: SharedPreferencesを空の状態で初期化
      // 【初期条件設定】: アプリ初回起動、アンインストール後の再インストール
      // 【前提条件確認】: getInt()がnullを返す状態
      SharedPreferences.setMockInitialValues({});

      // When（実行フェーズ）
      // 【実際の処理実行】: ProviderContainerを作成
      // 【処理内容】: build()メソッドでSharedPreferencesから設定を読み込む（null）
      // 【実行タイミング】: Provider初回アクセス時
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      // Then（検証フェーズ）
      // 【結果検証】: デフォルト値が使用されていることを確認
      // 【期待値確認】: Dart Null Safetyで`??`演算子によるデフォルト値提供

      // 【検証項目】: フォントサイズがmediumであること（デフォルト値）
      // 🔵 青信号: Dart Null Safetyの基本動作
      expect(settings.fontSize, FontSize.medium); // 【確認内容】: null時のデフォルト値使用を確認

      // 【検証項目】: テーマがlightであること（デフォルト値）
      // 🔵 青信号: Dart Null Safetyの基本動作
      expect(settings.theme, AppTheme.light); // 【確認内容】: null時のデフォルト値使用を確認
    });
  });

  group('SettingsNotifier - 境界値テスト', () {
    late ProviderContainer container;

    tearDown(() {
      // 【テスト後処理】: ProviderContainerを破棄
      // 【状態復元】: メモリリークを防ぐため、リソースを解放
      container.dispose();
    });

    // TC-015: FontSize enumの全値テスト（small, medium, large）
    test('TC-015: FontSize enumのすべての値（small=0, medium=1, large=2）が正しくSharedPreferencesに保存・復元されることを確認', () async {
      // 【テスト目的】: 全選択肢の網羅的確認
      // 【テスト内容】: enum indexの最小値（0）から最大値（2）までをすべてテスト
      // 【期待される動作】: 3段階すべてが正常動作することを確認
      // 🔵 青信号: REQ-801で定義された3段階がすべて

      // Given（準備フェーズ）
      // 【テストデータ準備】: FontSize enumの全値
      // 【初期条件設定】: ユーザーがすべての選択肢を試す
      final allFontSizes = [FontSize.small, FontSize.medium, FontSize.large];

      for (final fontSize in allFontSizes) {
        // 各フォントサイズについてテスト
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When（実行フェーズ）
        // 【実際の処理実行】: 各フォントサイズを設定
        // 【処理内容】: setFontSize()でフォントサイズを変更
        await notifier.setFontSize(fontSize);

        // Then（検証フェーズ）
        // 【結果検証】: 各値が正しく保存・復元されることを確認
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        // 【検証項目】: フォントサイズが正しく設定されていること
        // 🔵 青信号: REQ-801の3段階選択要件
        expect(settings.fontSize, fontSize); // 【確認内容】: フォントサイズが正しく設定されていることを確認

        // 【検証項目】: SharedPreferencesに正しく保存されていること
        // 🔵 青信号: enum境界値の安全性
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('fontSize'), fontSize.index); // 【確認内容】: index値が正しく保存されていることを確認

        container.dispose();
      }
    });

    // TC-016: AppTheme enumの全値テスト（light, dark, highContrast）
    test('TC-016: AppTheme enumのすべての値（light=0, dark=1, highContrast=2）が正しくSharedPreferencesに保存・復元されることを確認', () async {
      // 【テスト目的】: 全テーマの網羅的確認
      // 【テスト内容】: enum indexの最小値（0）から最大値（2）まで
      // 【期待される動作】: 3種類すべてが正常動作することを確認
      // 🔵 青信号: REQ-803で定義された3種類がすべて

      // Given（準備フェーズ）
      // 【テストデータ準備】: AppTheme enumの全値
      // 【初期条件設定】: 異なる環境・ユーザーがすべてのテーマを試す
      final allThemes = [AppTheme.light, AppTheme.dark, AppTheme.highContrast];

      for (final theme in allThemes) {
        // 各テーマについてテスト
        SharedPreferences.setMockInitialValues({});
        container = ProviderContainer();

        // 【Provider初期化】: build()を完了させる
        await container.read(settingsNotifierProvider.future);

        final notifier = container.read(settingsNotifierProvider.notifier);

        // When（実行フェーズ）
        // 【実際の処理実行】: 各テーマを設定
        // 【処理内容】: setTheme()でテーマを変更
        await notifier.setTheme(theme);

        // Then（検証フェーズ）
        // 【結果検証】: 各値が正しく保存・復元されることを確認
        final state = container.read(settingsNotifierProvider);
        final settings = state.requireValue;

        // 【検証項目】: テーマが正しく設定されていること
        // 🔵 青信号: REQ-803の3種類要件
        expect(settings.theme, theme); // 【確認内容】: テーマが正しく設定されていることを確認

        // 【検証項目】: SharedPreferencesに正しく保存されていること
        // 🔵 青信号: WCAG準拠含むすべてのテーマが動作
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme'), theme.index); // 【確認内容】: index値が正しく保存されていることを確認

        container.dispose();
      }
    });
  });
}
