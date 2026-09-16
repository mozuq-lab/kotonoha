/// 下書き（入力中の文）の保存失敗を利用者へ伝える（NFR-302、ADR-005、台帳 L-104）
///
/// 失敗の注入は shared_preferences の外部 SDK 境界（SharedPreferencesStorePlatform）で行う。
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/settings_write_failure_provider.dart';
import 'package:kotonoha_app/features/app_state/providers/app_session_provider.dart';
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

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  tearDown(() {
    // 壊れた store を次のテストへ持ち越さない
    SharedPreferences.setMockInitialValues({});
  });

  test('書き込みが例外で失敗すると、下書きのキーが失敗として記録される', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSessionProvider.notifier).saveDraftText('あ');

    expect(container.read(settingsWriteFailureProvider),
        contains(draftTextWriteKey));
    expect(container.read(appSessionProvider).draftText, 'あ');
  });

  test('書き込みが false で失敗しても同じく記録される', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _FalseStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await container.read(appSessionProvider.notifier).saveDraftText('あ');

    expect(container.read(settingsWriteFailureProvider),
        contains(draftTextWriteKey));
  });

  test('成功すると失敗の記録が消える', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _FalseStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final notifier = container.read(appSessionProvider.notifier);
    await notifier.saveDraftText('あ');
    expect(container.read(settingsWriteFailureProvider),
        contains(draftTextWriteKey));

    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance =
        InMemorySharedPreferencesStore.empty();
    await notifier.saveDraftText('い');

    expect(container.read(settingsWriteFailureProvider),
        isNot(contains(draftTextWriteKey)));
  });

  test('last_route の保存失敗は未処理エラーにならず、報告もしない', () async {
    SharedPreferences.setMockInitialValues({});
    SharedPreferencesStorePlatform.instance = _ThrowingStore();
    final container = ProviderContainer();
    addTearDown(container.dispose);

    await expectLater(
      container.read(appSessionProvider.notifier).saveLastRoute('/settings'),
      completes,
    );
    expect(container.read(settingsWriteFailureProvider), isEmpty);
  });
}
