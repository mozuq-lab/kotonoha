/// 入力候補チップ行ウィジェット
///
/// fix/improvement-p0-p2: 頻度ベースの入力候補
///
/// 入力表示エリアの直下に表示する、横スクロールの候補チップ行。
/// 候補が0件の場合は高さ0（[SizedBox.shrink]）になり、縦スペースを取らない。
/// 🟡 信頼性レベル: 黄信号 - 新規実装
library;

import 'package:flutter/material.dart';

import 'package:kotonoha_app/core/constants/app_sizes.dart';
import 'package:kotonoha_app/features/input_candidates/domain/models/input_candidate.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// 入力候補チップ行
///
/// [candidates] が空の場合は何も描画せず高さ0にする。
/// 各チップは44px以上のタップターゲットを持ち、タップで
/// [onSelect] に候補テキストを渡す（入力バッファをそのテキストで置換する用途）。
class InputCandidateChips extends StatelessWidget {
  /// 表示する候補一覧（最大4件を想定、呼び出し側で件数を絞り込み済み）
  final List<InputCandidate> candidates;

  /// 候補タップ時のコールバック（候補テキストを渡す）
  final ValueChanged<String> onSelect;

  /// フォントサイズ設定（未指定時はmedium相当）
  final FontSize? fontSize;

  /// コンストラクタ
  const InputCandidateChips({
    super.key,
    required this.candidates,
    required this.onSelect,
    this.fontSize,
  });

  double get _fontSizeValue {
    switch (fontSize ?? FontSize.medium) {
      case FontSize.small:
        return AppSizes.fontSizeSmall;
      case FontSize.medium:
        return AppSizes.fontSizeMedium;
      case FontSize.large:
        return AppSizes.fontSizeLarge;
    }
  }

  @override
  Widget build(BuildContext context) {
    // 【縦スペース確保しない】: 候補がない/入力が空のときは行ごと非表示にする。
    if (candidates.isEmpty) {
      return const SizedBox.shrink();
    }

    // 【チップ最大幅の算出】: 長文候補（履歴文など）でチップが際限なく
    // 横に伸び、後続候補が実質表示されなくなる問題を防ぐため、
    // 画面幅を基準にした上限を設ける（画面幅の約60%、ただし
    // AppSizes.candidateChipMaxWidthを絶対上限とする）。
    // 🟡 信頼性レベル: 黄信号 - Codexレビュー指摘（P2）に基づく
    final screenWidth = MediaQuery.sizeOf(context).width;
    final chipMaxWidth = (screenWidth * 0.6)
        .clamp(AppSizes.minTapTarget, AppSizes.candidateChipMaxWidth)
        .toDouble();

    return SizedBox(
      height: AppSizes.inputCandidateRowHeight,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        // 【注意】: 縦方向のpaddingを指定するとSliverPaddingにより
        // 横スクロールリストのcross-axis（高さ）そのものが縮むため、
        // ここでは横方向のみpaddingを指定し、縦の余白は各アイテムを
        // Centerで配置することで確保する（44pxタップターゲットを
        // 確実に確保するため）。
        padding: const EdgeInsets.symmetric(
          horizontal: AppSizes.paddingMedium,
        ),
        itemCount: candidates.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSizes.paddingSmall),
        itemBuilder: (context, index) {
          final candidate = candidates[index];
          return Center(
            child: _CandidateChip(
              text: candidate.text,
              fontSize: _fontSizeValue,
              maxWidth: chipMaxWidth,
              onTap: () => onSelect(candidate.text),
            ),
          );
        },
      ),
    );
  }
}

class _CandidateChip extends StatelessWidget {
  final String text;
  final double fontSize;
  final double maxWidth;
  final VoidCallback onTap;

  const _CandidateChip({
    required this.text,
    required this.fontSize,
    required this.maxWidth,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: '候補: $text',
      child: ConstrainedBox(
        constraints: BoxConstraints(
          minWidth: AppSizes.minTapTarget,
          minHeight: AppSizes.minTapTarget,
          maxWidth: maxWidth,
        ),
        child: SizedBox(
          height: AppSizes.minTapTarget,
          child: ElevatedButton(
            onPressed: onTap,
            style: ElevatedButton.styleFrom(
              backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
              foregroundColor:
                  Theme.of(context).colorScheme.onSecondaryContainer,
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.paddingMedium,
              ),
              // 【AA対応】: 短い候補テキスト（例:「はい」）でもボタンの内在サイズが
              // 44pxを下回らないよう、明示的にminimumSizeを指定する。
              minimumSize: const Size(
                AppSizes.minTapTarget,
                AppSizes.minTapTarget,
              ),
              // 【長文候補対応】: maxWidthを超えないよう、ボタンの最大サイズも
              // 明示的に制約する（未指定の場合、内容の幅までボタンが伸びうる）。
              // これによりText側のoverflow: TextOverflow.ellipsisが正しく機能する。
              maximumSize: Size(maxWidth, double.infinity),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppSizes.borderRadiusLarge),
              ),
            ),
            child: Text(
              text,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(fontSize: fontSize),
            ),
          ),
        ),
      ),
    );
  }
}
