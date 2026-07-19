/// AppLifecycleObserver 入力ドラフト保存・復元 統合テスト
///
/// TASK-0079: アプリ状態復元・クラッシュリカバリ実装
/// 対象: AppLifecycleObserverによる入力バッファ(inputBufferProvider)と
/// セッション状態(appSessionProvider)の配線
///
/// 関連要件:
/// - EDGE-201: バックグラウンド復帰時の状態復元
/// - REQ-5003: クラッシュ時のデータ保持（入力中ドラフトの保存・復元）
///
/// 【テスト方針】: ProviderContainerを直接操作しつつ、実際に配線される
/// AppLifecycleObserverウィジェットをUncontrolledProviderScope経由でマウントし、
/// 実装コードそのものを通して検証する。flutter_testのFakeAsyncゾーンにより、
/// デバウンス用Timerは実時間を待たずtester.pump(duration)で進められる。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/app_state/providers/app_lifecycle_observer.dart';
import 'package:kotonoha_app/features/app_state/providers/app_session_provider.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';

void main() {
  group('AppLifecycleObserver: 入力ドラフト保存・復元の配線', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    Future<ProviderContainer> pumpObserver(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppLifecycleObserver(child: SizedBox.shrink()),
          ),
        ),
      );
      // initStateのaddPostFrameCallback（initialize→復元→監視開始）を進める
      await tester.pumpAndSettle();
      return container;
    }

    testWidgets('TC-INT-001: 入力バッファの変更がデバウンス後にドラフトとして保存される', (tester) async {
      final container = await pumpObserver(tester);

      // When: 1文字入力する
      container.read(inputBufferProvider.notifier).addCharacter('あ');

      // デバウンス（400ms）経過前はまだ保存されていない
      await tester.pump(const Duration(milliseconds: 100));
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('draft_text'), isNull, reason: 'デバウンス中はまだ保存されない');

      // デバウンス経過後は保存される
      await tester.pump(const Duration(milliseconds: 400));
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('draft_text'), equals('あ'));
    });

    testWidgets('TC-INT-002: バックグラウンド移行時はデバウンスを待たず即時保存される', (tester) async {
      final container = await pumpObserver(tester);

      // When: 文字入力直後（デバウンス未経過）にバックグラウンドへ移行
      container.read(inputBufferProvider.notifier).setText('入力途中のテキスト');
      await tester.pump(const Duration(milliseconds: 50));

      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();

      // Then: デバウンス（400ms）を待たずに保存されている
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('draft_text'), equals('入力途中のテキスト'));
    });

    testWidgets('TC-INT-003: アプリ起動時に保存済みドラフトが入力バッファへ復元される', (tester) async {
      SharedPreferences.setMockInitialValues({
        'draft_text': '前回入力していたテキスト',
      });

      final container = await pumpObserver(tester);

      expect(
        container.read(inputBufferProvider),
        equals('前回入力していたテキスト'),
      );
    });

    testWidgets('TC-INT-004: フォアグラウンド復帰時にもドラフトが入力バッファへ復元される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = await pumpObserver(tester);

      // Given: バックグラウンド中に別プロセス等でドラフトが保存された状態を再現
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('draft_text', '復帰時に復元されるテキスト');

      // When: フォアグラウンドに復帰
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pumpAndSettle();

      // Then: 入力バッファに復元されている
      expect(
        container.read(inputBufferProvider),
        equals('復帰時に復元されるテキスト'),
      );
    });

    testWidgets('TC-INT-005: 入力バッファを全消去するとドラフトも即時に消去される', (tester) async {
      final container = await pumpObserver(tester);

      // Given: デバウンスを経て保存済みのテキストがある状態
      container.read(inputBufferProvider.notifier).setText('消去されるテキスト');
      await tester.pump(const Duration(milliseconds: 400));
      var prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('draft_text'), equals('消去されるテキスト'));

      // When: 全消去する
      container.read(inputBufferProvider.notifier).clear();

      // Then: デバウンスを待たず即時にドラフトも消去される
      await tester.pump(const Duration(milliseconds: 10));
      prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('draft_text'), isNull);
      expect(
        container.read(appSessionProvider).draftText,
        isEmpty,
      );
    });
  });
}
