/// シンプルモード設定 永続化テスト
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// テスト対象: lib/features/settings/providers/settings_provider.dart
///   `SettingsNotifier.setSimpleMode` / build()でのsimpleMode復元
///
/// 検証内容:
/// 1. デフォルト値はfalse（通常モード）
/// 2. setSimpleMode(true)で即座にstateへ反映される（楽観的更新）
/// 3. SharedPreferencesへbool値として永続化される
/// 4. アプリ再起動（新規ProviderContainer）後も復元される
/// 5. 他の設定値（fontSize等）に影響を与えない
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

void main() {
  group('SettingsNotifier - シンプルモード', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    tearDown(() {
      container.dispose();
    });

    test('初期状態ではsimpleModeはfalseである', () async {
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      expect(settings.simpleMode, isFalse);
    });

    test('setSimpleMode(true)で即座にstateがtrueへ更新される', () async {
      container = ProviderContainer();
      await container.read(settingsNotifierProvider.future);
      final notifier = container.read(settingsNotifierProvider.notifier);

      await notifier.setSimpleMode(true);

      final state = container.read(settingsNotifierProvider);
      expect(state.requireValue.simpleMode, isTrue);
    });

    test('setSimpleMode(true)はSharedPreferencesにbool値として保存される', () async {
      container = ProviderContainer();
      await container.read(settingsNotifierProvider.future);
      final notifier = container.read(settingsNotifierProvider.notifier);

      await notifier.setSimpleMode(true);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('simple_mode'), isTrue);
    });

    test('アプリ再起動後（新規ProviderContainer）もsimpleModeが復元される', () async {
      SharedPreferences.setMockInitialValues({'simple_mode': true});

      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      expect(settings.simpleMode, isTrue);
    });

    test('setSimpleMode(false)でOFFに戻せる', () async {
      SharedPreferences.setMockInitialValues({'simple_mode': true});
      container = ProviderContainer();
      await container.read(settingsNotifierProvider.future);
      final notifier = container.read(settingsNotifierProvider.notifier);

      await notifier.setSimpleMode(false);

      final state = container.read(settingsNotifierProvider);
      expect(state.requireValue.simpleMode, isFalse);

      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getBool('simple_mode'), isFalse);
    });

    test('setSimpleModeは他の設定値（fontSize）に影響を与えない', () async {
      container = ProviderContainer();
      await container.read(settingsNotifierProvider.future);
      final notifier = container.read(settingsNotifierProvider.notifier);

      await notifier.setFontSize(FontSize.large);
      await notifier.setSimpleMode(true);

      final state = container.read(settingsNotifierProvider);
      expect(state.requireValue.simpleMode, isTrue);
      expect(state.requireValue.fontSize, FontSize.large);
    });

    test('未保存(null)の場合はデフォルト値falseが使用される', () async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      final settings = await container.read(settingsNotifierProvider.future);

      expect(settings.simpleMode, isFalse);
    });
  });
}
