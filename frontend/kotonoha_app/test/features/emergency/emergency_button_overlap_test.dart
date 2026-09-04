/// 緊急ボタンと画面本体UI（文字盤のキー）の被覆検証テスト
///
/// 改善対応: 常設緊急ボタンが文字盤のキーを覆う不具合の修正
///
/// 【修正前の不具合】:
/// 緊急ボタンはStackで画面本体の上に重ねられており、画面右下
/// （右16〜76px / 下16〜76px）のタップを常に吸収していた。文字盤の
/// GridViewは画面下端まで伸びてスクロールするため、スマホ縦持ち(390x844)では
/// 「ほ」「も」、横持ち(844x390)では「ふ」「も」が緊急ボタンの下に入り、
/// タップ有効面積が44px（REQ-5001）を下回るうえ、誤タップで緊急確認
/// ダイアログが開いてしまっていた。
///
/// 関連要件:
/// - REQ-301 / REQ-302: 緊急ボタンの全画面常時表示・常時到達可能
/// - REQ-5001 / NFR-202: タップターゲット最小44px・推奨60px
/// - TASK-0045 FR-005: 緊急ボタンは他のUI要素と重ならない位置に配置する
/// - TASK-0045 FR-006: 緊急ボタンと他の操作ボタンとの間に16px以上の間隔を設ける
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:mocktail/mocktail.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';

import '../../mocks/mock_emergency_audio_service.dart';

/// 代表的な画面サイズ（論理ピクセル、devicePixelRatio: 1.0）
const Map<String, Size> _screenSizes = <String, Size>{
  'スマホ縦(390x844)': Size(390, 844),
  '中間幅タブレット縦(680x1024)': Size(680, 1024),
  'タブレット縦(768x1024)': Size(768, 1024),
  'タブレット横(1024x768)': Size(1024, 768),
  '横持ちスマホ(844x390)': Size(844, 390),
};

void main() {
  group('緊急ボタンと画面本体UIの被覆検証', () {
    late MockEmergencyAudioService mockAudioService;
    late ProviderContainer container;
    late GoRouter router;

    setUp(() {
      mockAudioService = MockEmergencyAudioService();
      when(() => mockAudioService.startEmergencySound())
          .thenAnswer((_) async {});
      when(() => mockAudioService.stopEmergencySound())
          .thenAnswer((_) async {});

      container = ProviderContainer(
        overrides: [
          // 音声プラグイン依存を避けるためモックへ差し替え
          emergencyAudioServiceProvider.overrideWithValue(mockAudioService),
          // 設定のローディング状態（無限アニメーション）を回避
          settingsNotifierProvider.overrideWith(() => _MockSettingsNotifier()),
          // 【このテストの主題を保つため】: このテストが見ているのは
          // 「緊急ボタンバーが文字盤を圧迫しないか」であって、警告バナーの
          // レイアウト影響ではない。テスト環境ではHiveを開いていないため
          // 既定ではUnavailable（＝バナー表示）になってしまうので、
          // 通常状態のReadyに固定する。
          //
          // 【別途判明した問題】: 警告バナー（永続化・オフラインとも）を
          // 表示すると、タブレット横持ちで文字盤にスクロールが発生する。
          // オフラインバナーは本変更以前から同じ問題を持つ（実測35px）。
          // 台帳 Issue #85 へ送った。
          persistenceStateProvider.overrideWithValue(const PersistenceReady()),
        ],
      );
      router = container.read(routerProvider);
    });

    tearDown(() {
      container.dispose();
    });

    Widget buildTestApp() {
      return UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(routerConfig: router),
      );
    }

    /// 指定サイズでアプリ全体（ShellRoute + AppShell + 各画面）を描画する
    Future<void> pumpAppAt(WidgetTester tester, Size size) async {
      tester.view.physicalSize = size;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();
    }

    /// 文字盤グリッドのScrollPositionを取得する
    ScrollPosition gridScrollPosition(WidgetTester tester) {
      return tester
          .state<ScrollableState>(
            find.descendant(
              of: find.byType(GridView),
              matching: find.byType(Scrollable),
            ),
          )
          .position;
    }

    /// Elementの描画矩形（グローバル座標）
    ///
    /// find.byWidget()は同一のwidgetインスタンスが複数存在すると
    /// findsOneWidget違反になるため、Elementから直接RenderBoxを引く。
    Rect rectOfElement(Element element) {
      final box = element.renderObject! as RenderBox;
      return box.localToGlobal(Offset.zero) & box.size;
    }

    /// 実際にタップ可能な矩形（グリッドのビューポートでクリップされた領域）
    ///
    /// GridViewはビューポート外を描画・ヒットテストしないため、
    /// レイアウト上の矩形ではなくクリップ後の矩形で重なりを判定する。
    /// クリップ結果が空（完全にビューポート外）の場合はnullを返す。
    Rect? visibleRect(Rect rect, Rect viewport) {
      final left = rect.left > viewport.left ? rect.left : viewport.left;
      final top = rect.top > viewport.top ? rect.top : viewport.top;
      final right = rect.right < viewport.right ? rect.right : viewport.right;
      final bottom =
          rect.bottom < viewport.bottom ? rect.bottom : viewport.bottom;
      if (left >= right || top >= bottom) return null;
      return Rect.fromLTRB(left, top, right, bottom);
    }

    /// 表示中の全文字ボタンが緊急ボタンと重なっていないことを検証する
    void expectNoKeyOverlapsEmergencyButton(
      WidgetTester tester,
      String label,
    ) {
      final emergencyRect =
          tester.getRect(find.byType(EmergencyButtonWithConfirmation));
      final viewport = tester.getRect(find.byType(GridView));

      for (final element in find.byType(CharacterButton).evaluate()) {
        final widget = element.widget as CharacterButton;
        final tappableRect = visibleRect(rectOfElement(element), viewport);
        if (tappableRect == null) continue;

        expect(
          tappableRect.overlaps(emergencyRect),
          isFalse,
          reason: '[$label] 文字「${widget.character}」($tappableRect)が'
              '緊急ボタン($emergencyRect)と重なっており、'
              'タップが緊急ボタンに吸収される',
        );
      }
    }

    for (final entry in _screenSizes.entries) {
      final label = entry.key;

      testWidgets('$label: 文字盤のキーが緊急ボタンに覆われない', (tester) async {
        await pumpAppAt(tester, entry.value);

        final emergencyRect =
            tester.getRect(find.byType(EmergencyButtonWithConfirmation));

        // 緊急ボタン自体が推奨サイズ（60px）を維持していること
        // （REQ-301 / NFR-202 / TASK-0045 FR-003）。
        // 「重ならないようにボタンを小さくした」という誤った修正を防ぐ。
        expect(
          emergencyRect.width,
          greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
          reason: '[$label] 緊急ボタンの幅は推奨60px以上である必要がある',
        );
        expect(
          emergencyRect.height,
          greaterThanOrEqualTo(AppSizes.recommendedTapTarget),
          reason: '[$label] 緊急ボタンの高さは推奨60px以上である必要がある',
        );

        // 初期表示（スクロール位置0）で重なりがないこと
        expectNoKeyOverlapsEmergencyButton(tester, '$label / スクロール先頭');

        // 最下部までスクロールしても重なりがないこと
        // （スマホ縦・横持ちでは文字盤がスクロールするため、
        // 「たまたま最終行の右端が空セル」に依存しないことを確認する）
        final position = gridScrollPosition(tester);
        if (position.maxScrollExtent > 0) {
          position.jumpTo(position.maxScrollExtent);
          await tester.pumpAndSettle();
          expectNoKeyOverlapsEmergencyButton(tester, '$label / スクロール末尾');
        }

        // 【構造的な保証】: 文字盤ウィジェット全体の矩形が緊急ボタンと
        // 重ならないこと。これが成り立てば、スクロール位置・文字カテゴリ・
        // フォントサイズによらずキーが緊急ボタンの下に入ることはない。
        // タブレットでは「たまたま最終行の右端が空セル」だったために
        // 実害が出ていなかっただけなので、偶然に依存しないことを確認する。
        final boardRect = tester.getRect(find.byType(CharacterBoardWidget));
        expect(
          boardRect.overlaps(emergencyRect),
          isFalse,
          reason: '[$label] 文字盤の領域($boardRect)が'
              '緊急ボタン($emergencyRect)と重なっている',
        );

        // TASK-0045 FR-006: 緊急ボタンと他の操作ボタンの間隔は16px以上
        // （縦向きは文字盤の下、横向きは文字盤の右に緊急ボタンが来るため、
        //   離れている方の軸の間隔を見る）
        final horizontalGap = math.max(
          boardRect.left - emergencyRect.right,
          emergencyRect.left - boardRect.right,
        );
        final verticalGap = math.max(
          boardRect.top - emergencyRect.bottom,
          emergencyRect.top - boardRect.bottom,
        );
        expect(
          math.max(horizontalGap, verticalGap),
          greaterThanOrEqualTo(AppSizes.emergencyButtonMargin),
          reason: '[$label] 文字盤($boardRect)と緊急ボタン($emergencyRect)の'
              '間隔は16px以上必要',
        );
      });
    }

    testWidgets('タブレット横持ち(1024x768): 文字盤がスクロール不要のまま維持される', (tester) async {
      // 【退行防止】: 緊急ボタンバーを画面下部の横帯として確保すると、
      // 推奨端末（9.7インチタブレット）を横に持ったときに、それまで
      // スクロール不要だった文字盤にスクロールが発生してしまう
      // （セル高が44pxの下限に張り付き、表示キーが49→40に減る）。
      // CLAUDE.mdの「タップ主体・スワイプ非依存」に反するため、
      // 横向きではバーを画面右端の縦帯（サイドレール）に切り替えて
      // 縦方向を一切奪わないようにしている。
      await pumpAppAt(tester, const Size(1024, 768));

      final position = gridScrollPosition(tester);
      expect(
        position.maxScrollExtent,
        lessThanOrEqualTo(1.0),
        reason: 'タブレット横持ちで文字盤にスクロールが発生している'
            '（maxScrollExtent=${position.maxScrollExtent}）',
      );

      // セル高が44px下限に張り付いていない（=縦方向を圧迫していない）
      final anyKey = find.byType(CharacterButton).evaluate().first;
      final keyRect = rectOfElement(anyKey);
      expect(
        keyRect.height,
        greaterThan(AppSizes.minTapTarget),
        reason: 'セル高が44pxの下限に張り付いている（縦方向が圧迫されている）',
      );
    });

    testWidgets('ソフトキーボード表示中に無駄な空白帯ができない', (tester) async {
      // 【退行防止】: MediaQuery.removePaddingはpaddingしか消さないため、
      // 補正しないと画面本体は「バーの分だけ短い箱」からさらにキーボード全高を
      // 引くことになり、キーボード上端との間にバー1本分（92px）の空白帯が
      // できる。バーはキーボードの裏に完全に隠れるため、その分を差し引いた
      // viewInsetsを画面本体へ渡すのが正しい。
      const screenHeight = 844.0;
      const keyboardHeight = 336.0;

      tester.view.physicalSize = const Size(390, screenHeight);
      tester.view.devicePixelRatio = 1.0;
      tester.view.viewInsets = const FakeViewPadding(bottom: keyboardHeight);
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
        tester.view.resetViewInsets();
      });

      await tester.pumpWidget(buildTestApp());
      await tester.pumpAndSettle();

      // 文字盤は画面本体の最下段なので、その下端がキーボード上端に一致する
      // （＝キーボードとの間に無駄な空白帯がない）。
      final boardBottom =
          tester.getRect(find.byType(CharacterBoardWidget)).bottom;
      expect(
        boardBottom,
        closeTo(screenHeight - keyboardHeight, 0.5),
        reason: 'キーボード上端(${screenHeight - keyboardHeight})と'
            '画面本体の下端($boardBottom)の間に空白帯ができている',
      );
    });

    testWidgets('全画面共通: 画面本体（Scaffold）が緊急ボタンと重ならない', (tester) async {
      // AppShellは全ルート画面に緊急ボタンを配線するため、
      // 文字盤以外の画面でも画面本体と重ならないことを保証する。
      await pumpAppAt(tester, const Size(390, 844));

      for (final route in <String>[
        '/',
        '/settings',
        '/history',
        '/preset-phrases',
      ]) {
        router.go(route);
        await tester.pumpAndSettle();

        final emergencyRect =
            tester.getRect(find.byType(EmergencyButtonWithConfirmation));
        final scaffoldRect = tester.getRect(find.byType(Scaffold).first);

        expect(
          scaffoldRect.overlaps(emergencyRect),
          isFalse,
          reason: '$route の画面本体($scaffoldRect)が'
              '緊急ボタン($emergencyRect)と重なっている',
        );
      }
    });

    /// ルーター設定（＝アプリが実際に配信するルート）から全パスを集める。
    ///
    /// **手書きの一覧にしないこと。** 画面を1つ足したときに検査から漏れる。
    /// 実際、この検査を入れるまで `/favorites` `/help` `/face-to-face` の3画面は
    /// どの緊急ボタン検査も通っていなかった（2026-08-31 実測）。
    List<String> allRoutePaths() {
      final paths = <String>[];
      void walk(List<RouteBase> routes) {
        for (final route in routes) {
          if (route is GoRoute && route.path.startsWith('/')) {
            paths.add(route.path);
          }
          walk(route.routes);
        }
      }

      walk(router.configuration.routes);
      return paths;
    }

    /// 【向きを2つ回す理由】: 緊急ボタンバーは縦向きなら画面下部の横帯、
    /// 横向きなら画面右端の縦帯とレイアウトが変わる（`_buildEmergencyButtonBar`）。
    /// 推奨端末は9.7インチ以上のタブレットで横持ちの利用が普通にあるため、
    /// 縦だけ確かめても「発報できない」側の検査としては足りない。
    const reachabilityScreens = <String, Size>{
      'スマホ縦(390x844)': Size(390, 844),
      'タブレット横(1024x768)': Size(1024, 768),
    };

    for (final screen in reachabilityScreens.entries) {
      testWidgets('REQ-301: ${screen.key} の全ルートで緊急ボタンにタップが届き、確認ダイアログが開く',
          (tester) async {
        // 【「見えている」で終わらせない理由】: ADR-007 の条件2 が問うのは
        // 「発報できないこと」の検査である。ウィジェットが存在していても、
        // 手前の要素がヒットテストを吸収すれば発報できない（Issue #84 で
        // 実際に起きた形）。**タップが届いて確認ダイアログが開くところまで**見る。
        await pumpAppAt(tester, screen.value);

        final paths = allRoutePaths();
        expect(
          paths,
          contains(AppRoutes.faceToFace),
          reason: 'ルーター設定からパスを列挙できていること（列挙に失敗すると検査が空振りする）',
        );

        for (final path in paths) {
          router.go(path);
          await tester.pumpAndSettle();

          expect(
            find.byType(EmergencyButtonWithConfirmation),
            findsOneWidget,
            reason: '[${screen.key}] $path に緊急ボタンが表示されていない'
                '（REQ-301: 全画面で常時表示）',
          );

          await tester.tap(find.byType(EmergencyButtonWithConfirmation));
          await tester.pumpAndSettle();

          // 【finder を型で取る理由】: `find.text('はい')` はホーム画面の
          // クイック応答ボタン「はい」とも一致してしまい、ダイアログが
          // 開いていなくても緑になりうる（2026-08-31 に実測して気づいた）。
          expect(
            find.byType(EmergencyConfirmationDialog),
            findsOneWidget,
            reason: '[${screen.key}] $path で緊急ボタンにタップが届いていない'
                '（手前の要素が吸収している）',
          );

          // 次のルートへ進む前に元の状態へ戻す
          await tester.tap(
            find.descendant(
              of: find.byType(EmergencyConfirmationDialog),
              matching: find.text('いいえ'),
            ),
          );
          await tester.pumpAndSettle();
        }
      });
    }

    testWidgets('定型文画面: 追加FAB（右下）が緊急ボタンに覆われない', (tester) async {
      // 【修正前の不具合】: 定型文画面の「定型文を追加」FABは
      // Scaffoldの右下（外周16px・56px）に置かれるため、同じ位置に
      // 重ねられていた緊急ボタン（右下・外周16px・60px）にほぼ完全に
      // 覆われ、追加操作が緊急確認ダイアログに化けていた。
      await pumpAppAt(tester, const Size(390, 844));

      router.go('/preset-phrases');
      await tester.pumpAndSettle();

      final fab = find.byType(FloatingActionButton);
      expect(fab, findsOneWidget);

      final fabRect = tester.getRect(fab);
      final emergencyRect =
          tester.getRect(find.byType(EmergencyButtonWithConfirmation));

      expect(
        fabRect.overlaps(emergencyRect),
        isFalse,
        reason: '定型文追加FAB($fabRect)が緊急ボタン($emergencyRect)と重なっている',
      );
    });
  });
}

/// テスト用のモックSettingsNotifier
///
/// ローディング状態を回避するため、build()で即座にデフォルト設定を返す。
class _MockSettingsNotifier extends SettingsNotifier {
  @override
  Future<AppSettings> build() async {
    return const AppSettings();
  }
}
