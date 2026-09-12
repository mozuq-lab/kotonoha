/// 設定（SharedPreferences）の保存失敗を利用者へ伝える（ADR-005、L-83）
///
/// 失敗の注入は shared_preferences の外部 SDK 境界（SharedPreferencesStorePlatform）で
/// 行う（AGENTS.md 規律 5: モックは外部 SDK とネットワーク境界にだけ）。
/// 自分の関数は patch しない。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_platform_interface.dart';

/// 書き込みだけが失敗する store（ディスクフルや権限エラーの形）
class _WriteFailingStore extends InMemorySharedPreferencesStore {
  _WriteFailingStore() : super.empty();

  @override
  Future<bool> setValue(String valueType, String key, Object value) async {
    throw Exception('setValue failed (injected)');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('設定の保存失敗の報告', () {
    test('保存に失敗すると settingsWriteFailureProvider が失敗を持つ', () async {
      // Given: getInstance は通るが setValue だけ失敗する store
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _WriteFailingStore();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      expect(container.read(settingsWriteFailureProvider), isFalse);

      // When: フォントサイズを保存する
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);

      // Then: 失敗が報告され、UI 状態は新しい値のまま（NFR-301: 使い続けられる）
      expect(container.read(settingsWriteFailureProvider), isTrue);
      expect(
        container.read(settingsNotifierProvider).asData?.value.fontSize,
        FontSize.large,
      );
    });

    test('保存に成功すると失敗の報告は消える', () async {
      SharedPreferences.setMockInitialValues({});
      SharedPreferencesStorePlatform.instance = _WriteFailingStore();
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(settingsNotifierProvider.future);
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.large);
      expect(container.read(settingsWriteFailureProvider), isTrue);

      // When: 保存できる store に戻して、もう一度保存する
      SharedPreferences.setMockInitialValues({});
      await container
          .read(settingsNotifierProvider.notifier)
          .setFontSize(FontSize.medium);

      // Then: 失敗の報告が消える
      expect(container.read(settingsWriteFailureProvider), isFalse);
    });
  });
}
