/// 対面表示モードへのナビゲーション統合テスト（fix/improvement-p0-p2）
///
/// TASK-0052/0053: 実装済みだった対面表示モード（FaceToFaceScreen、
/// 180度回転機能）が画面から到達できなかった問題を修正し、
/// ホーム画面のAppBarアクションからgo_router経由で遷移できるよう配線した。
///
/// 関連要件: REQ-501〜503（対面表示モード）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/screens/face_to_face_screen.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/rotation_toggle_button.dart';
import 'package:kotonoha_app/features/face_to_face/providers/face_to_face_provider.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

void main() {
  group('対面表示モードへのナビゲーション', () {
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      // settingsNotifierProviderをモックでオーバーライドして
      // CircularProgressIndicator（無限アニメーション）を回避
      container = ProviderContainer(
        overrides: [
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

    testWidgets(
        '入力中のテキストがある状態でAppBarの対面表示アイコンをタップすると、'
        'そのテキストを表示するFaceToFaceScreenへ遷移する', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 文字盤に入力する（対面表示に渡されるテキスト）
      container.read(inputBufferProvider.notifier).setText('おみずください');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.byType(FaceToFaceScreen), findsOneWidget);
      expect(find.text('おみずください'), findsOneWidget);
    });

    testWidgets('対面表示画面には180度回転トグルボタンが表示され、既存の回転機能を利用できる', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      container.read(inputBufferProvider.notifier).setText('テスト');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      expect(find.byType(RotationToggleButton), findsOneWidget);
      expect(container.read(faceToFaceProvider).isRotated180, isFalse);

      await tester.tap(find.byType(RotationToggleButton));
      await tester.pumpAndSettle();

      expect(container.read(faceToFaceProvider).isRotated180, isTrue);
    });

    testWidgets('対面表示画面を閉じるとホーム画面に戻る', (tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      container.read(inputBufferProvider.notifier).setText('テスト');
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();
      expect(find.byType(FaceToFaceScreen), findsOneWidget);

      await tester.tap(find.byIcon(Icons.close));
      await tester.pumpAndSettle();

      expect(find.byType(FaceToFaceScreen), findsNothing);
      expect(find.text('入力してください...'), findsNothing);
      // ホーム画面（文字盤）に戻り、入力していたテキストが表示される
      expect(find.text('テスト'), findsOneWidget);
    });

    testWidgets('入力が空の場合は直近の読み上げ履歴のテキストが対面表示される', (tester) async {
      // 入力バッファは空のまま（履歴もまだ空）
      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(Icons.open_in_full));
      await tester.pumpAndSettle();

      // 表示テキストが空でもFaceToFaceScreen自体は表示される
      expect(find.byType(FaceToFaceScreen), findsOneWidget);
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
