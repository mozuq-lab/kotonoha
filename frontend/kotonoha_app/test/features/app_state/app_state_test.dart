/// アプリ状態復元・クラッシュリカバリ テスト
///
/// TASK-0079: アプリ状態復元・クラッシュリカバリ実装
///
/// 関連要件:
/// - NFR-302: データ整合性の保持
/// - EDGE-201: バックグラウンド復帰時の状態復元
/// - REQ-5003: クラッシュ時のデータ保持
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/app_state/providers/app_session_provider.dart';

void main() {
  group('AppSessionProvider', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // 入力中テキスト保存・復元テスト
    // =========================================================================

    group('入力中テキスト保存・復元', () {
      test('TC-079-001: 入力中テキストが保存される', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // When: テキストを保存
        await notifier.saveDraftText('入力中のテキスト');

        // Then: テキストが保存される
        expect(notifier.draftText, equals('入力中のテキスト'));
      });

      test('TC-079-002: アプリ再起動後に入力中テキストが復元される', () async {
        // Given: テキストを保存
        SharedPreferences.setMockInitialValues({
          'draft_text': '保存されたテキスト',
        });

        final newContainer = ProviderContainer();
        final notifier = newContainer.read(appSessionProvider.notifier);

        // When: 初期化
        await notifier.initialize();

        // Then: テキストが復元される
        expect(notifier.draftText, equals('保存されたテキスト'));

        newContainer.dispose();
      });

      test('TC-079-003: 空のテキストはクリアされる', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // Given: テキストを保存
        await notifier.saveDraftText('テスト');

        // When: 空のテキストを保存
        await notifier.saveDraftText('');

        // Then: テキストがクリアされる
        expect(notifier.draftText, isEmpty);
      });
    });

    // =========================================================================
    // 最後の画面状態復元テスト
    // =========================================================================

    group('最後の画面状態復元', () {
      test('TC-079-004: 最後に表示した画面パスが保存される', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // When: 画面パスを保存
        await notifier.saveLastRoute('/history');

        // Then: パスが保存される
        expect(notifier.lastRoute, equals('/history'));
      });

      test('TC-079-005: アプリ再起動後に最後の画面パスが復元される', () async {
        // Given: パスを保存
        SharedPreferences.setMockInitialValues({
          'last_route': '/settings',
        });

        final newContainer = ProviderContainer();
        final notifier = newContainer.read(appSessionProvider.notifier);

        // When: 初期化
        await notifier.initialize();

        // Then: パスが復元される
        expect(notifier.lastRoute, equals('/settings'));

        newContainer.dispose();
      });
    });

    // =========================================================================
    // バックグラウンド復帰テスト (EDGE-201)
    // =========================================================================

    group('バックグラウンド復帰', () {
      test('TC-079-006: バックグラウンド移行時に状態が保存される', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // Given: 状態を設定
        await notifier.saveDraftText('バックグラウンド前のテキスト');
        await notifier.saveLastRoute('/home');

        // When: バックグラウンドに移行
        await notifier.onAppPaused();

        // Then: 状態が永続化されている
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('draft_text'), equals('バックグラウンド前のテキスト'));
        expect(prefs.getString('last_route'), equals('/home'));
      });

      test('TC-079-007: フォアグラウンド復帰時に状態が復元される', () async {
        // Given: 永続化された状態
        SharedPreferences.setMockInitialValues({
          'draft_text': '復帰後のテキスト',
          'last_route': '/favorites',
        });

        final newContainer = ProviderContainer();
        final notifier = newContainer.read(appSessionProvider.notifier);

        // When: フォアグラウンドに復帰
        await notifier.onAppResumed();

        // Then: 状態が復元される
        expect(notifier.draftText, equals('復帰後のテキスト'));
        expect(notifier.lastRoute, equals('/favorites'));

        newContainer.dispose();
      });
    });

    // =========================================================================
    // クラッシュリカバリテスト (REQ-5003)
    // =========================================================================

    group('クラッシュリカバリ', () {
      test('TC-079-008: 保存された状態が永続化されている', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // When: 状態を保存
        await notifier.saveDraftText('クラッシュ前のテキスト');
        await notifier.saveLastRoute('/emergency');

        // Then: SharedPreferencesに保存されている
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getString('draft_text'), equals('クラッシュ前のテキスト'));
        expect(prefs.getString('last_route'), equals('/emergency'));
      });

      test('TC-079-009: 状態をクリアできる', () async {
        final notifier = container.read(appSessionProvider.notifier);

        // Given: 状態を保存
        await notifier.saveDraftText('テスト');
        await notifier.saveLastRoute('/test');

        // When: 状態をクリア
        await notifier.clearSession();

        // Then: 状態がクリアされる
        expect(notifier.draftText, isEmpty);
        expect(notifier.lastRoute, isNull);
      });
    });

    // =========================================================================
    // データ整合性テスト (NFR-302)
    // =========================================================================

    group('データ整合性', () {
      test('TC-079-010: 複数の状態を同時に保存・復元できる', () async {
        // Given: 複数の状態を保存
        SharedPreferences.setMockInitialValues({
          'draft_text': '複数テスト',
          'last_route': '/complex',
          'session_timestamp': DateTime.now().millisecondsSinceEpoch.toString(),
        });

        final newContainer = ProviderContainer();
        final notifier = newContainer.read(appSessionProvider.notifier);

        // When: 初期化
        await notifier.initialize();

        // Then: すべての状態が正しく復元される
        expect(notifier.draftText, equals('複数テスト'));
        expect(notifier.lastRoute, equals('/complex'));

        newContainer.dispose();
      });
    });
  });
}
