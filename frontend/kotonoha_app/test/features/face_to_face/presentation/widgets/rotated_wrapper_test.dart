/// RotatedWrapper widget test
///
/// TASK-0053: 180 degree screen rotation
/// Test cases: TC-053-008 to TC-053-011
///
/// Test target: lib/features/face_to_face/presentation/widgets/rotated_wrapper.dart
///
/// TDD Red phase: RotatedWrapper not implemented, tests should fail
library;

import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/face_to_face/presentation/widgets/rotated_wrapper.dart';

void main() {
  group('RotatedWrapper widget test (TASK-0053)', () {
    /// TC-053-008: Display child widget as-is when isRotated=false
    testWidgets('TC-053-008: Display child widget as-is when isRotated=false',
        (WidgetTester tester) async {
      const testText = 'Test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: false,
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('rotation_transform')),
        findsNothing,
        reason: 'Transform not applied when not rotated',
      );

      expect(
        find.text(testText),
        findsOneWidget,
        reason: 'Child widget is displayed',
      );
    });

    /// TC-053-009: Apply Transform.rotate when isRotated=true
    testWidgets('TC-053-009: Apply Transform.rotate when isRotated=true',
        (WidgetTester tester) async {
      const testText = 'Test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: true,
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(
        find.byKey(const ValueKey('rotation_transform')),
        findsOneWidget,
        reason: 'Transform applied when rotated',
      );

      expect(
        find.text(testText),
        findsOneWidget,
        reason: 'Child widget is displayed',
      );
    });

    /// TC-053-010: Transform.rotate angle is math.pi (180 degrees)
    testWidgets('TC-053-010: Transform.rotate angle is math.pi (180 degrees)',
        (WidgetTester tester) async {
      const testText = 'Test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: true,
              child: Text(testText),
            ),
          ),
        ),
      );

      final transformFinder = find.byKey(const ValueKey('rotation_transform'));
      final transform = tester.widget<Transform>(transformFinder);

      expect(
        transform.transform,
        isNotNull,
        reason: 'Transform property is set',
      );

      final expectedTransform = Matrix4.rotationZ(math.pi);
      expect(
        transform.transform,
        equals(expectedTransform),
        reason: 'Rotation angle is math.pi (180 degrees)',
      );
    });

    /// TC-053-011: Rotation center is screen center (Alignment.center)
    testWidgets('TC-053-011: Rotation center is screen center (Alignment.center)',
        (WidgetTester tester) async {
      const testText = 'Test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: true,
              child: Text(testText),
            ),
          ),
        ),
      );

      final transformFinder = find.byKey(const ValueKey('rotation_transform'));
      final transform = tester.widget<Transform>(transformFinder);

      expect(
        transform.alignment,
        equals(Alignment.center),
        reason: 'Rotation center is Alignment.center',
      );
    });

    /// Additional test: Child widget renders correctly after rotation
    testWidgets('Additional test: Child widget renders correctly after rotation',
        (WidgetTester tester) async {
      const testText = 'Rotation test';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: true,
              child: Text(testText),
            ),
          ),
        ),
      );

      expect(
        find.text(testText),
        findsOneWidget,
        reason: 'Child widget content is displayed after rotation',
      );
    });

    /// Additional test: Rotation works with complex child widgets
    testWidgets('Additional test: Rotation works with complex child widgets',
        (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RotatedWrapper(
              isRotated: true,
              child: Column(
                children: [
                  Text('Line 1'),
                  Text('Line 2'),
                  ElevatedButton(onPressed: () {}, child: Text('Button')),
                ],
              ),
            ),
          ),
        ),
      );

      expect(find.text('Line 1'), findsOneWidget);
      expect(find.text('Line 2'), findsOneWidget);
      expect(find.text('Button'), findsOneWidget);
      expect(find.byKey(const ValueKey('rotation_transform')), findsOneWidget);
    });
  });
}
