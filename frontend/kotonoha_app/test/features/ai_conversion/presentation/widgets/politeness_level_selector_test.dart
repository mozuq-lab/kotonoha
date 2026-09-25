import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/high_contrast_theme.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/politeness_level_selector.dart';

void main() {
  testWidgets('高コントラスト表示で選択中の丁寧さは色以外でも識別できる', (tester) async {
    await tester.pumpWidget(MaterialApp(
      theme: highContrastTheme,
      home: Scaffold(
        body: PolitenessLevelSelector(
          selectedLevel: PolitenessLevel.normal,
          onLevelChanged: (_) {},
        ),
      ),
    ));

    final selected = tester.widget<Text>(find.text('普通'));
    final unselected = tester.widget<Text>(find.text('丁寧'));
    expect(selected.style?.decoration, TextDecoration.underline);
    expect(unselected.style?.decoration, isNot(TextDecoration.underline));
  });
}
