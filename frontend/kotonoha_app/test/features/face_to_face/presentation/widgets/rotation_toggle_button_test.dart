/// RotationToggleButton widget test
///
/// TASK-0053: 180 degree screen rotation
/// Test cases: TC-053-012 to TC-053-016
///
/// Test target: lib/features/face_to_face/presentation/widgets/rotation_toggle_button.dart
///
/// TDD Red phase: RotationToggleButton not implemented, tests should fail
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/rotation_toggle_button.dart';
import 'package:kotonoha_app/features/face_to_face/providers/face_to_face_provider.dart';

void main() {
  group('RotationToggleButton widget test (TASK-0053)', () {
    /// TC-053-012: Rotation button is displayed
    testWidgets('TC-053-012: Rotation button is displayed', (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RotationToggleButton(),
            ),
          ),
        ),
      );

      expect(
        find.byType(RotationToggleButton),
        findsOneWidget,
        reason: 'RotationToggleButton exists',
      );
    });

    /// TC-053-013: Button tap toggles rotation state
    testWidgets('TC-053-013: Button tap toggles rotation state',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RotationToggleButton(),
            ),
          ),
        ),
      );

      expect(
        container.read(faceToFaceProvider).isRotated180,
        isFalse,
        reason: 'Initial state: no rotation',
      );

      await tester.tap(find.byType(RotationToggleButton));
      await tester.pump();

      expect(
        container.read(faceToFaceProvider).isRotated180,
        isTrue,
        reason: 'First tap: rotation enabled',
      );

      await tester.tap(find.byType(RotationToggleButton));
      await tester.pump();

      expect(
        container.read(faceToFaceProvider).isRotated180,
        isFalse,
        reason: 'Second tap: rotation disabled',
      );
    });

    /// TC-053-014: Button size is 44px x 44px or larger
    testWidgets('TC-053-014: Button size is 44px x 44px or larger',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RotationToggleButton(),
            ),
          ),
        ),
      );

      final buttonFinder = find.byType(RotationToggleButton);
      final size = tester.getSize(buttonFinder);

      expect(
        size.width,
        greaterThanOrEqualTo(44.0),
        reason: 'Button width >= 44px',
      );

      expect(
        size.height,
        greaterThanOrEqualTo(44.0),
        reason: 'Button height >= 44px',
      );
    });

    /// TC-053-015: Button provides visual feedback based on rotation state
    testWidgets('TC-053-015: Button provides visual feedback',
        (WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            home: Scaffold(
              body: RotationToggleButton(),
            ),
          ),
        ),
      );

      // 初期状態: 回転OFF
      expect(
        container.read(faceToFaceProvider).isRotated180,
        isFalse,
        reason: 'Initial state: rotation OFF',
      );

      // ボタンをタップして回転ON
      await tester.tap(find.byType(RotationToggleButton));
      await tester.pump();

      // 回転状態が変わったことを確認
      expect(
        container.read(faceToFaceProvider).isRotated180,
        isTrue,
        reason: 'After tap: rotation ON - visual feedback provided',
      );
    });

    /// TC-053-016: Rotation icon is clear
    testWidgets('TC-053-016: Rotation icon is clear', (WidgetTester tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: RotationToggleButton(),
            ),
          ),
        ),
      );

      expect(
        find.byIcon(Icons.screen_rotation),
        findsOneWidget,
        reason: 'Screen rotation icon is displayed',
      );
    });
  });
}
