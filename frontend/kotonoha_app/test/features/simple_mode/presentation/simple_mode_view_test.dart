/// SimpleModeView ウィジェットテスト
///
/// fix/improvement-p0-p2: シンプルモード（疲労時・症状進行時の簡易画面）
///
/// 対象: lib/features/simple_mode/presentation/simple_mode_view.dart
///
/// 検証内容:
/// - クイック応答・状態ボタン（12個）・お気に入りが表示される
/// - お気に入りが0件のときはお気に入りセクションが表示されない
/// - 「通常モードに戻る」ボタンが常に表示され、タップでコールバックが呼ばれる
/// - 各ボタンタップで対応するコールバックが呼ばれる
/// - スマホ縦/横・タブレットの各サイズでオーバーフローしない
library;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/simple_mode/presentation/simple_mode_view.dart';
import 'package:kotonoha_app/features/status_buttons/status_buttons.dart';

void main() {
  List<Favorite> buildFavorites(int count) {
    final now = DateTime(2026, 1, 1);
    return List.generate(
      count,
      (i) => Favorite(
        id: 'fav-$i',
        content: 'お気に入り$i',
        createdAt: now,
        displayOrder: i,
      ),
    );
  }

  Widget wrap(Widget child) => MaterialApp(home: Scaffold(body: child));

  group('SimpleModeView 表示', () {
    testWidgets('クイック応答ボタン（はい/いいえ/わからない）が表示される', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('はい'), findsOneWidget);
      expect(find.text('いいえ'), findsOneWidget);
      expect(find.text('わからない'), findsOneWidget);
    });

    testWidgets('状態ボタンが12個（全ボタン）表示される', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(StatusButton), findsNWidgets(12));
    });

    testWidgets('お気に入りが0件のときはお気に入りセクションが表示されない', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('お気に入り'), findsNothing);
    });

    testWidgets('お気に入りがあるとき、上位数件がグリッド表示される', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: buildFavorites(3),
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('お気に入り'), findsOneWidget);
      expect(find.text('お気に入り0'), findsOneWidget);
      expect(find.text('お気に入り1'), findsOneWidget);
      expect(find.text('お気に入り2'), findsOneWidget);
    });

    testWidgets('お気に入りは最大6件までしか表示されない', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: buildFavorites(10),
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('お気に入り0'), findsOneWidget);
      expect(find.text('お気に入り5'), findsOneWidget);
      expect(find.text('お気に入り6'), findsNothing);
    });

    testWidgets('「通常モードに戻る」ボタンが常に表示される', (tester) async {
      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byKey(const Key('exit_simple_mode_button')), findsOneWidget);
      expect(find.text('通常モードに戻る'), findsOneWidget);
    });
  });

  group('SimpleModeView コールバック', () {
    testWidgets('「通常モードに戻る」タップでonExitSimpleModeが呼ばれる', (tester) async {
      var exited = false;

      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () => exited = true,
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('exit_simple_mode_button')));
      await tester.pump();

      expect(exited, isTrue);
    });

    testWidgets('クイック応答タップでonQuickResponseとonTTSSpeakが呼ばれる', (tester) async {
      QuickResponseType? respondedType;
      String? spoken;

      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (type) => respondedType = type,
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (text) => spoken = text,
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('はい'));
      await tester.pump();

      expect(respondedType, QuickResponseType.yes);
      expect(spoken, 'はい');
    });

    testWidgets('状態ボタンタップでonStatusButtonとonTTSSpeakが呼ばれる', (tester) async {
      StatusButtonType? tappedType;
      String? spoken;

      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (type) => tappedType = type,
            onFavoriteTap: (_) {},
            onTTSSpeak: (text) => spoken = text,
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('痛い'));
      await tester.pump();

      expect(tappedType, StatusButtonType.pain);
      expect(spoken, '痛い');
    });

    testWidgets('お気に入りタップでonFavoriteTapが呼ばれる', (tester) async {
      Favorite? tapped;

      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: buildFavorites(1),
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (favorite) => tapped = favorite,
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      // お気に入りセクションはスクロール領域の下部にあるため、
      // タップ前に画面内へスクロールする。
      await tester.ensureVisible(find.text('お気に入り0'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('お気に入り0'));
      await tester.pump();

      expect(tapped?.content, 'お気に入り0');
    });
  });

  group('SimpleModeView レスポンシブ', () {
    for (final size in const [
      Size(390, 844), // 縦持ちスマホ
      Size(844, 390), // 横持ちスマホ
      Size(768, 1024), // タブレット
    ]) {
      testWidgets(
        '${size.width.toInt()}x${size.height.toInt()}: '
        'お気に入り6件表示時もオーバーフローしない',
        (tester) async {
          tester.view.physicalSize = size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
          });

          await tester.pumpWidget(
            wrap(
              SimpleModeView(
                fontSize: FontSize.medium,
                favorites: buildFavorites(6),
                onQuickResponse: (_) {},
                onStatusButton: (_) {},
                onFavoriteTap: (_) {},
                onTTSSpeak: (_) {},
                onExitSimpleMode: () {},
              ),
            ),
          );
          await tester.pumpAndSettle();

          expect(tester.takeException(), isNull);
        },
      );
    }

    testWidgets('状態ボタンの高さは60px以上である（390x844）', (tester) async {
      tester.view.physicalSize = const Size(390, 844);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(
        wrap(
          SimpleModeView(
            fontSize: FontSize.medium,
            favorites: const [],
            onQuickResponse: (_) {},
            onStatusButton: (_) {},
            onFavoriteTap: (_) {},
            onTTSSpeak: (_) {},
            onExitSimpleMode: () {},
          ),
        ),
      );
      await tester.pumpAndSettle();

      final size = tester.getSize(find.byType(StatusButton).first);
      expect(size.height, greaterThanOrEqualTo(60.0));
    });
  });
}
