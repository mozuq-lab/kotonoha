/// 緊急機能の全画面配線テスト（AppShell / ShellRoute経由）
///
/// F3: 緊急機能（緊急ボタン常時表示・緊急アラート表示）が
/// AppShellを経由して全画面に配線されていることを検証する。
///
/// 関連要件:
/// - REQ-301: 緊急ボタンの全画面常時表示
/// - REQ-302: 2段階確認（ボタンタップ→確認ダイアログ→確認タップ）
/// - REQ-304: 緊急アラート画面のフルスクリーン表示
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

import '../../mocks/mock_emergency_audio_service.dart';

void main() {
  setUpAll(() {
    // EmergencyStateNotifier.startEmergency/resetEmergency が呼び出す
    // モックメソッドのデフォルト挙動を登録。
    registerFallbackValue(Object());
  });

  group('緊急機能の全画面配線テスト（ShellRoute経由）', () {
    late MockEmergencyAudioService mockAudioService;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      mockAudioService = MockEmergencyAudioService();
      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          // 音声プラグイン依存を避けるためモックへ差し替え
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
          // SettingsScreen等のローディング無限アニメーションを回避
          settingsNotifierProvider.overrideWith(() => _MockSettingsNotifier()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          routerConfig: router,
        ),
      );
    }

    testWidgets('REQ-301: ホーム画面で緊急ボタンが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      expect(
        find.byType(EmergencyButtonWithConfirmation),
        findsOneWidget,
        reason: 'ホーム画面で緊急ボタンが常時表示される必要がある',
      );
      expect(
        find.bySemanticsLabel('緊急呼び出しボタン'),
        findsOneWidget,
        reason: '緊急呼び出しボタンのSemanticsが存在する必要がある',
      );
    });

    testWidgets('REQ-301: 別画面（/settings）でも緊急ボタンが表示される',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      router.go('/settings');
      await tester.pumpAndSettle();

      expect(
        find.byType(EmergencyButtonWithConfirmation),
        findsOneWidget,
        reason: '設定画面でも緊急ボタンが常時表示される必要がある（全画面常時表示）',
      );
    });

    testWidgets('REQ-302/304: 緊急ボタン→確認→緊急アラート画面が表示され、リセットで戻る',
        (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 初期状態では緊急アラート画面は表示されない
      expect(find.byType(EmergencyAlertScreen), findsNothing);

      // 緊急ボタンをタップ → 確認ダイアログ表示（REQ-302 1段階目）
      await tester.tap(find.byType(EmergencyButtonWithConfirmation));
      await tester.pumpAndSettle();

      // 確認ダイアログ（EmergencyConfirmationDialog）内の「はい」ボタンに限定。
      // ホーム画面にも定型文等で「はい」テキストが存在しうるため、
      // AlertDialog配下のElevatedButtonに絞り込む。
      final confirmButton = find.descendant(
        of: find.byType(AlertDialog),
        matching: find.widgetWithText(ElevatedButton, 'はい'),
      );
      expect(
        confirmButton,
        findsOneWidget,
        reason: '緊急ボタンタップで確認ダイアログ（はいボタン）が表示される必要がある',
      );

      // 「はい」をタップ → 緊急処理開始（REQ-302 2段階目）
      await tester.tap(confirmButton);
      await tester.pumpAndSettle();

      // 緊急アラート画面が最前面に表示される（REQ-304）
      expect(
        find.byType(EmergencyAlertScreen),
        findsOneWidget,
        reason: '確認後に緊急アラート画面がフルスクリーンで表示される必要がある',
      );
      expect(
        find.text('緊急呼び出し中'),
        findsOneWidget,
        reason: '緊急アラート画面の「緊急呼び出し中」メッセージが表示される必要がある',
      );
      verify(() => mockAudioService.startEmergencySound()).called(1);

      // リセットボタンで通常画面に戻る
      await tester.tap(find.text('リセット'));
      await tester.pumpAndSettle();

      expect(
        find.byType(EmergencyAlertScreen),
        findsNothing,
        reason: 'リセット後は緊急アラート画面が消える必要がある',
      );
      verify(() => mockAudioService.stopEmergencySound()).called(1);
    });
  });
}

/// テスト用のモックSettingsNotifier
///
/// ローディング状態を回避するため、build()で即座にデフォルト設定を返す。
class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return const AppSettings();
  }
}
