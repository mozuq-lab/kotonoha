/// アプリ全画面共通シェル
///
/// 全ルート画面を内包する共通シェル。go_routerのShellRouteから利用され、
/// 以下の5つの横断的関心事を全画面に配線する。
///
/// 1. ネットワーク監視の起動（F2 / REQ-1001, REQ-3004）
///    - 起動時に一度だけ NetworkNotifier を初期化し、接続状態の監視を開始する。
///    - これにより `isAIConversionAvailable` がオンライン時に true となり、
///      AI変換が利用可能になる。
///
/// 2. 緊急機能の全画面配線（F3 / REQ-301, REQ-302, REQ-304）
///    - 右下に緊急ボタンを常時表示（REQ-301）。
///    - 緊急状態（alertActive）の時に緊急アラート画面を最前面に重ねる（REQ-304）。
///    - 【重なり対策】: 緊急ボタンは画面本体に「重ねる」のではなく、画面端に
///      専用の帯（緊急ボタンバー）としてレイアウト領域を確保して配置する。
///      縦向きは画面下部の横帯、横向きは画面右端の縦帯（サイドレール）。
///      詳細は [_AppShellState._buildEmergencyButtonBar] を参照。
///
/// 3. 緊急時の音量警告配線（EDGE-203）
///    - 緊急状態に遷移したタイミングでOS音量（VolumeService）を確認し、
///      音量が0（マナーモード等で緊急音が聞こえない可能性がある）場合は
///      EmergencyAlertScreen に警告メッセージを渡して視覚的に補完する。
///
/// 4. オフライン状態表示（REQ-1002）/ オンライン復帰通知（EDGE-001）
///    - 全画面共通で、オフライン時は常時バナーを表示し、オンライン復帰時は
///      一時的な復帰通知を表示する（fix/improvement-p0-p2で配線）。
///
/// 5. 初回チュートリアル表示（TASK-0075 / REQ-3001）
///    - 初回起動時（チュートリアル未完了時）にTutorialOverlayを画面本体
///      （オフラインバナー＋現在のルート画面）にのみ重ねる
///      （fix/improvement-p0-p2で配線）。緊急ボタン・緊急アラート画面は
///      常にTutorialOverlayより手前に表示され、チュートリアル表示中も
///      操作をブロックされない（REQ-301, REQ-302）。
///
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
library;

import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/emergency/domain/models/emergency_state.dart';
import 'package:kotonoha_app/features/emergency/presentation/providers/emergency_state_provider.dart';
import 'package:kotonoha_app/features/emergency/presentation/screens/emergency_alert_screen.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_button_with_confirmation.dart';
import 'package:kotonoha_app/features/help/presentation/widgets/tutorial_overlay.dart';
import 'package:kotonoha_app/features/help/providers/tutorial_provider.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/offline_banner.dart';
import 'package:kotonoha_app/features/network/presentation/widgets/online_recovery_notification.dart';
import 'package:kotonoha_app/features/network/providers/network_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';

/// AppShellで使用する定数
abstract class _AppShellConstants {
  /// 緊急時、OS音量が0の場合に表示する警告メッセージ（EDGE-203対応）
  ///
  /// マナーモードやミュート設定により緊急音が聞こえない可能性がある場合に、
  /// 視覚的な代替手段としてEmergencyAlertScreenへ渡す。
  static const String volumeZeroWarningMessage = 'マナーモード中のため音が鳴らない可能性があります';
}

/// 全画面共通シェルウィジェット
///
/// ShellRouteのbuilderから `AppShell(child: child)` として生成される。
/// [child] は現在のルート画面ウィジェット。
class AppShell extends ConsumerStatefulWidget {
  /// 現在表示中のルート画面
  final Widget child;

  /// AppShellを作成する。
  ///
  /// [child] - ShellRouteから渡される現在のルート画面（必須）
  const AppShell({super.key, required this.child});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  /// ネットワーク監視の起動を一度きりにするためのフラグ
  bool _networkInitialized = false;

  /// 緊急アラート画面へ渡す警告メッセージ（EDGE-203）
  ///
  /// nullの場合は警告メッセージなし。
  /// 緊急状態がalertActiveに遷移したタイミングで音量チェックを行い、
  /// 音量0の場合にのみ設定される。
  String? _volumeWarningMessage;

  @override
  void initState() {
    super.initState();
    // 最初のフレーム描画後にネットワーク監視・チュートリアル判定を起動する。
    // initState内で直接ref.readを呼ばず、addPostFrameCallbackで遅延実行する。
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initializeNetworkMonitoring();
      _initializeTutorial();
    });
  }

  /// ネットワーク監視を起動する（一度きり）
  ///
  /// 初期接続状態の確認と接続状態変更リスナーの開始を行う。
  /// connectivity_plusプラグインが未モックなテスト環境などでも
  /// テストが落ちないよう、例外は握りつぶす
  /// （NetworkNotifier側でも捕捉済み）。
  Future<void> _initializeNetworkMonitoring() async {
    if (_networkInitialized) return;
    _networkInitialized = true;

    try {
      final notifier = ref.read(networkProvider.notifier);
      await notifier.initializeWithConnectivity();
      await notifier.startListening();
    } catch (_) {
      // テスト環境などでのプラグイン未モック対策。
      // ネットワーク状態は checking のままとなり、AI変換は無効のままになる。
    }
  }

  /// チュートリアル完了状態を初期化する（TASK-0075 / REQ-3001）
  ///
  /// shared_preferencesから初回起動判定を読み込む。読み込みが完了するまでは
  /// `TutorialState.isLoading == true` のためチュートリアルは表示されない。
  /// テスト環境などでSharedPreferencesが未モックの場合に例外が発生しても、
  /// アプリ本体の表示に影響を与えないよう握りつぶす
  /// （その場合チュートリアルは表示されないままとなる）。
  Future<void> _initializeTutorial() async {
    try {
      await ref.read(tutorialProvider.notifier).initialize();
    } catch (_) {
      // テスト環境などでのSharedPreferences未モック対策。
    }
  }

  /// 緊急状態がalertActiveに遷移したタイミングでOS音量をチェックする（EDGE-203）
  ///
  /// VolumeService経由でOS音量が0かどうかを判定し、
  /// 音量0の場合は警告メッセージをEmergencyAlertScreenへ渡すために状態を更新する。
  ///
  /// 【エラーハンドリング】:
  /// VolumeService側で例外は握りつぶされ isVolumeZero() は false を返す設計だが、
  /// 万が一の例外発生時も緊急フロー自体を止めないよう、ここでも防御的に捕捉する。
  Future<void> _checkVolumeWarning() async {
    try {
      final volumeService = ref.read(volumeServiceProvider);
      final isZero = await volumeService.isVolumeZero();
      if (!mounted) return;
      setState(() {
        _volumeWarningMessage =
            isZero ? _AppShellConstants.volumeZeroWarningMessage : null;
      });
    } catch (_) {
      // 音量チェックに失敗しても緊急画面表示は継続する（警告表示のみ諦める）。
      if (!mounted) return;
      setState(() => _volumeWarningMessage = null);
    }
  }

  @override
  Widget build(BuildContext context) {
    // 緊急状態を監視し、alertActive時に緊急画面を最前面に重ねる（REQ-304）
    final emergencyState = ref.watch(emergencyStateProvider);
    final isAlertActive = emergencyState == EmergencyStateEnum.alertActive;

    // 初回チュートリアル表示要否を監視する（TASK-0075 / REQ-3001）。
    final tutorialState = ref.watch(tutorialProvider);

    // normal -> alertActive への遷移を検知し、音量チェックを一度だけ実行する（EDGE-203）。
    // alertActiveから抜けた場合は次回の緊急発生に備えて警告メッセージをクリアする。
    ref.listen<EmergencyStateEnum>(emergencyStateProvider, (previous, next) {
      final wasActive = previous == EmergencyStateEnum.alertActive;
      final isActive = next == EmergencyStateEnum.alertActive;
      if (!wasActive && isActive) {
        _checkVolumeWarning();
      } else if (wasActive && !isActive && _volumeWarningMessage != null) {
        setState(() => _volumeWarningMessage = null);
      }
    });

    // 現在のルート画面。オフライン時は常時バナーを表示し（REQ-1002）、
    // オンライン復帰時は一時的な復帰通知を重ねる（EDGE-001）。
    final screenContent = OnlineRecoveryNotification(
      child: Column(
        children: [
          const OfflineBanner(),
          Expanded(child: widget.child),
        ],
      ),
    );

    // 初回起動時（チュートリアル未完了時）はTutorialOverlayを画面本体にのみ
    // 重ねる（TASK-0075 / REQ-3001）。完了・スキップ操作でcompleteTutorial()を
    // 呼び、以降の起動では再表示されないようにする。
    //
    // 【安全性（重要）】: TutorialOverlayは半透明の黒背景で覆う不透明な
    // Containerを最前面に描画するため、これで緊急ボタンまで覆ってしまうと
    // チュートリアル表示中は緊急ボタンがタップ不能になる。緊急機能は
    // いかなる状況でもブロックしてはならない（REQ-301, REQ-302）ため、
    // TutorialOverlayは画面本体（screenContent）のみをラップし、
    // 緊急ボタン・緊急アラート画面は下記Stackで常にその手前（最前面）に
    // 配置する。
    final bodyContent = tutorialState.shouldShowTutorial
        ? TutorialOverlay(
            onComplete: () {
              ref.read(tutorialProvider.notifier).completeTutorial();
            },
            child: screenContent,
          )
        : screenContent;

    // 【向きによる配置切替】: 緊急ボタンバーは縦向きなら画面下部の横帯、
    // 横向きなら画面右端の縦帯（サイドレール）としてレイアウト領域を確保する。
    // 横向きで縦方向に92pxを使うと文字盤の可視行数が大きく減り、推奨端末の
    // タブレット横持ち（1024x768）ではスクロール不要だった文字盤にスクロールが
    // 発生してしまう。「タップ主体・スワイプ非依存」の方針（CLAUDE.md）に
    // 反するため、横向きでは相対的に余裕のある横方向から確保する。
    final mediaQuery = MediaQuery.of(context);
    final isLandscape = mediaQuery.orientation == Orientation.landscape;

    // 画面本体。緊急ボタンバーの太さぶんだけ小さくなるため、
    // 画面側のUIが緊急ボタンの下に潜り込むことがない。
    final screenBody = Expanded(
      child: MediaQuery(
        data: _screenMediaQueryData(mediaQuery, isLandscape: isLandscape),
        child: bodyContent,
      ),
    );

    return Stack(
      children: [
        if (isLandscape)
          Row(
            children: [
              screenBody,
              _buildEmergencyButtonBar(context, isLandscape: true),
            ],
          )
        else
          Column(
            children: [
              screenBody,
              _buildEmergencyButtonBar(context, isLandscape: false),
            ],
          ),

        // 緊急アラート画面（alertActive時のみ最前面に表示 / REQ-304）
        if (isAlertActive)
          Positioned.fill(
            child: EmergencyAlertScreen(
              onReset: () =>
                  ref.read(emergencyStateProvider.notifier).resetEmergency(),
              // OS音量が0の場合の警告メッセージ（EDGE-203）
              warningMessage: _volumeWarningMessage,
            ),
          ),
      ],
    );
  }

  /// 画面本体（各ルート画面）へ渡すMediaQueryDataを構築する
  ///
  /// 緊急ボタンバーが画面端のレイアウト領域を占有するぶん、
  /// 画面本体側のインセットを補正する。
  MediaQueryData _screenMediaQueryData(
    MediaQueryData mediaQuery, {
    required bool isLandscape,
  }) {
    if (isLandscape) {
      // 右端のシステムインセット（横持ち時のノッチ等）はサイドレール側の
      // SafeAreaが消費するため、画面本体側では取り除く。
      // 縦方向は何も奪っていないので、下端インセット・キーボード
      // （viewInsets）はそのまま画面本体へ渡す。
      return mediaQuery.removePadding(removeRight: true);
    }

    // 下端のシステムインセット（ホームインジケータ等）はバー側のSafeAreaが
    // 消費する。取り除かないと画面本体のSafeAreaとバーのSafeAreaで二重に
    // 余白が入り、無駄に縦幅を失う。
    //
    // 【キーボード表示時の補正】: removePaddingはpaddingしか消さないため、
    // 補正しないと画面本体は「バーの分だけ短い箱」からさらにキーボード全高を
    // 引くことになり、キーボード上端との間にバー1本分（92px）の空白帯が
    // できる。バーはキーボードの裏に完全に隠れるので、その分を差し引いた
    // viewInsetsを渡すのが正しい。
    final barTotal =
        AppSizes.emergencyButtonBarThickness + mediaQuery.padding.bottom;
    return mediaQuery.removePadding(removeBottom: true).copyWith(
          viewInsets: mediaQuery.viewInsets.copyWith(
            bottom: math.max(0.0, mediaQuery.viewInsets.bottom - barTotal),
          ),
        );
  }

  /// 緊急ボタンバーを構築する（REQ-301, REQ-302 / TASK-0045 FR-005, FR-006）
  ///
  /// 【この構成にした理由（重なり不具合の修正）】:
  /// 以前は緊急ボタンをStackで画面本体の上に「重ねて」いたため、画面右下
  /// （右16〜76px / 下16〜76px）のタップが常に緊急ボタンへ吸収されていた。
  /// 文字盤（CharacterBoardWidget）のグリッドは画面端まで伸びてスクロール
  /// するため、スマホ縦持ち・横持ちでは最右列のキーが緊急ボタンの下に入り、
  /// タップ有効面積が44px（REQ-5001）を下回るうえ、誤タップで緊急確認
  /// ダイアログが開いてしまっていた。定型文画面では追加FAB（右下）が
  /// 緊急ボタンに完全に覆われ、追加操作そのものが不能だった。
  ///
  /// そこで緊急ボタンを「重ねる」のをやめ、画面端に専用のレイアウト領域
  /// （太さ [AppSizes.emergencyButtonBarThickness] = 92px）を確保して配置する。
  /// 画面本体はこの帯のぶんだけ小さくなるため、どの画面・どの画面サイズ・
  /// どのスクロール位置であっても緊急ボタンと画面側UIが重ならない
  /// （偶然の空きセルに依存しない構造的な解決）。
  ///
  /// - [isLandscape] がtrue（横向き）なら画面右端の縦帯（幅92pxの
  ///   サイドレール）、falseなら画面下部の横帯（高さ92px）として確保する。
  ///   横向きは縦方向が貴重なため、奪う方向を切り替えて文字盤の可視行数を
  ///   維持する。
  /// - ボタン自体のサイズ・位置（右下・外周16px）はどちらの向きでも従来と
  ///   同じで、見た目の位置は変わらない。
  /// - 帯の周囲に16pxの余白が入るため、他の操作ボタンとの間隔16px以上
  ///   （FR-006）も同時に満たす。
  /// - チュートリアル表示中もTutorialOverlayは画面本体側だけを覆うため、
  ///   緊急ボタンは常に操作可能（REQ-301, REQ-302）。
  /// - 帯は各画面のScaffoldの外側に位置するため、背景が透明にならないよう
  ///   ScaffoldBackgroundColorで塗りつぶし、画面本体と地続きに見せる。
  Widget _buildEmergencyButtonBar(
    BuildContext context, {
    required bool isLandscape,
  }) {
    final button = EmergencyButtonWithConfirmation(
      size: AppSizes.emergencyButtonSize,
      onEmergencyConfirmed: () =>
          ref.read(emergencyStateProvider.notifier).startEmergency(),
    );

    return ColoredBox(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: isLandscape
          // 横向き: 画面右端の縦帯。右端・下端のセーフエリアを消費する。
          ? SafeArea(
              left: false,
              child: SizedBox(
                width: AppSizes.emergencyButtonBarThickness,
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      vertical: AppSizes.emergencyButtonMargin,
                    ),
                    child: button,
                  ),
                ),
              ),
            )
          // 縦向き: 画面下部の横帯。下端のセーフエリアを消費する。
          : SafeArea(
              top: false,
              child: SizedBox(
                height: AppSizes.emergencyButtonBarThickness,
                child: Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSizes.emergencyButtonMargin,
                    ),
                    child: button,
                  ),
                ),
              ),
            ),
    );
  }
}
