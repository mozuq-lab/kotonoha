/// チュートリアル完了フラグの保存失敗を利用者へ伝える（ADR-005、台帳 L-104）
///
/// 失敗の注入は shared_preferences の外部 SDK 境界（SharedPreferencesStorePlatform）で行う。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // 壊れた store を次のテストへ持ち越さない
    SharedPreferences.setMockInitialValues({});
  });

  test('完了フラグの書き込みが失敗しても、状態は完了になり、失敗が記録される', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).completeTutorial();

    expect(container.read(tutorialProvider).isCompleted, isTrue);
    expect(container.read(settingsWriteFailureProvider), isNotEmpty);
  });

  test('成功すると失敗は記録されない', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(tutorialProvider.notifier).completeTutorial();

    expect(container.read(settingsWriteFailureProvider), isEmpty);
  });
}
