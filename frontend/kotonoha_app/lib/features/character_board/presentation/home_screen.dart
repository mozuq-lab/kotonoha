/// Home screen widget (Character Board)
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/core/router/app_router.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/models/politeness_level.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_button.dart';
import 'package:kotonoha_app/features/ai_conversion/presentation/widgets/ai_conversion_result_dialog.dart';
import 'package:kotonoha_app/features/ai_conversion/providers/ai_conversion_provider.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/face_to_face/providers/face_to_face_provider.dart';
import 'package:kotonoha_app/features/favorite/domain/models/favorite.dart';
import 'package:kotonoha_app/features/favorite/presentation/constants/favorite_ui_constants.dart';
import 'package:kotonoha_app/features/favorite/presentation/widgets/favorite_shortcut_button.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart';
import 'package:kotonoha_app/features/quick_response/domain/quick_response_type.dart';
import 'package:kotonoha_app/features/quick_response/presentation/widgets/quick_response_buttons.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/providers/settings_provider.dart';
import 'package:kotonoha_app/features/simple_mode/presentation/simple_mode_view.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_state.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/tts_button.dart';
import 'package:kotonoha_app/features/tts/presentation/widgets/volume_warning_widget.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/tts/providers/volume_warning_provider.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

/// コンパクト2ペインの幅の配分（左: 操作UI 2 / 右: 文字盤 3）
/// 2ペインにできるかの判定と実際のレイアウトで同じ値を使う。
const int _compactControlsFlex = 2;
const int _compactBoardFlex = 3;

/// 2ペインの右ペインに文字盤を置くのに要る幅
/// 文字盤自身の最小幅（5列 × 44px ＋ 列間隔 ＋ GridViewのpadding）に
/// [_buildCharacterBoard] が足す左右の余白を加えた値 = 284px。
const double _minBoardPaneWidth =
    CharacterBoardWidget.minLayoutWidth + 2 * AppSizes.paddingSmall;

/// 右ペイン幅の丸め許容（1px）
/// [_minBoardPaneWidth] を1pxまで下回っても2ペインにする。このとき
/// セル幅は44pxを最大0.2px下回る（例: 569×375の横持ちは右ペイン283.8px
/// でセル43.96px）。その画面を縦積みにすると文字盤には85pxしか渡せず
/// 2行目のセルが25pxに切れるため、0.2pxの不足より2ペインの方が使える
/// （台帳 L-155）。幅320の右ペインは189pxで、この許容では届かない。
const double _boardPaneWidthTolerance = 1.0;

/// 状態ボタン1個に要る最小幅
/// 8個を1行に並べるか、4列×2行にするかの判定に使う。
const double _minStatusButtonWidth = 80.0;

/// 縦積みで文字盤に残す高さ（カテゴリと44pxセル2行ぶん）
const double _boardReserve = 200.0;

/// 縦積みにしたとき文字盤へ渡る高さ
/// 操作群には残り（[_ScrollableHomeControls] の maxHeight）を渡す。
/// 予約を引くと負になるほど低い画面では半分ずつに分ける。これは
/// maxHeightが負の不正な制約になるのを防ぐための下限で、44pxの行が
/// 入ることは保証しない（可視高さ〜250未満では入らない。台帳 L-172）。
double _stackedBoardHeight(double availableHeight) =>
    availableHeight < _boardReserve * 2 ? availableHeight / 2 : _boardReserve;

/// ホーム画面（文字盤画面）ウィジェット
/// アプリケーションのメイン画面。文字盤入力機能を提供する。
/// 実装要件
/// 初期ルート「/」でこの画面を表示
/// 五十音配列の文字盤UI
/// タップで入力欄に文字追加
/// クイック応答ボタン（はい/いいえ/わからない）
/// TTS読み上げ機能
class HomeScreen extends ConsumerWidget {
  /// ホーム画面を作成する。
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final inputBuffer = ref.watch(inputBufferProvider);
    final settingsAsync = ref.watch(settingsNotifierProvider);
    final settings = settingsAsync.asData?.value;
    final fontSize = settings?.fontSize ?? FontSize.medium;
    final aiPoliteness = settings?.aiPoliteness ?? PolitenessLevel.normal;
    final simpleMode = settings?.simpleMode ?? false;

    // 音量ゼロ警告の配線: tts_button.dart自体は変更せず
    // グローバルなttsProviderの状態遷移(非speaking -> speaking)を横断的に
    // 監視することで、どのボタン（クイック応答・状態ボタン・読み上げボタン等）
    // から読み上げが開始されても音量チェックが行われるようにする。
    ref.listen<TTSServiceState>(ttsProvider, (previous, next) {
      final wasSpeaking = previous?.state == TTSState.speaking;
      final isSpeaking = next.state == TTSState.speaking;
      if (!wasSpeaking && isSpeaking) {
        ref.read(volumeWarningProvider.notifier).checkVolumeBeforeSpeak();
      }
    });
    final showVolumeWarning = ref.watch(volumeWarningProvider).showWarning;
    final showAppName =
        MediaQuery.sizeOf(context).width >= AppSizes.phoneMaxWidth;

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
              child: Image.asset(
                'assets/images/kotonoha_icon.png',
                key: const Key('home_app_icon'),
                width: AppSizes.iconSizeLarge,
                height: AppSizes.iconSizeLarge,
                semanticLabel: 'kotonoha',
                excludeFromSemantics: showAppName,
              ),
            ),
            if (showAppName) ...[
              const SizedBox(width: AppSizes.paddingSmall),
              const Flexible(
                child: Text('kotonoha',
                    maxLines: 1, overflow: TextOverflow.ellipsis),
              ),
            ],
          ],
        ),
        // シンプルモード: 文字盤を使わない大ボタン画面に切り替えている間は
        // 認知負荷を下げるため他のナビゲーションアイコンは表示せず
        // 通常モードへ戻すトグルアイコンのみを表示する。
        actions: simpleMode
            ? [_buildSimpleModeToggleButton(ref, simpleMode: true)]
            : [
                IconButton(
                  icon: const Icon(Icons.open_in_full),
                  tooltip: '対面表示',
                  onPressed: () => _openFaceToFace(context, ref, inputBuffer),
                ),
                IconButton(
                  icon: const Icon(Icons.format_list_bulleted),
                  tooltip: '定型文',
                  onPressed: () => context.push(AppRoutes.presetPhrases),
                ),
                IconButton(
                  icon: const Icon(Icons.history),
                  tooltip: '履歴',
                  onPressed: () => context.push(AppRoutes.history),
                ),
                IconButton(
                  icon: const Icon(Icons.favorite),
                  tooltip: 'お気に入り',
                  onPressed: () => context.push(AppRoutes.favorites),
                ),
                IconButton(
                  icon: const Icon(Icons.settings),
                  tooltip: '設定',
                  onPressed: () => context.push(AppRoutes.settings),
                ),
                _buildSimpleModeToggleButton(ref, simpleMode: false),
              ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // 音量0警告: 警告不要時はSizedBox.shrinkで高さ0のため
            // 既存レイアウトへの影響はない。シンプルモード中も表示する。
            VolumeWarningWidget(
              isVisible: showVolumeWarning,
              onDismiss: () =>
                  ref.read(volumeWarningProvider.notifier).dismissWarning(),
            ),
            Expanded(
              child: simpleMode
                  ? _buildSimpleModeContent(ref, fontSize: fontSize)
                  : LayoutBuilder(
                      builder: (context, constraints) {
                        // レスポンシブ対応: 可視高さ・幅に応じてレイアウトを切り替える。
                        // isCompactHeight: 可視高さが乏しい画面（主に横持ち）。
                        // 固定サイズのセクションを縦に積むと必要高さが可視高さを超え
                        // RenderFlexオーバーフローが発生するため、左右2ペイン構成に切替える。
                        // isPhoneWidth: 縦持ちスマホ幅（< phoneMaxWidth）。オーバーフローは
                        // しないが、各セクションをコンパクト化し文字盤の可視行数を増やす。
                        final isCompactHeight = constraints.maxHeight <
                            AppSizes.compactHeightThreshold;
                        final isPhoneWidth =
                            constraints.maxWidth < AppSizes.phoneMaxWidth;

                        // 2ペインは、右ペインに文字盤をそのまま置ける幅が
                        // あるときだけ成立する。置けない幅で2ペインにすると
                        // 五十音の5列を44pxで並べられずセルが痩せ
                        // （台帳 L-155: 幅320で25.12px）、左ペインでは告知が
                        // 横にはみ出す（台帳 L-156）。
                        final boardPaneWidth =
                            (constraints.maxWidth - AppSizes.paddingXSmall) *
                                _compactBoardFlex /
                                (_compactControlsFlex + _compactBoardFlex);
                        // 判定は幅だけで行う。可視高さが低いことを理由に
                        // 2ペインへ戻すと、幅320（右ペイン189px）で
                        // セル25.12pxを選び直してしまう（台帳 L-155 そのもの）。
                        final hasBoardPaneWidth = boardPaneWidth >=
                            _minBoardPaneWidth - _boardPaneWidthTolerance;

                        // 幅320でオフラインバナーが出ると可視高さが446pxとなり
                        // 幅が足りないので縦積みに入る。
                        if (isCompactHeight && hasBoardPaneWidth) {
                          return _buildCompactLandscapeLayout(
                            context,
                            ref,
                            inputBuffer: inputBuffer,
                            fontSize: fontSize,
                            aiPoliteness: aiPoliteness,
                            availableHeight: constraints.maxHeight,
                          );
                        }

                        return _buildStandardLayout(
                          context,
                          ref,
                          inputBuffer: inputBuffer,
                          fontSize: fontSize,
                          aiPoliteness: aiPoliteness,
                          compact: isPhoneWidth,
                          availableHeight: constraints.maxHeight,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// シンプルモードの切替トグルボタンを構築する
  /// [simpleMode] は現在シンプルモードが有効かどうか。有効な場合はアイコン
  /// tooltip（=Semanticsラベル）を「解除」用に切り替える。
  Widget _buildSimpleModeToggleButton(
    WidgetRef ref, {
    required bool simpleMode,
  }) {
    return IconButton(
      icon: Icon(
        simpleMode ? Icons.keyboard_alt_outlined : Icons.grid_view_rounded,
      ),
      tooltip: simpleMode ? 'シンプルモードを解除' : 'シンプルモードに切替',
      onPressed: () {
        ref.read(settingsNotifierProvider.notifier).setSimpleMode(!simpleMode);
      },
    );
  }

  /// シンプルモード画面の中身を構築する
  /// 文字盤を使わない大ボタン画面。クイック応答・お気に入りを
  /// 再利用し、TTS読み上げ・履歴保存はこのメソッド内のコールバックで配線する。
  Widget _buildSimpleModeContent(
    WidgetRef ref, {
    required FontSize fontSize,
  }) {
    final favorites = ref.watch(favoriteProvider).favorites;

    return SimpleModeView(
      fontSize: fontSize,
      favorites: favorites,
      onQuickResponse: (type) {
        _saveToHistory(ref, type.label, HistoryType.quickButton);
      },
      onTTSSpeak: (text) {
        ref.read(ttsProvider.notifier).speak(text);
      },
      onFavoriteTap: (favorite) {
        // 既存挙動に合わせる: FavoritesScreenのお気に入りタップと同様
        // 読み上げのみ行い、履歴への再保存は行わない。
        if (favorite.content.isEmpty) return;
        ref.read(ttsProvider.notifier).speak(favorite.content);
      },
      onExitSimpleMode: () {
        ref.read(settingsNotifierProvider.notifier).setSimpleMode(false);
      },
    );
  }

  /// 表示するテキストは、入力中のテキスト（input_buffer）を優先し
  /// 入力が空の場合は直近の読み上げ履歴（historyProvider）のテキストを使う。
  void _openFaceToFace(
      BuildContext context, WidgetRef ref, String inputBuffer) {
    final histories = ref.read(historyProvider).histories;
    final lastSpokenText = histories.isNotEmpty ? histories.first.content : '';
    final displayText = inputBuffer.isNotEmpty ? inputBuffer : lastSpokenText;

    ref.read(faceToFaceProvider.notifier).enableFaceToFace(displayText);
    context.push(AppRoutes.faceToFace, extra: displayText).whenComplete(() {
      ref.read(faceToFaceProvider.notifier).disableFaceToFace();
    });
  }

  /// 標準レイアウト（タブレット・縦持ちスマホ）
  /// 各セクションを縦に積むレイアウト。[compact] がtrue（スマホ幅）の場合は
  /// パディング・ボタン高さを圧縮し、文字盤（Expanded）の可視領域を広げる。
  Widget _buildStandardLayout(
    BuildContext context,
    WidgetRef ref, {
    required String inputBuffer,
    required FontSize fontSize,
    required PolitenessLevel aiPoliteness,
    required bool compact,
    required double availableHeight,
  }) {
    // すべての行の左右端を、クイック応答ボタンの左右端にそろえる。
    final gutter = compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;

    final controls = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // クイック応答ボタン（はい/いいえ/わからない）
        _buildQuickResponseSection(
          ref,
          fontSize: fontSize,
          padding: EdgeInsets.all(gutter),
          compact: compact,
        ),
        _buildFavoriteShortcutsSection(
          ref,
          fontSize: fontSize,
          gutter: gutter,
          compact: compact,
        ),
        // 入力表示エリア
        _buildInputArea(
          context,
          ref: ref,
          inputBuffer: inputBuffer,
          fontSize: fontSize,
          compact: compact,
          availableHeight: availableHeight,
        ),
        // 操作ボタン（削除、全消去、AI変換、読み上げ）
        _buildControlRow(
          context,
          ref,
          inputBuffer: inputBuffer,
          aiPoliteness: aiPoliteness,
          gutter: gutter,
          compact: compact,
        ),
        const SizedBox(height: AppSizes.paddingSmall),
      ],
    );
    // 文字盤に残す高さ（[_stackedBoardHeight]）を引いた残りを操作域へ渡し
    // 上部の超過分だけをそのスクロールへ移す。
    final controlsMaxHeight =
        availableHeight - _stackedBoardHeight(availableHeight);
    return Column(
      children: [
        _ScrollableHomeControls(maxHeight: controlsMaxHeight, child: controls),
        Expanded(child: _buildCharacterBoard(ref, fontSize: fontSize)),
      ],
    );
  }

  /// コンパクト2ペインレイアウト（可視高さが乏しく、かつ右ペインに文字盤を
  /// 置ける幅がある場合。主に横持ち）
  /// 縦積みだと固定セクションの必要高さが可視高さを超えRenderFlex
  /// オーバーフローが発生するため、左ペイン（各種操作UI・スクロール可）と
  /// 右ペイン（文字盤、残り全高さをExpandedで使用）の横並びに切り替える。
  /// アプリの主機能である文字盤が消えてしまう不具合を解消する。
  /// 幅の配分は [_compactControlsFlex] : [_compactBoardFlex]。右ペインが
  /// [_minBoardPaneWidth] を下回る幅では呼ばれない（台帳 L-155・L-156）。
  Widget _buildCompactLandscapeLayout(
    BuildContext context,
    WidgetRef ref, {
    required String inputBuffer,
    required FontSize fontSize,
    required PolitenessLevel aiPoliteness,
    required double availableHeight,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 左ペイン: 操作UI一式（スクロール可能にしてオーバーフローを防止）
        Expanded(
          flex: _compactControlsFlex,
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(
              vertical: AppSizes.paddingXSmall,
            ),
            child: Column(
              children: [
                _buildQuickResponseSection(
                  ref,
                  fontSize: fontSize,
                  padding: const EdgeInsets.symmetric(
                    horizontal: AppSizes.paddingSmall,
                    vertical: AppSizes.paddingXSmall,
                  ),
                  compact: true,
                ),
                _buildFavoriteShortcutsSection(
                  ref,
                  fontSize: fontSize,
                  gutter: AppSizes.paddingSmall,
                  compact: true,
                ),
                _buildInputArea(
                  context,
                  ref: ref,
                  inputBuffer: inputBuffer,
                  fontSize: fontSize,
                  compact: true,
                  availableHeight: availableHeight,
                ),
                _buildControlRow(
                  context,
                  ref,
                  inputBuffer: inputBuffer,
                  aiPoliteness: aiPoliteness,
                  gutter: AppSizes.paddingSmall,
                  compact: true,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(width: AppSizes.paddingXSmall),
        // 右ペイン: 文字盤（主機能。残り全高さを使用する）
        Expanded(
          flex: _compactBoardFlex,
          child: _buildCharacterBoard(ref, fontSize: fontSize),
        ),
      ],
    );
  }

  /// クイック応答ボタンセクションを構築する
  /// バグ修正: 従来はonResponse内でもTTS読み上げを行っていたため
  /// onTTSSpeak（読み上げ実行）と合わせて1タップでspeakが二重に
  /// 呼ばれていた。読み上げはonTTSSpeakのみに一本化し、onResponseは
  /// 履歴保存のみを担当するようにした。
  /// バグ修正: 履歴種類が誤ってHistoryType.manualInput（文字盤入力）に
  /// なっていたため、大ボタン相当のHistoryType.quickButtonに修正した
  /// （履歴画面でのアイコン・スクリーンリーダー表示の誤りを解消）。
  Widget _buildQuickResponseSection(
    WidgetRef ref, {
    required FontSize fontSize,
    required EdgeInsets padding,
    required bool compact,
  }) {
    return Padding(
      padding: padding,
      child: QuickResponseButtons(
        onResponse: (type) {
          _saveToHistory(ref, type.label, HistoryType.quickButton);
        },
        onTTSSpeak: (text) {
          ref.read(ttsProvider.notifier).speak(text);
        },
        fontSize: fontSize,
        buttonHeight:
            compact ? AppSizes.quickResponseButtonHeightCompact : null,
      ),
    );
  }

  /// 表示順上位8件のお気に入りを、スワイプなしで並べる。
  Widget _buildFavoriteShortcutsSection(
    WidgetRef ref, {
    required FontSize fontSize,
    required double gutter,
    required bool compact,
  }) {
    const gap = AppSizes.paddingSmall;
    final height =
        compact ? AppSizes.minTapTarget : AppSizes.recommendedTapTarget;
    final favorites = List<Favorite>.from(ref.watch(favoriteProvider).favorites)
      ..sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    final shortcuts = favorites.take(8).toList();
    if (shortcuts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final count = shortcuts.length;
          bool fits(int columns, double minWidth) =>
              constraints.maxWidth >= columns * minWidth + (columns - 1) * gap;
          // 2ペインの狭い左ペインでも1個44px以上を保つよう、列を減らす。
          final columns = fits(count, _minStatusButtonWidth)
              ? count
              : fits(count < 4 ? count : 4, AppSizes.minTapTarget)
                  ? (count < 4 ? count : 4)
                  : fits(2, AppSizes.minTapTarget)
                      ? 2
                      : 1;
          Widget button(Favorite favorite) => Expanded(
                child: FavoriteShortcutButton(
                  favorite: favorite,
                  height: height,
                  fontSize: fontSize,
                  onPressed: () {
                    ref.read(ttsProvider.notifier).speak(favorite.content);
                    _saveToHistory(
                      ref,
                      favorite.content,
                      HistoryType.quickButton,
                    );
                  },
                ),
              );
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              for (var start = 0; start < count; start += columns) ...[
                if (start > 0) const SizedBox(height: gap),
                Row(
                  children: [
                    for (var i = start;
                        i < start + columns && i < count;
                        i++) ...[
                      if (i > start) const SizedBox(width: gap),
                      button(shortcuts[i]),
                    ],
                  ],
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  /// 入力表示エリアを構築する
  /// 長文（最大1000文字）入力時に文字盤エリアを圧迫しないよう
  /// 可視高さの約20%を上限（maxHeight）とし、内部をSingleChildScrollView
  /// （reverse: true）にすることで、超過分は末尾（最新入力）が見える形で
  /// スクロール可能にする。
  Widget _buildInputArea(
    BuildContext context, {
    required WidgetRef ref,
    required String inputBuffer,
    required FontSize fontSize,
    required bool compact,
    required double availableHeight,
  }) {
    final minHeight = compact
        ? AppSizes.inputAreaMinHeightCompact
        : AppSizes.inputAreaMinHeightStandard;
    final ratioBasedMaxHeight = availableHeight.isFinite
        ? availableHeight * AppSizes.inputAreaMaxHeightRatio
        : double.infinity;
    final maxHeight =
        ratioBasedMaxHeight > minHeight ? ratioBasedMaxHeight : minHeight;
    final horizontalMargin =
        compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;
    final contentPadding =
        compact ? AppSizes.paddingSmall : AppSizes.paddingMedium;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          key: const Key('home_input_area'),
          width: double.infinity,
          margin: EdgeInsets.symmetric(
            horizontal: horizontalMargin,
            vertical: AppSizes.paddingSmall,
          ),
          padding: EdgeInsets.all(contentPadding),
          decoration: BoxDecoration(
            border: Border.all(
              color: Theme.of(context).colorScheme.outline,
            ),
            borderRadius: BorderRadius.circular(AppSizes.borderRadiusMedium),
          ),
          constraints:
              BoxConstraints(minHeight: minHeight, maxHeight: maxHeight),
          child: HomeInputField(
            fontSize: fontSize,
            onFavoritePressed: () =>
                _addInputToFavorites(context, ref, inputBuffer),
          ),
        ),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: horizontalMargin),
          child: const InputLimitNotice(),
        ),
      ],
    );
  }

  Future<void> _addInputToFavorites(
    BuildContext context,
    WidgetRef ref,
    String content,
  ) async {
    if (content.trim().isEmpty) return;
    final exists = ref
        .read(favoriteProvider)
        .favorites
        .any((favorite) => favorite.content == content);
    if (exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('すでにお気に入りに登録されています')),
      );
      return;
    }
    final saved =
        await ref.read(favoriteProvider.notifier).addFavorite(content);
    if (!context.mounted) return;
    final registered = ref
        .read(favoriteProvider)
        .favorites
        .any((favorite) => favorite.content == content);
    final temporary =
        registered && ref.read(favoriteRepositoryProvider) == null;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(saved
            ? 'お気に入りに登録しました'
            : temporary
                ? FavoriteUIConstants.temporaryRegistrationMessage
                : registered
                    ? 'すでにお気に入りに登録されています'
                    : FavoriteUIConstants.saveFailureMessage),
        backgroundColor: !registered || temporary
            ? Theme.of(context).colorScheme.error
            : null,
      ),
    );
  }

  /// 操作ボタン行（削除・全消去・AI変換・読み上げ）を構築する
  /// 幅に余裕がある場合は1行（左に削除・全消去、右にAI変換・読み上げ）で
  /// 表示し、コンパクト2ペインの左ペインや大きい文字のように幅が不足する
  /// 場合は、スワイプ操作を必要とせず2行に折り返して収める。
  /// オフラインでAI変換が使えないことは、ボタンの幅を広げて並びを
  /// 崩さないよう、行の下に右寄せで出す。
  Widget _buildControlRow(
    BuildContext context,
    WidgetRef ref, {
    required String inputBuffer,
    required PolitenessLevel aiPoliteness,
    required double gutter,
    required bool compact,
  }) {
    const gap = AppSizes.paddingSmall;
    final height = compact
        ? AppSizes.quickResponseButtonHeightCompact
        : AppSizes.recommendedTapTarget;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: gutter),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            // 片方のグループが折り返しても、もう片方を上端にそろえる。
            crossAxisAlignment: WrapCrossAlignment.start,
            spacing: gap,
            runSpacing: gap,
            children: [
              // 内側のグループもWrapにする。外側のWrapは子をまたぐ折り返し
              // しか制御せず、2ボタン分の幅すら無い極端に狭い幅では
              // 単一の子の中でオーバーフローするため。
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  DeleteButton(
                    size: height,
                    enabled: inputBuffer.isNotEmpty,
                    onPressed: () {
                      ref
                          .read(inputBufferProvider.notifier)
                          .deleteLastCharacter();
                    },
                  ),
                  ClearAllButton(
                    size: height,
                    enabled: inputBuffer.isNotEmpty,
                    onConfirmed: () {
                      ref.read(inputBufferProvider.notifier).clear();
                    },
                  ),
                ],
              ),
              Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  AIConversionButton(
                    inputText: inputBuffer,
                    politenessLevel: aiPoliteness,
                    height: height,
                    onConvert: () => _convertWithAI(
                      context,
                      ref,
                      inputBuffer,
                      aiPoliteness,
                    ),
                    onConversionComplete: (convertedText) {
                      if (!context.mounted) return;
                      _showConversionResult(
                        context,
                        ref,
                        inputBuffer,
                        convertedText,
                        aiPoliteness,
                      );
                    },
                    onConversionError: (error) {
                      if (!context.mounted) return;
                      _showAIConversionError(context, error);
                    },
                  ),
                  TTSButton(
                    text: inputBuffer,
                    height: height,
                    onSpeak: () {
                      if (inputBuffer.isNotEmpty) {
                        _saveToHistory(
                            ref, inputBuffer, HistoryType.manualInput);
                      }
                    },
                  ),
                ],
              ),
            ],
          ),
          // 文字数不足の案内は出さない。入力のたびに出入りして行の高さが
          // 変わり、押そうとした文字盤のキーが指の下で動いてしまうため。
          const Padding(
            padding: EdgeInsets.only(top: AppSizes.paddingXSmall),
            child: Align(
              alignment: Alignment.centerRight,
              child: OfflineIndicator(),
            ),
          ),
        ],
      ),
    );
  }

  /// 文字盤セクションを構築する
  Widget _buildCharacterBoard(
    WidgetRef ref, {
    required FontSize fontSize,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSizes.paddingSmall,
      ),
      child: CharacterBoardWidget(
        onCharacterTap: (character) {
          // 濁点・半濁点キー対応: 通常の文字追加ではなく、入力バッファ末尾の
          // 文字を濁音/半濁音に変換する専用処理を呼び出す（3タップ問題の解消）。
          // 空白キーは全角スペース文字そのものが渡ってくるため、通常のaddCharacter
          // でそのまま追加できる。
          final notifier = ref.read(inputBufferProvider.notifier);
          if (CharacterData.isDakutenKey(character)) {
            notifier.applyDakuten();
          } else if (CharacterData.isHandakutenKey(character)) {
            notifier.applyHandakuten();
          } else {
            notifier.addCharacter(character);
          }
        },
        fontSize: fontSize,
      ),
    );
  }

  /// 履歴に保存する
  /// バグ修正: 従来は常にHistoryType.manualInput固定で保存していたため
  /// クイック応答・状態ボタン経由の履歴も「文字盤入力」として記録され
  /// 履歴画面のアイコン・スクリーンリーダー読み上げが実態と異なっていた。
  /// 呼び出し元ごとに適切な[type]を指定できるようにした
  /// （文字盤入力: HistoryType.manualInput、クイック応答・状態ボタン
  /// HistoryType.quickButton）。
  void _saveToHistory(WidgetRef ref, String text, HistoryType type) {
    ref.read(historyProvider.notifier).addHistory(text, type);
  }

  Future<String> _convertWithAI(
    BuildContext context,
    WidgetRef ref,
    String inputText,
    PolitenessLevel politenessLevel,
  ) async {
    final hasConsent = await _ensureAIPrivacyConsent(context, ref);
    if (!hasConsent) {
      throw const AIConversionException(
        code: 'PRIVACY_CONSENT_REQUIRED',
        message: 'AI変換を利用するにはプライバシー同意が必要です。',
      );
    }

    await ref.read(aiConversionProvider.notifier).convert(
          inputText: inputText,
          politenessLevel: politenessLevel,
        );

    final state = ref.read(aiConversionProvider);
    if (state.hasResult && state.convertedText != null) {
      return state.convertedText!;
    }

    throw state.error ??
        const AIConversionException(
          code: 'AI_CONVERSION_FAILED',
          message: 'AI変換に失敗しました。しばらく待ってから再度お試しください。',
        );
  }

  Future<String> _regenerateWithAI(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final hasConsent = await _ensureAIPrivacyConsent(context, ref);
    if (!hasConsent) {
      throw const AIConversionException(
        code: 'PRIVACY_CONSENT_REQUIRED',
        message: 'AI変換を利用するにはプライバシー同意が必要です。',
      );
    }

    await ref.read(aiConversionProvider.notifier).regenerate();

    final state = ref.read(aiConversionProvider);
    if (state.hasResult && state.convertedText != null) {
      return state.convertedText!;
    }

    throw state.error ??
        const AIConversionException(
          code: 'AI_REGENERATION_FAILED',
          message: 'AI再生成に失敗しました。しばらく待ってから再度お試しください。',
        );
  }

  Future<bool> _ensureAIPrivacyConsent(
    BuildContext context,
    WidgetRef ref,
  ) async {
    final loadedSettings = ref.read(settingsNotifierProvider).asData?.value;
    final settings =
        loadedSettings ?? await ref.read(settingsNotifierProvider.future);
    if (settings == null) return false;
    if (settings.hasAcceptedAIPrivacyPolicy) return true;
    if (!context.mounted) return false;

    final accepted = await showDialog<bool>(
          context: context,
          barrierDismissible: false,
          // データを消す操作ではないので destructive ではないが、
          // 外部送信への同意なので誤タップは避ける（台帳 L-130）
          builder: (dialogContext) => ConfirmationDialog(
            title: 'AI変換の利用確認',
            message: 'AI変換では入力した文章を外部のAIサービスへ送信します。'
                '送信前に内容を確認し、同意できる場合のみ利用してください。',
            cancelLabel: '同意しない',
            confirmLabel: '同意して利用',
            kind: ConfirmKind.normal,
            onCancel: () => Navigator.of(dialogContext).pop(false),
            onConfirm: () => Navigator.of(dialogContext).pop(true),
          ),
        ) ??
        false;

    if (accepted) {
      await ref
          .read(settingsNotifierProvider.notifier)
          .setAIPrivacyConsent(true);
    }
    return accepted;
  }

  void _showConversionResult(
    BuildContext context,
    WidgetRef ref,
    String originalText,
    String convertedText,
    PolitenessLevel politenessLevel,
  ) {
    // 注意ダイアログのクローズはAIConversionResultDialog.show内部で
    // dialogContext（root Navigator）を使って行われるため、ここで
    // Navigator.of(context).popを呼んではならない。
    // 呼び出し元contextはShellRoute配下のbranch Navigatorに属し、popすると
    // ダイアログではなく背後のページが閉じられてしまう。
    AIConversionResultDialog.show(
      context: context,
      originalText: originalText,
      convertedText: convertedText,
      politenessLevel: politenessLevel,
      onAdopt: (result) {
        ref.read(inputBufferProvider.notifier).setText(result);
      },
      onRegenerate: () {
        Future<void>.microtask(() async {
          if (!context.mounted) return;
          try {
            final result = await _regenerateWithAI(context, ref);
            if (!context.mounted) return;
            // ダイアログ内で丁寧さを選び直していれば、再生成もその丁寧さで
            // 行われる（aiConversionProvider が最後の丁寧さを持つ）。
            _showConversionResult(
              context,
              ref,
              originalText,
              result,
              ref.read(aiConversionProvider).politenessLevel ?? politenessLevel,
            );
          } catch (e) {
            if (context.mounted) {
              _showAIConversionError(context, e);
            }
          }
        });
      },
      onUseOriginal: (original) {
        ref.read(inputBufferProvider.notifier).setText(original);
      },
      onLevelChanged: (level) {
        // 選び直した丁寧さを次回の既定にし、その丁寧さで変換し直す。
        // 結果はダイアログ内で差し替わる（ダイアログは閉じない）。
        ref.read(settingsNotifierProvider.notifier).setAIPoliteness(level);
        return _convertWithAI(context, ref, originalText, level);
      },
    );
  }

  void _showAIConversionError(BuildContext context, Object error) {
    if (error is AIConversionException &&
        error.code == 'PRIVACY_CONSENT_REQUIRED') {
      return;
    }

    final message = error is AIConversionException
        ? error.message
        : 'AI変換に失敗しました。しばらく待ってから再度お試しください。';
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

/// 操作群が収まらない場合だけ、固定した上下ボタンで移動できる領域。
class _ScrollableHomeControls extends StatefulWidget {
  const _ScrollableHomeControls({required this.maxHeight, required this.child});

  final double maxHeight;
  final Widget child;

  @override
  State<_ScrollableHomeControls> createState() =>
      _ScrollableHomeControlsState();
}

class _ScrollableHomeControlsState extends State<_ScrollableHomeControls> {
  static const _buttonHeight = 48.0;
  final _controller = ScrollController();
  bool _overflow = false;
  bool _canUp = false;
  bool _canDown = false;
  bool _scheduled = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_scheduleUpdate);
  }

  void _scheduleUpdate() {
    if (_scheduled) return;
    _scheduled = true;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scheduled = false;
      if (!mounted || !_controller.hasClients) return;
      final position = _controller.position;
      // 補助を除いた高さに収まれば消す。表示後のviewportだけでは残り続ける。
      final overflow =
          position.maxScrollExtent > (_overflow ? _buttonHeight : 0) + 0.5;
      final canUp = position.extentBefore > 0.5;
      final canDown = position.extentAfter > 0.5;
      if (overflow != _overflow || canUp != _canUp || canDown != _canDown) {
        setState(() {
          _overflow = overflow;
          _canUp = canUp;
          _canDown = canDown;
        });
      }
    });
  }

  void _move(int direction) {
    final position = _controller.position;
    // 停止位置の間に操作が隠れないよう、半画面ずつ重ねて移動する。
    _controller.animateTo(
      (position.pixels + direction * position.viewportDimension / 2)
          .clamp(position.minScrollExtent, position.maxScrollExtent),
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOut,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => ConstrainedBox(
        constraints: BoxConstraints(maxHeight: widget.maxHeight),
        child: NotificationListener<ScrollMetricsNotification>(
          onNotification: (notification) {
            if (notification.depth == 0) _scheduleUpdate();
            return false;
          },
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Flexible(
                child: SingleChildScrollView(
                  key: const ValueKey('home-controls-scroll'),
                  controller: _controller,
                  child: widget.child,
                ),
              ),
              if (_overflow)
                SizedBox(
                  height: _buttonHeight,
                  child: Row(
                    children: [
                      for (final direction in [-1, 1])
                        Expanded(
                          child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                              minimumSize: const Size(44, 44),
                              padding: EdgeInsets.zero,
                            ),
                            onPressed: (direction < 0 ? _canUp : _canDown)
                                ? () => _move(direction)
                                : null,
                            child: Text(direction < 0 ? '上へ' : '下へ'),
                          ),
                        ),
                    ],
                  ),
                ),
            ],
          ),
        ),
      );
}
