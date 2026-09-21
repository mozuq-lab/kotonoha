import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/themes/theme_provider.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';

void main() {
  testWidgets('AI変換の超過結果を採用すると本番入力欄で切り詰めを告知する', (tester) async {
    SharedPreferences.setMockInitialValues({'ai_privacy_consent': true});
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    // Dioの通信境界のみでローカルの固定応答を返す。アプリの変換処理は実物。
    container.read(aiConversionApiClientProvider).dio.interceptors.add(
      InterceptorsWrapper(onRequest: (options, handler) {
        handler.resolve(Response(
          requestOptions: options,
          statusCode: 200,
          data: <String, dynamic>{
            'converted_text': 'あ' * 1001,
            'original_text': 'ああ',
            'politeness_level': 'normal',
            'processing_time_ms': 1,
          },
        ));
      }),
    );
    await container.read(networkProvider.notifier).setOnline();
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.tap(find.text('あ'));
    await tester.tap(find.text('あ'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('AI変換'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('採用'));
    await tester.pumpAndSettle();
    expect(find.textContaining('切り詰め').hitTestable(), findsOneWidget);
    expect(find.textContaining('達しました'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('同じ1000文字でも到達と切り詰めを区別し、削除・置換・全消去で解除する', (tester) async {
    tester.view.physicalSize = const Size(768, 1024);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    final container = ProviderContainer();
    addTearDown(container.dispose);
    await tester.pumpWidget(UncontrolledProviderScope(
      container: container,
      child: const MaterialApp(home: HomeScreen()),
    ));
    await tester.pumpAndSettle();
    final input = container.read(inputBufferProvider.notifier);
    final truncated = find.textContaining('切り詰め');
    final reached = find.textContaining('達しました');
    input.setText('あ' * 999);
    await tester.tap(find.text('あ'));
    await tester.pumpAndSettle();
    expect(reached.hitTestable(), findsOneWidget);
    expect(truncated, findsNothing);
    // 保存文字列が同じでも、超過結果を適用したことを通知する。
    input.setText('あ' * 1001);
    await tester.pumpAndSettle();
    expect(truncated.hitTestable(), findsOneWidget);
    expect(reached, findsNothing);
    input.setText('あ' * 1000);
    await tester.pumpAndSettle();
    expect(reached.hitTestable(), findsOneWidget);
    expect(truncated, findsNothing);
    input.setText('い' * 1001);
    input.deleteLastCharacter();
    await tester.pumpAndSettle();
    expect(truncated, findsNothing);
    expect(reached, findsNothing);
    input.addCharacter('う');
    await tester.pumpAndSettle();
    expect(reached.hitTestable(), findsOneWidget);
    expect(truncated, findsNothing);
    input.setText('え' * 1001);
    input.clear();
    for (var i = 0; i < 1000; i++) {
      input.addCharacter('お');
    }
    await tester.pumpAndSettle();
    expect(truncated, findsNothing);
    expect(reached.hitTestable(), findsOneWidget);
    input.setText('短文');
    await tester.pumpAndSettle();
    expect(reached, findsNothing);
    expect(truncated, findsNothing);
    expect(tester.takeException(), isNull);
  });

  for (final size in const [
    Size(320, 844),
    Size(360, 844),
    Size(390, 844),
    Size(768, 1024),
  ]) {
    for (final scale in [1.0, 1.3]) {
      for (final length in [1000, 1001]) {
        testWidgets('標準 $size OS倍率$scale 大設定 $length文字の告知が全文見える',
            (tester) async {
          SharedPreferences.setMockInitialValues({'fontSize': 'large'});
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);
          final container = ProviderContainer();
          addTearDown(container.dispose);
          await tester.pumpWidget(UncontrolledProviderScope(
            container: container,
            child: Consumer(builder: (context, ref, child) {
              return MaterialApp(
                theme: ref.watch(currentThemeProvider),
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(context).copyWith(
                    textScaler: TextScaler.linear(scale),
                  ),
                  child: child!,
                ),
                home: const HomeScreen(),
              );
            }),
          ));
          await tester.pumpAndSettle();
          container.read(inputBufferProvider.notifier).setText('あ' * length);
          await tester.pumpAndSettle();
          final notice = find.descendant(
            of: find.byType(InputLimitNotice),
            matching: find.byType(Text),
          );
          expect(notice.hitTestable(), findsOneWidget);
          final paragraph = tester.renderObject<RenderParagraph>(notice);
          expect(paragraph.didExceedMaxLines, isFalse);
          expect(tester.widget<Text>(notice).style!.fontSize, greaterThan(20));
          final boxes = paragraph.getBoxesForSelection(TextSelection(
            baseOffset: 0,
            extentOffset: paragraph.text.toPlainText().length,
          ));
          expect(boxes, isNotEmpty);
          if (size.width < 400) {
            expect(boxes.map((box) => box.top).toSet().length, greaterThan(1));
          }
          final bounds = Offset.zero & paragraph.size;
          for (final box in boxes) {
            expect(box.left, greaterThanOrEqualTo(bounds.left - 0.01));
            expect(box.right, lessThanOrEqualTo(bounds.right + 0.01));
            expect(box.bottom, lessThanOrEqualTo(bounds.bottom + 0.01));
          }
          final rect = tester.getRect(notice);
          expect(rect.top, greaterThanOrEqualTo(0));
          expect(rect.bottom, lessThan(size.height));
          expect(tester.takeException(), isNull);
        });
      }
    }
  }
}
