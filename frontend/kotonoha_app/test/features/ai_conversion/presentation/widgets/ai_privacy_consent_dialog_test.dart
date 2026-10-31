/// AI 変換の同意画面。最初は短く見せ、残りは「詳しく見る」で画面の中に開く。
///
/// 個人情報保護法 28 条で同意の前に示す情報（外国の名称・その国の制度・提供先の措置）を、
/// 短くしても画面の外へ追い出していないことを見る。
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_privacy_consent_dialog.dart';

Future<void> _openDialog(
  WidgetTester tester, {
  VoidCallback? onCancel,
  VoidCallback? onConfirm,
}) async {
  await tester.pumpWidget(MaterialApp(
    home: Scaffold(
      body: Builder(
        builder: (context) => TextButton(
          onPressed: () => showDialog<void>(
            context: context,
            barrierDismissible: false,
            builder: (_) => AIPrivacyConsentDialog(
              onCancel: onCancel ?? () {},
              onConfirm: onConfirm ?? () {},
            ),
          ),
          child: const Text('開く'),
        ),
      ),
    ),
  ));
  await tester.tap(find.text('開く'));
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('最初から、何を・どの国の誰に送るかを読める', (tester) async {
    await _openDialog(tester);

    for (final text in [
      '入力した文章と選んだ丁寧さ',
      '再生成では前回の変換結果も',
      '米国の Cloudflare, Inc.',
      '日本の外',
      '名前や体調などを入力すると、それも送られます',
      '内容を保存しません',
      'AIの学習やサービスの改善に使わない',
    ]) {
      expect(find.textContaining(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('制度と措置の説明は、開くまで出さない', (tester) async {
    await _openDialog(tester);

    expect(find.text('詳しく見る'), findsOneWidget);
    expect(find.textContaining('CCPA'), findsNothing);
    expect(find.textContaining('日本の法律に基づく保護'), findsNothing);
  });

  testWidgets('「詳しく見る」で、同意の前に示す残りの情報を画面の中で読める', (tester) async {
    await _openDialog(tester);

    await tester.tap(find.text('詳しく見る'));
    await tester.pumpAndSettle();

    for (final text in [
      'ことのはのサーバーを経由',
      '世界各地の設備',
      'どの国かは前もって特定できません',
      '連邦の包括的な個人情報保護法',
      'CCPA',
      '日本の法律に基づく保護',
      'プライバシーポリシー',
      '外国にある第三者への提供について',
    ]) {
      expect(find.textContaining(text), findsOneWidget, reason: text);
    }
  });

  testWidgets('狭い画面で文字を大きくして開いても、ボタンは画面の中にある', (tester) async {
    tester.view.physicalSize = const Size(320, 568);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.reset);
    await tester.pumpWidget(MaterialApp(
      builder: (context, child) => MediaQuery(
        data: MediaQuery.of(context).copyWith(
          textScaler: const TextScaler.linear(2),
        ),
        child: child!,
      ),
      home: AIPrivacyConsentDialog(onCancel: () {}, onConfirm: () {}),
    ));
    await tester.pumpAndSettle();

    final details = find.text('詳しく見る');
    await tester.ensureVisible(details);
    await tester.pumpAndSettle();
    await tester.tap(details);
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    final screen = tester.getRect(find.byType(MaterialApp));
    for (final label in ['同意しない', '同意して利用']) {
      final rect = tester.getRect(find.text(label));
      expect(screen.contains(rect.topLeft), isTrue, reason: label);
      expect(screen.contains(rect.bottomRight), isTrue, reason: label);
    }
  });

  testWidgets('「同意しない」は不同意だけを、「同意して利用」は同意だけを伝える', (tester) async {
    var cancelled = 0;
    var confirmed = 0;
    await _openDialog(
      tester,
      onCancel: () => cancelled++,
      onConfirm: () => confirmed++,
    );

    await tester.tap(find.text('同意しない'));
    expect((cancelled, confirmed), (1, 0));

    await tester.tap(find.text('詳しく見る'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('同意して利用'));
    expect((cancelled, confirmed), (1, 1));
  });
}
