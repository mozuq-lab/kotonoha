/// 警告系ウィジェットのコントラスト比回帰テスト
///
/// 【テスト対象】: OfflineIndicator / VolumeWarningWidget
/// 【テスト目的】: 警告表示の前景色/背景色が WCAG 2.1 AA を満たし続けることを保証する
/// 【背景】: これらは `Colors.orange.shade100` 背景に `Colors.orange`（約1.7:1）や
/// `orange.shade800/900`（約2.5〜3.0:1）を重ねており AA 未達だった。
/// 色定数を戻した場合に検知できるよう、実際に描画された色から比を計算して検証する。
///
/// エラーダイアログ側は error_dialog_contrast_test.dart が担当する。
///
/// 🔵 信頼性レベル: 青信号 - NFR（高コントラストモード WCAG 2.1 AA・4.5:1以上）
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';

import 'contrast_helpers.dart';

void main() {
  group('コントラスト比計算ヘルパーの妥当性', () {
    test('既知の値と一致する', () {
      // 黒背景に白文字は最大比 21:1
      expect(
        contrastRatio(const Color(0xFFFFFFFF), const Color(0xFF000000)),
        closeTo(21.0, 0.01),
      );
      // 同色同士は 1:1
      expect(
        contrastRatio(const Color(0xFF6D2C00), const Color(0xFF6D2C00)),
        closeTo(1.0, 0.01),
      );
      // 修正前の組み合わせ（Colors.orange on orange.shade100）はAA未達であること
      expect(
        contrastRatio(const Color(0xFFFF9800), const Color(0xFFFFE0B2)),
        lessThan(4.5),
      );
    });
  });

  group('OfflineIndicator のコントラスト比', () {
    /// オフライン状態にして表示させる。
    Future<void> pumpOffline(WidgetTester tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await container.read(networkProvider.notifier).setOffline();

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: const MaterialApp(
            home: Scaffold(body: Center(child: OfflineIndicator())),
          ),
        ),
      );
      await tester.pump();
    }

    /// 表示本体のContainerから背景色を取り出す。
    Color background(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(OfflineIndicator),
              matching: find.byType(Container),
            )
            .first,
      );
      return (container.decoration! as BoxDecoration).color!;
    }

    testWidgets('テキストと背景が 4.5:1 以上', (tester) async {
      await pumpOffline(tester);

      final bg = background(tester);
      final textColor = resolvedTextColor(tester, find.text('オフライン'));

      // 【前提確認】: 半透明だとこの計算が実際の比を保証できない
      expectOpaque(bg, 'オフライン表示の背景色');
      expectOpaque(textColor, 'オフライン表示のテキスト色');

      // 【結果検証】: AA基準（4.5:1）を満たすこと
      final ratio = contrastRatio(textColor, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: 'オフライン表示のコントラスト比が ${ratio.toStringAsFixed(2)}:1 で '
            'WCAG 2.1 AA (4.5:1) 未達',
      );
    });

    testWidgets('アイコンと背景が 3:1 以上', (tester) async {
      await pumpOffline(tester);

      final bg = background(tester);
      final iconColor = resolvedIconColor(tester, Icons.wifi_off);

      expectOpaque(bg, 'オフライン表示の背景色');
      expectOpaque(iconColor, 'オフラインアイコンの色');

      final ratio = contrastRatio(iconColor, bg);
      expect(
        ratio,
        greaterThanOrEqualTo(3.0),
        reason: 'オフラインアイコンのコントラスト比が '
            '${ratio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
      );
    });
  });

  group('VolumeWarningWidget のコントラスト比', () {
    /// 警告本体のContainer（BoxDecorationを持つもの）を取得する。
    ///
    /// 祖先方向に辿ると harness 側のContainerを拾いうるため、
    /// 対象ウィジェット配下に限定して最初のContainerを取る。
    BoxDecoration warningDecoration(WidgetTester tester) {
      final container = tester.widget<Container>(
        find
            .descendant(
              of: find.byType(VolumeWarningWidget),
              matching: find.byType(Container),
            )
            .first,
      );
      return container.decoration! as BoxDecoration;
    }

    Future<void> pumpWarning(WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: VolumeWarningWidget(isVisible: true, onDismiss: () {}),
          ),
        ),
      );
      await tester.pump();
    }

    testWidgets('メッセージと背景が 4.5:1 以上', (tester) async {
      await pumpWarning(tester);

      final background = warningDecoration(tester).color!;
      final textColor = resolvedTextColor(tester, find.text('音量が0です'));

      expectOpaque(background, '音量警告の背景色');
      expectOpaque(textColor, '音量警告のテキスト色');

      final ratio = contrastRatio(textColor, background);
      expect(
        ratio,
        greaterThanOrEqualTo(4.5),
        reason: '音量警告メッセージのコントラスト比が '
            '${ratio.toStringAsFixed(2)}:1 で WCAG 2.1 AA (4.5:1) 未達',
      );
    });

    testWidgets('アイコン・枠線と背景が 3:1 以上', (tester) async {
      await pumpWarning(tester);

      final decoration = warningDecoration(tester);
      final background = decoration.color!;
      expectOpaque(background, '音量警告の背景色');

      // 音量オフアイコン
      final volumeIconColor = resolvedIconColor(tester, Icons.volume_off);
      final iconRatio = contrastRatio(volumeIconColor, background);
      expect(
        iconRatio,
        greaterThanOrEqualTo(3.0),
        reason: '音量オフアイコンのコントラスト比が '
            '${iconRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
      );

      // 閉じるアイコン
      final closeIconColor = resolvedIconColor(tester, Icons.close);
      final closeRatio = contrastRatio(closeIconColor, background);
      expect(
        closeRatio,
        greaterThanOrEqualTo(3.0),
        reason: '閉じるアイコンのコントラスト比が '
            '${closeRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
      );

      // 枠線
      final borderColor = decoration.border!.top.color;
      final borderRatio = contrastRatio(borderColor, background);
      expect(
        borderRatio,
        greaterThanOrEqualTo(3.0),
        reason: '警告枠線のコントラスト比が '
            '${borderRatio.toStringAsFixed(2)}:1 で非テキスト基準 (3:1) 未達',
      );
    });
  });
}
