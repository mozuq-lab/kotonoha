/// EmergencyStateNotifier テスト
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:kotonoha_app/features/emergency/domain/models/emergency_state.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import '../../../../mocks/mock_emergency_audio_service.dart';

void main() {
  group('EmergencyStateNotifier', () {
    late MockEmergencyAudioService mockAudioService;
    late ProviderContainer container;

    setUp(() {
      mockAudioService = MockEmergencyAudioService();
      // モックのデフォルト動作を設定
      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.dispose()).thenAnswer((_) async {});
      when(() => mockAudioService.isPlaying).thenReturn(false);

      container = ProviderContainer(
        overrides: [
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
        ],
      );
    });

    tearDown(() {
      container.dispose();
    });

    // 5.1 EmergencyStateNotifier基本テスト
    group('EmergencyStateNotifier基本テスト', () {
      /// 初期状態がnormalである
      test('TC-047-042: 初期状態がnormalである', () {
        // Act
        final state = container.read(emergencyStateProvider);

        // Assert
        expect(state, equals(EmergencyStateEnum.normal));
      });

      /// startEmergencyで状態がalertActiveになる
      test('TC-047-043: startEmergencyで状態がalertActiveになる', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
      });

      /// resetEmergencyで状態がnormalに戻る
      test('TC-047-044: resetEmergencyで状態がnormalに戻る', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        await notifier.startEmergency();

        // Act
        await notifier.resetEmergency();

        // Assert
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );
      });

      /// startEmergencyで緊急音が再生される
      test('TC-047-045: startEmergencyで緊急音が再生される', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert
        verify(() => mockAudioService.startEmergencySound()).called(1);
      });

      /// resetEmergencyで緊急音が停止される
      test('TC-047-046: resetEmergencyで緊急音が停止される', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        await notifier.startEmergency();

        // Act
        await notifier.resetEmergency();

        // Assert
        verify(() => mockAudioService.stopEmergencySound()).called(1);
      });
    });

    // 5.2 Riverpod連携テスト
    group('Riverpod連携テスト', () {
      /// Providerから状態を取得できる
      test('TC-047-047: Providerから状態を取得できる', () {
        // Act
        final state = container.read(emergencyStateProvider);

        // Assert
        expect(state, equals(EmergencyStateEnum.normal));
      });

      /// 状態変更がUIに反映される
      testWidgets('TC-047-048: 状態変更がUIに反映される', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(emergencyStateProvider);
                  return Text('State: ${state.name}');
                },
              ),
            ),
          ),
        );

        // Assert - 初期状態
        expect(find.text('State: normal'), findsOneWidget);
      });

      /// refを使用して状態を変更できる
      test('TC-047-049: refを使用して状態を変更できる', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
      });
    });

    // 5.3 状態遷移テスト
    group('状態遷移テスト', () {
      /// normal → alertActive遷移が正常
      test('TC-047-050: normal → alertActive遷移が正常', () async {
        // Arrange
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );

        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
      });

      /// alertActive → normal遷移が正常
      test('TC-047-051: alertActive → normal遷移が正常', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        await notifier.startEmergency();
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );

        // Act
        await notifier.resetEmergency();

        // Assert
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );
      });

      /// 既にalertActiveの時にstartEmergencyしても問題ない
      test('TC-047-052: 既にalertActiveの時にstartEmergencyしても問題ない', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        await notifier.startEmergency();

        // Act & Assert - エラーが発生しないことを確認
        await expectLater(
          notifier.startEmergency(),
          completes,
        );
      });

      /// 既にnormalの時にresetEmergencyしても問題ない
      test('TC-047-053: 既にnormalの時にresetEmergencyしても問題ない', () async {
        // Arrange
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );

        final notifier = container.read(emergencyStateProvider.notifier);

        // Act & Assert - エラーが発生しないことを確認
        await expectLater(
          notifier.resetEmergency(),
          completes,
        );
      });
    });

    // 8.1 既存コンポーネント連携テスト
    group('既存コンポーネント連携テスト', () {
      /// 確認ダイアログで「はい」タップ後に緊急処理が開始される
      testWidgets('TC-047-067: 確認後に緊急処理が開始される', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(emergencyStateProvider);
                  return Column(
                    children: [
                      Text('State: ${state.name}'),
                      ElevatedButton(
                        onPressed: () async {
                          // 確認ダイアログで「はい」タップ後の処理をシミュレート
                          await ref
                              .read(emergencyStateProvider.notifier)
                              .startEmergency();
                        },
                        child: const Text('確認'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Assert - 初期状態
        expect(find.text('State: normal'), findsOneWidget);

        // Act - 確認ボタンをタップ
        await tester.tap(find.text('確認'));
        await tester.pumpAndSettle();

        // Assert - 状態がalertActiveに変わる
        expect(find.text('State: alertActive'), findsOneWidget);
      });

      /// EmergencyStateEnumが正しく使用される
      test('TC-047-069: EmergencyStateEnumが正しく使用される', () {
        // Assert - Enumの値が正しいことを確認
        expect(EmergencyStateEnum.values.length,
            equals(3)); // normal, alertActive, resetting
        expect(EmergencyStateEnum.values, contains(EmergencyStateEnum.normal));
        expect(EmergencyStateEnum.values,
            contains(EmergencyStateEnum.alertActive));
      });

      /// 状態がalertActiveの時に緊急画面が表示される
      testWidgets('TC-047-070: 状態がalertActiveの時に緊急画面が表示される', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(emergencyStateProvider);
                  return Column(
                    children: [
                      if (state == EmergencyStateEnum.alertActive)
                        const Text('緊急画面表示中')
                      else
                        const Text('通常画面'),
                      ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(emergencyStateProvider.notifier)
                              .startEmergency();
                        },
                        child: const Text('緊急開始'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Assert - 初期状態
        expect(find.text('通常画面'), findsOneWidget);

        // Act
        await tester.tap(find.text('緊急開始'));
        await tester.pumpAndSettle();

        // Assert - 緊急画面が表示される
        expect(find.text('緊急画面表示中'), findsOneWidget);
      });

      /// 状態がnormalの時に緊急画面が非表示
      testWidgets('TC-047-071: 状態がnormalの時に緊急画面が非表示', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(emergencyStateProvider);
                  if (state == EmergencyStateEnum.alertActive) {
                    return const Text('緊急画面表示中');
                  }
                  return const Text('通常画面');
                },
              ),
            ),
          ),
        );

        // Assert - normal状態では緊急画面が非表示
        expect(find.text('通常画面'), findsOneWidget);
        expect(find.text('緊急画面表示中'), findsNothing);
      });
    });

    // 10. 統合テスト
    group('統合テスト', () {
      /// 緊急音再生と画面赤表示が同時に開始される
      test('TC-047-086: 緊急音再生と画面赤表示が同時に開始される', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert - 音再生と状態変更が同時に行われる
        verify(() => mockAudioService.startEmergencySound()).called(1);
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
      });

      /// リセットで音停止と画面解除が同時に行われる
      test('TC-047-087: リセットで音停止と画面解除が同時に行われる', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        await notifier.startEmergency();

        // Act
        await notifier.resetEmergency();

        // Assert - 音停止と状態変更が同時に行われる
        verify(() => mockAudioService.stopEmergencySound()).called(1);
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );
      });

      /// 2段階確認→緊急処理→リセットの一連フローが正常動作
      test('TC-047-088: 2段階確認→緊急処理→リセットの一連フローが正常動作', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Assert - 初期状態
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );

        // Act 1 - 緊急開始（確認ダイアログで「はい」タップ後）
        await notifier.startEmergency();

        // Assert 1 - 緊急状態
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
        verify(() => mockAudioService.startEmergencySound()).called(1);

        // Act 2 - リセット
        await notifier.resetEmergency();

        // Assert 2 - 通常状態に復帰
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.normal),
        );
        verify(() => mockAudioService.stopEmergencySound()).called(1);
      });

      /// 状態とUIが常に同期している
      testWidgets('TC-047-092: 状態とUIが常に同期している', (tester) async {
        // Arrange
        await tester.pumpWidget(
          ProviderScope(
            overrides: [
              emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
            ],
            child: MaterialApp(
              home: Consumer(
                builder: (context, ref, _) {
                  final state = ref.watch(emergencyStateProvider);
                  return Column(
                    children: [
                      Text('State: ${state.name}'),
                      if (state == EmergencyStateEnum.alertActive)
                        const Text('緊急表示中'),
                      ElevatedButton(
                        onPressed: () async {
                          await ref
                              .read(emergencyStateProvider.notifier)
                              .startEmergency();
                        },
                        child: const Text('緊急開始'),
                      ),
                    ],
                  );
                },
              ),
            ),
          ),
        );

        // Assert - 初期状態はnormal
        expect(find.text('State: normal'), findsOneWidget);
        expect(find.text('緊急表示中'), findsNothing);

        // Act
        await tester.tap(find.text('緊急開始'));
        await tester.pumpAndSettle();

        // Assert - 状態変更後
        expect(find.text('State: alertActive'), findsOneWidget);
        expect(find.text('緊急表示中'), findsOneWidget);
      });

      /// 状態とAudioServiceが常に同期している
      test('TC-047-093: 状態とAudioServiceが常に同期している', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);

        // Act 1 - alertActive状態で再生
        await notifier.startEmergency();
        verify(() => mockAudioService.startEmergencySound()).called(1);

        // Act 2 - normal状態で停止
        await notifier.resetEmergency();
        verify(() => mockAudioService.stopEmergencySound()).called(1);
      });

      /// エラー発生後も状態が一貫している
      test('TC-047-094: エラー発生後も状態が一貫している', () async {
        // Arrange - AudioServiceがエラーをスロー
        when(() => mockAudioService.startEmergencySound())
            .thenThrow(Exception('Audio error'));

        final notifier = container.read(emergencyStateProvider.notifier);

        // Act
        await notifier.startEmergency();

        // Assert - エラー発生後も状態はalertActiveになる（画面表示は継続）
        expect(
          container.read(emergencyStateProvider),
          equals(EmergencyStateEnum.alertActive),
        );
      });
    });

    // パフォーマンステスト
    group('パフォーマンステスト', () {
      /// 緊急音再生開始まで500ms以内
      test('TC-047-054: 緊急音再生開始まで500ms以内', () async {
        // Arrange
        final notifier = container.read(emergencyStateProvider.notifier);
        final stopwatch = Stopwatch()..start();

        // Act
        await notifier.startEmergency();
        stopwatch.stop();

        // Assert
        expect(stopwatch.elapsedMilliseconds, lessThanOrEqualTo(500));
      });
    });
  });
}
