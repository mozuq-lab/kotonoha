/// シンプルモード設定ウィジェット テスト
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// 対象: lib/features/settings/presentation/widgets/simple_mode_settings_widget.dart
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:kotonoha_app/features/settings/presentation/widgets/simple_mode_settings_widget.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

void main() {
  group('SimpleModeSettingsWidget', () {
    setUp(() async {
      SharedPreferences.setMockInitialValues({});
    });

    testWidgets('タイトルと説明文、スイッチが表示される', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SimpleModeSettingsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('シンプルモード'), findsOneWidget);
      expect(find.byType(SwitchListTile), findsOneWidget);
    });

    testWidgets('初期状態ではスイッチはOFFである', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SimpleModeSettingsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isFalse);
    });

    testWidgets('スイッチをタップするとシンプルモードがONになる', (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: SimpleModeSettingsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(SwitchListTile));
      await tester.pumpAndSettle();

      final settings = container.read(settingsNotifierProvider).requireValue;
      expect(settings.simpleMode, isTrue);

      final tile = tester.widget<SwitchListTile>(find.byType(SwitchListTile));
      expect(tile.value, isTrue);
    });

    testWidgets('タップターゲット（行全体）は44px以上の高さである', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: SimpleModeSettingsWidget()),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(SwitchListTile));
      expect(size.height, greaterThanOrEqualTo(44.0));
    });
  });
}
