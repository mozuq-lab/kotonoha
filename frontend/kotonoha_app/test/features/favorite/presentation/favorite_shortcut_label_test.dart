/// iPhone を縦にしたホームで、お気に入りの名前を語の途中で折り返さない
///
/// 電話の幅では 1 列に 4 つ並ぶので、5 文字の「ありがとう」が「ありが／とう」と
/// 2 行に分かれていた（iPhone 17 Pro のシミュレータ、2026-10-18）。収まらないときは
/// 文字を少し縮めて 1 行に収める。縮めすぎると読めないので、それでも収まらない
/// 長い名前は元の大きさで 2 行にする。
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/character_board/presentation/home_screen.dart';
import 'package:kotonoha_app/features/favorite/data/favorite_repository.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Android 14 以降の OS の文字の拡大は比例しない（小さい文字ほど大きく拡大する）。
/// 縮めた分ほど幅が減らないので、縮めた後も収まるかを確かめる必要がある
class _NonLinearScaler extends TextScaler {
  const _NonLinearScaler();

  @override
  double scale(double fontSize) => fontSize + 8;

  @override
  double get textScaleFactor => 1.4;
}

/// 縮めてよい下限（元の文字の大きさに対する割合）
const _minScale = 0.75;

Future<void> _pump(
    WidgetTester tester, Size size, List<String> contents) async {
  tester.view.physicalSize = size;
  tester.view.devicePixelRatio = 1.0;
  addTearDown(tester.view.reset);
  SharedPreferences.setMockInitialValues(
      {'tutorial_completed': true, 'fontSize': 'medium'});
  final container = ProviderContainer();
  addTearDown(container.dispose);
  for (final content in contents) {
    await container.read(favoriteProvider.notifier).addFavorite(content);
  }
  await tester.pumpWidget(UncontrolledProviderScope(
    container: container,
    child: const MaterialApp(home: AppShell(child: HomeScreen())),
  ));
  await tester.pumpAndSettle();
}

/// [name] のボタンの文字の描かれ方
({bool wraps, double fontSize}) _label(WidgetTester tester, String name) {
  final button = find.ancestor(
    of: find.text(name),
    matching: find.byType(FavoriteShortcutButton),
  );
  final paragraph = tester.renderObject<RenderParagraph>(
    find.descendant(of: button, matching: find.text(name)),
  );
  // 1 行で描くのに要る幅より狭く描かれていれば、折り返している
  // （固定の箱の中では高さや大きさを測っても折り返しは見えない）
  final wraps = paragraph.size.width <
      paragraph.getMaxIntrinsicWidth(double.infinity) - 0.5;
  return (wraps: wraps, fontSize: paragraph.text.style!.fontSize!);
}

void main() {
  // iPhone 17 Pro（6.3 インチ）と iPhone 17 Pro Max（6.9 インチ）の縦向き
  for (final size in const [Size(402, 874), Size(440, 956)]) {
    testWidgets('$size: 初期のお気に入りはどれも 1 行に収まり、縮めすぎない', (tester) async {
      await _pump(tester, size, FavoriteRepository.initialContents);

      expect(find.byType(FavoriteShortcutButton), findsNWidgets(8));
      for (final name in FavoriteRepository.initialContents) {
        final label = _label(tester, name);
        expect(label.wraps, isFalse, reason: '「$name」が語の途中で 2 行に折り返す');
        expect(label.fontSize,
            greaterThanOrEqualTo(AppSizes.fontSizeMedium * _minScale - 0.01),
            reason: '「$name」を縮めすぎている（${label.fontSize}）');
      }
    });

    testWidgets('$size: 縮めても収まらない長い名前は、元の大きさで 2 行にする', (tester) async {
      const long = 'くすりをのみたいです';
      // 8 件並べたときの幅で見る（1 件だけだとボタンが横に広がる）
      await _pump(
          tester, size, [long, ...FavoriteRepository.initialContents.skip(1)]);

      final label = _label(tester, long);
      expect(label.fontSize, AppSizes.fontSizeMedium,
          reason: '長い名前を小さく縮めて 1 行に詰め込んでいる');
      expect(label.wraps, isTrue);
    });
  }

  testWidgets('OS の文字の拡大が比例しなくても、縮めた名前を「…」で切らない', (tester) async {
    // 縮めれば 1 行に収まりそうに見えるが、比例しない拡大では収まらない幅
    for (final width in [70.0, 80.0, 90.0, 100.0, 110.0]) {
      await tester.pumpWidget(MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(textScaler: _NonLinearScaler()),
          child: Scaffold(
            body: Center(
              child: SizedBox(
                width: width,
                child: FavoriteShortcutButton(
                  favorite: Favorite(
                    id: 'f',
                    content: '水ほしい',
                    createdAt: DateTime(2026),
                    displayOrder: 0,
                  ),
                  onPressed: () {},
                  height: 120,
                  fontSize: FontSize.medium,
                ),
              ),
            ),
          ),
        ),
      ));
      final paragraph = tester.renderObject<RenderParagraph>(find.text('水ほしい'));
      expect(paragraph.didExceedMaxLines, isFalse,
          reason: '幅 $width で「水ほしい」が「…」で切れる');
    }
  });
}
