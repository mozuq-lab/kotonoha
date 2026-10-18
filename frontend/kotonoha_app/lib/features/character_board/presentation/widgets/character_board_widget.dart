/// 五十音文字盤ウィジェット
library;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 五十音文字盤ウィジェット
/// 五十音配列の文字盤UIを表示し、ユーザーがタップした文字を
/// コールバック経由で返却する。
/// 実装要件
/// 五十音配列の文字盤UI表示
/// タップで入力欄に文字追加
/// タップターゲット44px × 44px以上
/// 100ms以内の応答
/// 推奨60px × 60px以上
class CharacterBoardWidget extends StatefulWidget {
  /// 文字盤ウィジェットを作成する。
  /// [onCharacterTap] - 文字タップ時のコールバック（必須）
  /// [fontSize] - フォントサイズ設定（デフォルト: medium）
  /// [isEnabled] - 有効/無効状態（デフォルト: true）
  /// [initialCategory] - 初期表示カテゴリ（デフォルト: basic）
  const CharacterBoardWidget({
    super.key,
    required this.onCharacterTap,
    this.fontSize = FontSize.medium,
    this.isEnabled = true,
    this.initialCategory = CharacterCategory.basic,
  });

  /// 文字タップ時のコールバック
  final void Function(String character) onCharacterTap;

  /// フォントサイズ設定
  final FontSize fontSize;

  /// 有効/無効状態
  final bool isEnabled;

  /// 初期表示カテゴリ
  final CharacterCategory initialCategory;

  /// 五十音表の最低列数
  /// [CharacterData] の各カテゴリは5列の表で、や行・わ行の空きセルに
  /// 濁点・半濁点・空白キーを差してある。これを下回る列数で並べると
  /// 行・段の対応と特殊キーの位置が崩れるため、下限として扱う。
  static const int minColumns = 5;

  /// 最低列数をタップ目標（44px）で並べるのに要る幅
  /// 内訳: 5列 × 44px ＋ 列間隔 4 × 8px ＋ GridViewの左右padding 2 × 8px
  /// = 268px。これを下回る幅を渡すとセルが44px未満に痩せる（台帳 L-155）。
  /// 呼び出し側は、自分が文字盤の外に足す余白を加えて判断する。
  static const double minLayoutWidth = minColumns * AppSizes.minTapTarget +
      (minColumns - 1) * AppSizes.characterBoardButtonSpacing +
      2 * AppSizes.paddingSmall;

  @override
  State<CharacterBoardWidget> createState() => _CharacterBoardWidgetState();
}

class _CharacterBoardWidgetState extends State<CharacterBoardWidget> {
  late CharacterCategory _currentCategory;

  @override
  void initState() {
    super.initState();
    _currentCategory = widget.initialCategory;
  }

  @override
  Widget build(BuildContext context) {
    final characters = CharacterData.getCharacters(_currentCategory);
    final buttonSize = AppSizes.characterBoardButtonSize;

    final board = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // カテゴリタブ
        _buildCategoryTabs(context),
        const SizedBox(height: AppSizes.paddingSmall),
        // 文字グリッド
        Expanded(
          child: _buildCharacterGrid(context, characters, buttonSize),
        ),
      ],
    );
    // 横向きの電話でキーボードが出ると、文字盤に残る高さはタブにも足りない
    // （915×412 で 46px）。そのときは最低限の高さで組み、文字盤ごとスクロールさせる。
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxHeight >= _minBoardHeight) return board;
        return SingleChildScrollView(
          child: SizedBox(height: _minBoardHeight, child: board),
        );
      },
    );
  }

  /// 文字種タブ（48）＋間（8）＋キー 1 行（44）。これより低いと組めない
  static const double _minBoardHeight = 100;

  /// キーの高さの上限（幅に対する倍率）。これより縦長にはしない
  static const double _maxCellHeightRatio = 1.75;

  /// 10 列のとき、5 列ずつの間に置く隙間。iPad では 1 列に 2 行分（あいうえお｜
  /// かきくけこ）が並び、行の区切りがわかりにくかった（人の依頼、2026-10-18）
  static const double _rowGroupGap = 24;

  /// 5 列のとき、行ごとに交互に混ぜる基本色の割合。iPhone では 1 列＝1 行なので、
  /// どの列が何行目かを目で追えるよう、ごく淡い縞にする（人の依頼、2026-10-18）
  static const double _rowStripe = 0.06;

  /// 文字種の切り替え（基本・濁音・半濁音・小文字・記号）
  /// 横スクロールにすると狭い画面で右端のラベルが切れて見えるため、
  /// 5つを等幅の1行に並べる。長いラベルは折り返さずに縮めて1行に保つ。
  /// 選択中はタブ全体を塗り、太字・太い下線でも示す。
  Widget _buildCategoryTabs(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: CharacterCategory.values.map((category) {
        final isSelected = category == _currentCategory;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppSizes.paddingXSmall,
            ),
            child: ChoiceChip(
              showCheckmark: false,
              selectedColor: scheme.primary,
              backgroundColor: scheme.surface,
              side: isSelected
                  ? BorderSide(color: scheme.primary, width: 2)
                  : BorderSide.none,
              shape: RoundedRectangleBorder(
                borderRadius:
                    BorderRadius.circular(AppSizes.borderRadiusMedium),
              ),
              labelPadding: EdgeInsets.zero,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingXSmall,
              ),
              label: SizedBox(
                width: double.infinity,
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: Text(
                    category.displayName,
                    style: TextStyle(
                      color: isSelected ? scheme.onPrimary : scheme.onSurface,
                      fontWeight: isSelected ? FontWeight.bold : null,
                      decoration: isSelected ? TextDecoration.underline : null,
                      decorationThickness: isSelected ? 2 : null,
                    ),
                  ),
                ),
              ),
              selected: isSelected,
              onSelected: widget.isEnabled
                  ? (selected) {
                      if (selected) {
                        setState(() {
                          _currentCategory = category;
                        });
                      }
                    }
                  : null,
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCharacterGrid(
    BuildContext context,
    List<String> characters,
    double buttonSize,
  ) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // 横幅に応じて列数を 5 か 10 にする（最低5列＝[CharacterBoardWidget.minColumns]）。
        // 文字の並びはどの文字種も 5 列前提（や行・わ行の空きの位置も含む）。
        // 6〜9 列にすると「あいうえお」の段に「か」がはみ出し、行がずれる。
        final spacing = AppSizes.characterBoardButtonSpacing;
        final availableWidth = constraints.maxWidth;
        final availableHeight = constraints.maxHeight;
        final columnsCount = (availableWidth / (buttonSize + spacing)).floor();
        final columns =
            columnsCount >= 10 ? 10 : CharacterBoardWidget.minColumns;

        // セルの高さ: 幅で決まるセル（widthBasedCellSize）を基準に、縦に余裕があれば
        // 最大 [_maxCellHeightRatio] 倍まで伸ばして空いた高さを使う（タブレット）。
        // 足りなければ押し縮める（電話の縦持ち）が、44px 未満には縮めず
        // GridView のスクロールに委ねる（タップターゲット下限）。
        // 行数はどの文字種でも基本（五十音）の行数で数え、タブを切り替えても
        // キーの大きさを変えない。
        const gridPadding = AppSizes.paddingSmall;
        final rows = [
          (characters.length / columns).ceil(),
          (CharacterData.basic.length / columns).ceil(),
        ].reduce((a, b) => a > b ? a : b);

        final contentWidth = availableWidth - gridPadding * 2;
        final groupGap = columns == 10 ? _rowGroupGap : 0.0;
        final widthBasedCellSize = columns > 0
            ? (contentWidth - spacing * (columns - 1) - groupGap) / columns
            : buttonSize;

        double heightBasedCellSize = widthBasedCellSize;
        if (rows > 0 && availableHeight.isFinite) {
          final contentHeight = availableHeight - gridPadding * 2;
          heightBasedCellSize = (contentHeight - spacing * (rows - 1)) / rows;
        }

        final effectiveCellHeight = heightBasedCellSize
            .clamp(
              AppSizes.minTapTarget,
              widthBasedCellSize * _maxCellHeightRatio < AppSizes.minTapTarget
                  ? AppSizes.minTapTarget
                  : widthBasedCellSize * _maxCellHeightRatio,
            )
            .toDouble();

        final childAspectRatio =
            (widthBasedCellSize > 0 && effectiveCellHeight > 0)
                ? widthBasedCellSize / effectiveCellHeight
                : 1.0;

        return GridView.builder(
          padding: const EdgeInsets.all(AppSizes.paddingSmall),
          gridDelegate: _GroupedGridDelegate(
            crossAxisCount: columns,
            spacing: spacing,
            groupGap: groupGap,
            childAspectRatio: childAspectRatio,
          ),
          itemCount: characters.length,
          itemBuilder: (context, index) {
            final character = characters[index];
            if (character.isEmpty) {
              // 空のスペーサー（constで最適化）
              return const SizedBox.shrink();
            }
            // RepaintBoundaryで個別ボタンの再描画範囲を限定
            // タップ時に該当ボタンのみ再描画し、他のボタンへの影響を最小化
            // 5 列のときは、行（あ行・か行…）ごとに淡い色と白を交互にする。
            // 高コントラストは白黒の見やすさを優先して色を付けない
            final scheme = Theme.of(context).colorScheme;
            final stripe = columns == 5 &&
                    (index ~/ 5).isEven &&
                    scheme.primary != Colors.black
                ? Color.lerp(
                    scheme.surfaceContainerLow, scheme.primary, _rowStripe)
                : null;
            return RepaintBoundary(
              child: CharacterButton(
                key: ValueKey('character_button_$character'),
                face: stripe,
                character: character,
                displayLabel: CharacterData.getDisplayLabel(character),
                accessibilityLabel:
                    CharacterData.getAccessibilityLabel(character),
                onTap: widget.isEnabled
                    ? () => widget.onCharacterTap(character)
                    : null,
                size: buttonSize,
                isEnabled: widget.isEnabled,
                fontSize: widget.fontSize,
              ),
            );
          },
        );
      },
    );
  }
}

/// 文字ボタンウィジェット
/// 個々の文字を表示するボタン。タップ時にコールバックを呼び出す。
/// 実装要件
/// タップターゲット44px × 44px以上
/// 推奨60px × 60px以上
class CharacterButton extends StatelessWidget {
  /// 文字ボタンを作成する。
  /// [character] - 表示する文字（タップ時にコールバックへ渡す値）
  /// [onTap] - タップ時のコールバック
  /// [size] - ボタンサイズ（デフォルト: 60.0）
  /// [isEnabled] - 有効/無効状態（デフォルト: true）
  /// [fontSize] - フォントサイズ設定（デフォルト: medium）
  /// [displayLabel] - ボタンに表示するラベル（省略時は[character]をそのまま表示）
  /// [accessibilityLabel] - スクリーンリーダー用ラベル（省略時は[character]を使用）
  const CharacterButton({
    super.key,
    this.face,
    required this.character,
    required this.onTap,
    this.size = 60.0,
    this.isEnabled = true,
    this.fontSize = FontSize.medium,
    this.displayLabel,
    this.accessibilityLabel,
  });

  /// 表示する文字（タップ時にコールバックへ渡す値）
  final String character;

  /// タップ時のコールバック
  final VoidCallback? onTap;

  /// ボタンサイズ
  final double size;

  /// 有効/無効状態
  final bool isEnabled;

  /// フォントサイズ設定
  final FontSize fontSize;

  /// ボタンに表示するラベル（濁点・半濁点・空白キー等の特殊表示用）
  /// nullの場合は[character]をそのまま表示する。
  final String? displayLabel;

  /// スクリーンリーダー用ラベル（濁点・半濁点・空白キー等の特殊表示用）
  /// nullの場合は[character]をそのまま使用する。
  final String? accessibilityLabel;

  /// キーの面の色。null ならいつもの面（[ColorScheme.surfaceContainerLow]）
  final Color? face;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textSize = _getTextSize();
    // BorderRadiusを共通化してインスタンス生成を削減
    const borderRadius = BorderRadius.all(
      Radius.circular(AppSizes.borderRadiusMedium),
    );

    return Semantics(
      label: accessibilityLabel ?? character,
      button: true,
      enabled: isEnabled,
      child: SizedBox(
        width: size,
        height: size,
        child: Material(
          // 背景より一段明るい面に置き、影は付けない（縁で境界を示す）
          color: isEnabled
              ? (face ?? theme.colorScheme.surfaceContainerLow)
              : theme.colorScheme.surfaceContainerLow.withValues(alpha: 0.5),
          borderRadius: borderRadius,
          child: InkWell(
            onTap: isEnabled ? onTap : null,
            borderRadius: borderRadius,
            child: Container(
              decoration: BoxDecoration(
                border: Border.all(
                  color: isEnabled
                      ? theme.colorScheme.outline
                      : theme.colorScheme.outline.withValues(alpha: 0.3),
                ),
                borderRadius: borderRadius,
              ),
              alignment: Alignment.center,
              padding: const EdgeInsets.all(AppSizes.paddingXSmall),
              // 文字はキーの大きさに合わせて大きくする（タブレットで大きな
              // キーに小さな文字が浮かないように）。設定の大きさは倍率と下限になる。
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final shortSide = constraints.biggest.shortestSide.isFinite
                      ? constraints.biggest.shortestSide
                      : 0.0;
                  final scaled = shortSide * _textRatio();
                  final size = scaled > textSize ? scaled : textSize;
                  // 「゛」「゜」は字面の左上に寄った小さな記号なので、
                  // 大きくして中央へ寄せる
                  final isMark = CharacterData.isDakutenKey(character) ||
                      CharacterData.isHandakutenKey(character);
                  // 読み上げは外側の Semantics の名前だけにする。描いた文字も
                  // 読ませると名前に合流し「あ、あ、ボタン」と 2 回読まれる
                  // （物理 iPad の VoiceOver、2026-10-17）
                  final label = ExcludeSemantics(
                      child: Text(
                    displayLabel ?? character,
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontSize: isMark ? size * 1.5 : size,
                      color: isEnabled
                          ? theme.colorScheme.onSurface
                          : theme.colorScheme.onSurface.withValues(alpha: 0.5),
                    ),
                  ));
                  return FittedBox(
                    fit: BoxFit.scaleDown,
                    child: isMark
                        ? Transform.translate(
                            offset: Offset(size * 0.3, size * 0.35),
                            child: label,
                          )
                        : label,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// キーの短い辺に対する文字の大きさ
  double _textRatio() => switch (fontSize) {
        FontSize.small => 0.34,
        FontSize.medium => 0.42,
        FontSize.large => 0.5,
      };

  double _getTextSize() {
    switch (fontSize) {
      case FontSize.small:
        return AppSizes.fontSizeSmall;
      case FontSize.medium:
        return AppSizes.fontSizeMedium;
      case FontSize.large:
        return AppSizes.fontSizeLarge;
    }
  }
}

/// 列数が決まったグリッドで、10 列のときだけ 5 列ずつの間に [groupGap] の隙間を置く。
/// キーの幅は隙間の分だけ全員を等しく狭くする（隙間に接するキーだけ細くしない）。
class _GroupedGridDelegate extends SliverGridDelegateWithFixedCrossAxisCount {
  const _GroupedGridDelegate({
    required super.crossAxisCount,
    required double spacing,
    required this.groupGap,
    required super.childAspectRatio,
  }) : super(mainAxisSpacing: spacing, crossAxisSpacing: spacing);

  final double groupGap;

  @override
  SliverGridLayout getLayout(SliverConstraints constraints) {
    final usable = constraints.crossAxisExtent -
        crossAxisSpacing * (crossAxisCount - 1) -
        groupGap;
    final width = usable > 0 ? usable / crossAxisCount : 0.0;
    final height = width / childAspectRatio;
    return _GroupedGridLayout(
      crossAxisCount: crossAxisCount,
      mainAxisStride: height + mainAxisSpacing,
      crossAxisStride: width + crossAxisSpacing,
      childMainAxisExtent: height,
      childCrossAxisExtent: width,
      reverseCrossAxis: axisDirectionIsReversed(constraints.crossAxisDirection),
      groupGap: groupGap,
    );
  }

  @override
  bool shouldRelayout(_GroupedGridDelegate oldDelegate) =>
      super.shouldRelayout(oldDelegate) || oldDelegate.groupGap != groupGap;
}

class _GroupedGridLayout extends SliverGridRegularTileLayout {
  const _GroupedGridLayout({
    required super.crossAxisCount,
    required super.mainAxisStride,
    required super.crossAxisStride,
    required super.childMainAxisExtent,
    required super.childCrossAxisExtent,
    required super.reverseCrossAxis,
    required this.groupGap,
  });

  final double groupGap;

  @override
  SliverGridGeometry getGeometryForChildIndex(int index) {
    final geometry = super.getGeometryForChildIndex(index);
    // 画面の右半分に来る列を右へずらす。右から並べるとき（RTL）は、先頭の列が右半分
    final inFirstHalf = index % crossAxisCount < crossAxisCount ~/ 2;
    if (groupGap == 0 || inFirstHalf != reverseCrossAxis) {
      return geometry;
    }
    return SliverGridGeometry(
      scrollOffset: geometry.scrollOffset,
      crossAxisOffset: geometry.crossAxisOffset + groupGap,
      mainAxisExtent: geometry.mainAxisExtent,
      crossAxisExtent: geometry.crossAxisExtent,
    );
  }
}
