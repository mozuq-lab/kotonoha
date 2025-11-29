/// Phase 4 統合テスト
///
/// TASK-0080: Phase 4 統合テスト
///
/// 関連要件: Phase 4の全要件
/// - 履歴管理、お気に入り、AI変換UI、設定、オフライン対応
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

// Network
import 'package:kotonoha_app/features/network/domain/models/network_state.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';

// Settings
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

// App State
import 'package:kotonoha_app/features/app_state/providers/app_session_provider.dart';

void main() {
  group('Phase 4 統合テスト', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    // =========================================================================
    // 1. 設定変更即時反映テスト
    // =========================================================================

    group('1. 設定変更即時反映テスト', () {
      test('TC-080-001: テーマ設定変更が即時反映される', () async {
        // Given: 設定の初期化を待機
        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: ダークテーマに変更
        await notifier.setTheme(AppTheme.dark);

        // Then: 即時に反映される
        final settings = container.read(settingsNotifierProvider).valueOrNull;
        expect(settings?.theme, AppTheme.dark);
      });

      test('TC-080-002: フォントサイズ変更が即時反映される', () async {
        // Given: 設定の初期化を待機
        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: フォントサイズを変更
        await notifier.setFontSize(FontSize.large);

        // Then: 即時に反映される
        final settings = container.read(settingsNotifierProvider).valueOrNull;
        expect(settings?.fontSize, FontSize.large);
      });

      test('TC-080-003: TTS速度変更が即時反映される', () async {
        // Given: 設定の初期化を待機
        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: TTS速度を変更
        await notifier.setTTSSpeed(TTSSpeed.fast);

        // Then: 即時に反映される
        final settings = container.read(settingsNotifierProvider).valueOrNull;
        expect(settings?.ttsSpeed, TTSSpeed.fast);
      });
    });

    // =========================================================================
    // 2. オフライン時フォールバック動作テスト
    // =========================================================================

    group('2. オフライン時フォールバック動作テスト', () {
      testWidgets('TC-080-004: オフライン時にバナーが表示される', (tester) async {
        // Given: オフライン状態
        await container.read(networkProvider.notifier).setOffline();

        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: const MaterialApp(
              home: Scaffold(
                body: Column(
                  children: [
                    OfflineBanner(),
                    Expanded(child: Center(child: Text('Content'))),
                  ],
                ),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();

        // Then: オフラインバナーが表示される
        expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);
      });

      test('TC-080-005: オフライン時にAI変換が無効', () async {
        // When: オフライン状態に設定
        await container.read(networkProvider.notifier).setOffline();

        // Then: AI変換が利用不可
        expect(
          container.read(networkProvider.notifier).isAIConversionAvailable,
          isFalse,
        );
      });

      test('TC-080-006: オンライン復帰時にAI変換が有効化', () async {
        // Given: オフライン状態
        await container.read(networkProvider.notifier).setOffline();

        // When: オンライン復帰
        await container.read(networkProvider.notifier).setOnline();

        // Then: AI変換が利用可能
        expect(
          container.read(networkProvider.notifier).isAIConversionAvailable,
          isTrue,
        );
      });
    });

    // =========================================================================
    // 3. アプリ状態復元テスト
    // =========================================================================

    group('3. アプリ状態復元テスト', () {
      test('TC-080-007: 入力中テキストが保存・復元される', () async {
        // Given: セッション状態を保存
        await container
            .read(appSessionProvider.notifier)
            .saveDraftText('テスト入力');

        // When: 新しいコンテナで復元
        SharedPreferences.setMockInitialValues({
          'draft_text': 'テスト入力',
        });
        final newContainer = ProviderContainer();
        await newContainer.read(appSessionProvider.notifier).initialize();

        // Then: テキストが復元される
        expect(newContainer.read(appSessionProvider).draftText, 'テスト入力');

        newContainer.dispose();
      });

      test('TC-080-008: 最後のルートが保存・復元される', () async {
        // Given: セッション状態を保存
        await container
            .read(appSessionProvider.notifier)
            .saveLastRoute('/settings');

        // When: 新しいコンテナで復元
        SharedPreferences.setMockInitialValues({
          'last_route': '/settings',
        });
        final newContainer = ProviderContainer();
        await newContainer.read(appSessionProvider.notifier).initialize();

        // Then: ルートが復元される
        expect(newContainer.read(appSessionProvider).lastRoute, '/settings');

        newContainer.dispose();
      });
    });

    // =========================================================================
    // 4. ネットワーク状態管理テスト
    // =========================================================================

    group('4. ネットワーク状態管理テスト', () {
      test('TC-080-009: 初期状態はchecking', () {
        // Given: 新しいコンテナ
        final newContainer = ProviderContainer();

        // Then: 初期状態はchecking
        expect(newContainer.read(networkProvider), NetworkState.checking);

        newContainer.dispose();
      });

      test('TC-080-010: ネットワーク状態変更が正しく通知される', () async {
        final states = <NetworkState>[];
        final notifier = container.read(networkProvider.notifier);

        container.listen<NetworkState>(
          networkProvider,
          (previous, next) => states.add(next),
        );

        // When: 状態変更
        await notifier.setOnline();
        await notifier.setOffline();
        await notifier.setOnline();

        // Then: 変更が通知される
        expect(states, contains(NetworkState.online));
        expect(states, contains(NetworkState.offline));
      });
    });

    // =========================================================================
    // 5. 設定永続化テスト
    // =========================================================================

    group('5. 設定永続化テスト', () {
      test('TC-080-011: 設定が永続化される', () async {
        // Given: 設定の初期化を待機
        await container.read(settingsNotifierProvider.future);
        final notifier = container.read(settingsNotifierProvider.notifier);

        // When: 設定を変更
        await notifier.setTheme(AppTheme.dark);
        await notifier.setFontSize(FontSize.large);
        await notifier.setTTSSpeed(TTSSpeed.slow);

        // Then: SharedPreferencesに保存されている
        final prefs = await SharedPreferences.getInstance();
        expect(prefs.getInt('theme'), AppTheme.dark.index);
        expect(prefs.getInt('fontSize'), FontSize.large.index);
        expect(prefs.getString('tts_speed'), TTSSpeed.slow.name);
      });

      test('TC-080-012: アプリ再起動後も設定が維持される', () async {
        // Given: 設定を保存
        SharedPreferences.setMockInitialValues({
          'theme': AppTheme.dark.index,
          'fontSize': FontSize.large.index,
          'tts_speed': TTSSpeed.slow.name,
        });

        // When: 新しいコンテナで初期化
        final newContainer = ProviderContainer();
        final settings =
            await newContainer.read(settingsNotifierProvider.future);

        // Then: 設定が復元される
        expect(settings.theme, AppTheme.dark);
        expect(settings.fontSize, FontSize.large);
        expect(settings.ttsSpeed, TTSSpeed.slow);

        newContainer.dispose();
      });
    });
  });
}
