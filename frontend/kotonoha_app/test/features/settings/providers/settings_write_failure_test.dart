/// 設定（SharedPreferences）の保存失敗を利用者へ伝える（ADR-005、L-83）
///
/// 失敗の注入は shared_preferences の外部 SDK 境界（SharedPreferencesStorePlatform）で
/// 行う（AGENTS.md 規律 5: モックは外部 SDK とネットワーク境界にだけ）。
/// 自分の関数は patch しない。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 書き込みだけが例外で失敗する store（iOS / Web のチャネル例外の形）
class _ThrowingStore extends InMemorySharedPreferencesStore {
  _ThrowingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw Exception('setValue failed (injected)');
  }
}

/// 書き込みが false で失敗する store（Android の commit() が false を返す形）
class _FalseStore extends InMemorySharedPreferencesStore {
  _FalseStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async =>
      false;
}

/// 読み出しから失敗する store（getInstance が投げ、_prefs が null のまま動く形）
class _UnreadableStore extends InMemorySharedPreferencesStore {
  _UnreadableStore() : super.empty();

  @override
  Future<Map<String, Object>> getAll() async {
    throw Exception('getAll failed (injected)');
  }
}

Future<ProviderContainer> _containerWith(
    SharedPreferencesStorePlatform store) async {
  SharedPreferences.setMockInitialValues({});
  SharedPreferencesStorePlatform.instance = store;
  final container = ProviderContainer();
  addTearDown(container.dispose);
  await container.read(settingsNotifierProvider.future);
  return container;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // 壊れた store を次のテストへ持ち越さない
    SharedPreferences.setMockInitialValues({});
  });

  /// 6 つの設定すべてが同じ報告経路を通る
  final setters = <String, Future<void> Function(SettingsNotifier)>{
    'fontSize': (n) => n.setFontSize(FontSize.large),
    'theme': (n) => n.setTheme(AppTheme.dark),
    'tts_speed': (n) => n.setTTSSpeed(TTSSpeed.slow),
    'ai_politeness': (n) => n.setAIPoliteness(PolitenessLevel.polite),
    'ai_privacy_consent': (n) => n.setAIPrivacyConsent(true),
    'simple_mode': (n) => n.setSimpleMode(true),
  };

  group('設定の保存失敗の報告（例外）', () {
    for (final entry in setters.entries) {
      test('${entry.key} の保存が例外で失敗すると、そのキーが失敗として報告される', () async {
        final container = await _containerWith(_ThrowingStore());
        expect(container.read(settingsWriteFailureProvider), isEmpty);
        await entry.value(container.read(settingsNotifierProvider.notifier));
        expect(
            container.read(settingsWriteFailureProvider), contains(entry.key));
      });
    }

    test('失敗しても UI 状態は新しい値のまま（NFR-301: 使い続けられる）', () async {
      final container = await _containerWith(_ThrowingStore());
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      expect(
        container.read(settingsNotifierProvider).asData?.value.fontSize,
        FontSize.large,
      );
    });
  });

  group('設定の保存失敗の報告（例外にならない失敗）', () {
    test('Android の commit() のように false が返っても失敗として報告される', () async {
      final container = await _containerWith(_FalseStore());
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      expect(
          container.read(settingsWriteFailureProvider), contains('fontSize'));
    });

    test('SharedPreferences 自体が使えず _prefs が無いときも、保存は失敗として報告される', () async {
      final container = await _containerWith(_UnreadableStore());
      // build は既定値で立ち上がる（NFR-301）
      expect(container.read(settingsNotifierProvider).hasValue, isTrue);
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      expect(container.read(settingsWriteFailureProvider), contains('fontSize'),
          reason: '1 つも保存できない最悪ケースが黙らないこと');
    });
  });

  group('失敗の解消', () {
    test('同じキーの保存が成功すると、そのキーの失敗は消える', () async {
      final container = await _containerWith(_ThrowingStore());
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setFontSize(FontSize.large);
      expect(
          container.read(settingsWriteFailureProvider), contains('fontSize'));

      SharedPreferences.setMockInitialValues({});
      await notifier.setFontSize(FontSize.medium);
      expect(container.read(settingsWriteFailureProvider), isEmpty);
    });

    test('別のキーの保存が成功しても、失敗したままのキーは消えない', () async {
      final container = await _containerWith(_ThrowingStore());
      final notifier = container.read(settingsNotifierProvider.notifier);
      await notifier.setFontSize(FontSize.large);

      SharedPreferences.setMockInitialValues({});
      await notifier.setTheme(AppTheme.dark);
      expect(container.read(settingsWriteFailureProvider), contains('fontSize'),
          reason: '未保存のフォントサイズが残っているのにバナーが消えないこと');
    });
  });
}
