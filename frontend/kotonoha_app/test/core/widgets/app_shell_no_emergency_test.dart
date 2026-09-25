import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  for (final size in [const Size(390, 844), const Size(1024, 768)]) {
    testWidgets('AppShell は $size で呼び出し警報を表示せず画面全体を子に渡す', (tester) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.reset);
      SharedPreferences.setMockInitialValues({'tutorial_completed': true});

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: AppShell(
              child: Scaffold(body: SizedBox.expand(key: ValueKey('page'))),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.bySemanticsLabel('緊急呼び出しボタン'), findsNothing);
      final page = tester.getRect(find.byKey(const ValueKey('page')));
      expect(page.right, size.width);
      expect(page.bottom, size.height);
    });
  }
}
