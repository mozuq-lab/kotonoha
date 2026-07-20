/// AppShell 初回チュートリアル・オフラインバナー配線テスト（fix/improvement-p0-p2）
///
/// 実装済みだが画面に配線されていなかった以下の機能を、全画面共通の
/// AppShellへ配線したことを確認する。
///
/// - TASK-0075 / REQ-3001: 初回起動時のチュートリアル(TutorialOverlay)表示
/// - REQ-1002: オフライン状態の常時バナー表示
/// - EDGE-001: オンライン復帰時の一時的な通知表示
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/emergency/domain/models/emergency_state.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

import '../../mocks/mock_emergency_audio_service.dart';

void main() {
  group('AppShell 初回チュートリアル配線テスト (TASK-0075 / REQ-3001)', () {
    testWidgets('チュートリアル未完了（初回起動）の場合、TutorialOverlayが表示される', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TutorialOverlay), findsOneWidget);
      expect(find.textContaining('ようこそ'), findsOneWidget);
    });

    testWidgets('チュートリアル完了済みの場合、TutorialOverlayは表示されない', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TutorialOverlay), findsNothing);
      expect(find.text('test child'), findsOneWidget);
    });

    testWidgets('チュートリアルを完了するとTutorialOverlayが消え、以降表示されない', (tester) async {
      SharedPreferences.setMockInitialValues({});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TutorialOverlay), findsOneWidget);

      // 最後のステップまで進めて完了する
      while (find.text('次へ').evaluate().isNotEmpty) {
        await tester.tap(find.text('次へ'));
        await tester.pumpAndSettle();
      }
      await tester.tap(find.text('はじめる'));
      await tester.pumpAndSettle();

      expect(find.byType(TutorialOverlay), findsNothing);
      expect(
        container.read(tutorialProvider).isCompleted,
        isTrue,
        reason: 'チュートリアル完了操作でisCompletedがtrueになる必要がある',
      );
    });
  });

  group('AppShell オフラインバナー配線テスト (REQ-1002)', () {
    testWidgets('オフライン状態になると、AppShell配下に常時バナーが表示される', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(OfflineBanner), findsOneWidget);
      expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);

      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpAndSettle();

      expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);
      // 現在のルート画面は引き続き表示される
      expect(find.text('test child'), findsOneWidget);
    });

    testWidgets('オンラインに復帰すると常時バナーは消える', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpAndSettle();
      expect(find.text('オフライン - 基本機能のみ利用可能'), findsOneWidget);

      await container.read(networkProvider.notifier).setOnline();
      await tester.pumpAndSettle();

      expect(find.text('オフライン - 基本機能のみ利用可能'), findsNothing);
    });

    testWidgets('オンライン復帰時、一時的な復帰通知（EDGE-001）が表示される', (tester) async {
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await container.read(networkProvider.notifier).setOffline();
      await tester.pumpAndSettle();

      await container.read(networkProvider.notifier).setOnline();
      await tester.pump();

      expect(find.text('オンラインに戻りました。AI変換が利用可能です'), findsOneWidget);
    });
  });

  group('AppShell 緊急ボタンとチュートリアルの共存（安全要件）', () {
    // 【回帰テスト】: TutorialOverlayは半透明の不透明なContainerを最前面に
    // 描画するため、Stack内でAppShellの`content`全体（緊急ボタンを含む）を
    // ラップすると、初回起動時のチュートリアル表示中は緊急ボタンがその下に
    // 隠れてタップ不能になってしまう。緊急機能はいかなる状況でも
    // ブロックしてはならない（REQ-301, REQ-302）ため、緊急ボタン・
    // 緊急アラート画面は常にチュートリアルより手前に表示される必要がある。
    testWidgets('チュートリアル表示中でも緊急ボタンをタップして確認ダイアログを開き、緊急状態にできる', (tester) async {
      SharedPreferences.setMockInitialValues({});

      // 緊急音再生サービスをモック化する（実際のaudioplayersプラグインは
      // widgetテスト環境では応答せずFutureが永久に解決しない場合があるため）。
      final mockAudioService = MockEmergencyAudioService();
      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});

      final container = ProviderContainer(
        overrides: [
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: AppShell(
              child: Scaffold(body: Text('test child')),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 前提: チュートリアルが表示されている
      expect(find.byType(TutorialOverlay), findsOneWidget);

      // 緊急ボタンがチュートリアルに隠されずタップできることを確認
      expect(find.bySemanticsLabel('緊急呼び出しボタン'), findsOneWidget);
      await tester.tap(find.bySemanticsLabel('緊急呼び出しボタン'));
      await tester.pumpAndSettle();

      // 確認ダイアログが開き、「はい」で緊急状態へ遷移できることを確認
      expect(find.text('はい'), findsOneWidget);
      await tester.tap(find.text('はい'));
      await tester.pumpAndSettle();

      expect(
        container.read(emergencyStateProvider),
        EmergencyStateEnum.alertActive,
        reason: 'チュートリアル表示中でも緊急ボタン操作がブロックされてはならない',
      );
    });
  });
}
