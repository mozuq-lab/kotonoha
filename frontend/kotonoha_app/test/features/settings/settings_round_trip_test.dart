/// 設定の往復テスト（Phase 3 / WP-3）
///
/// **UI → provider → SharedPreferences → 再起動相当 → UI** を1本で通す。
///
/// 【設定だけ storage が違う】: 履歴・定型文・お気に入りは Hive だが、設定は
/// SharedPreferences に入る。`setMockInitialValues` はプラグインが用意した
/// **インメモリの実装**であって自作のモックではないので、外部 SDK の境界として
/// 使ってよい（`docs/verification-principles.md`「モックは外部 SDK / ネットワーク
/// 境界にのみ置く」）。
///
/// 【フォントサイズを選んだ理由】: アクセシビリティ要件（REQ-801、3段階）で、
/// 視力の弱い利用者が最初に触る設定。**次の起動で戻ってしまう**と、
/// 発話で訂正できない利用者は毎回設定し直すことになる。
library;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/presentation/settings_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  final binding = TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() async {
    binding.defaultBinaryMessenger.setMockMethodCallHandler(
      const MethodChannel('flutter_tts'),
      (call) async => 1,
    );
    // 【まっさらな端末】: 保存済みの設定が無い状態から始める
    SharedPreferences.setMockInitialValues(<String, Object>{});
  });

  tearDown(() {
    binding.defaultBinaryMessenger
        .setMockMethodCallHandler(const MethodChannel('flutter_tts'), null);
  });

  testWidgets('フォントサイズを変えると保存され、再起動相当でも選ばれたまま', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    final largeLabel = find.text(FontSize.large.displayName);
    expect(largeLabel, findsOneWidget, reason: '「大」が選べること（往復の出発点）');

    // When: 「大」を選ぶ
    await tester.tap(largeLabel);
    await tester.pumpAndSettle();

    // Then: 実際に SharedPreferences へ書かれている（provider の状態ではなく storage を見る）
    late String? stored;
    await tester.runAsync(() async {
      final prefs = await SharedPreferences.getInstance();
      stored = prefs.getString('fontSize');
    });
    expect(stored, FontSize.large.name, reason: 'UI の操作が実際の保存先に到達していること');

    // And: 新しい ProviderScope（＝再起動相当）でも「大」が選ばれている
    await tester.pumpWidget(
      const ProviderScope(child: MaterialApp(home: SettingsScreen())),
    );
    await tester.pumpAndSettle();

    final selectedLarge = tester.widget<SegmentedButton<FontSize>>(
      find.byType(SegmentedButton<FontSize>),
    );
    expect(selectedLarge.selected, {FontSize.large},
        reason: '再起動後の UI が、保存された値から描かれていること');
  });
}
