/// TextInputField ウィジェット
///
/// TASK-0017: 共通UIコンポーネント実装（大ボタン・入力欄・緊急ボタン）
/// 要件: EDGE-101（1000文字制限）、REQ-801（フォントサイズ）
/// 信頼性レベル: 🔵 青信号（要件定義書ベース）
///
/// 文字盤入力やテキスト入力に使用するカスタムテキストフィールド。
/// 最大1000文字制限、クリアボタン対応、大きなフォントサイズ。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// テキスト入力欄ウィジェット
///
/// コミュニケーション支援アプリ用にカスタマイズされたテキスト入力フィールド。
/// 大きなフォントサイズ（24px）、1000文字制限、クリアボタン対応。
///
/// 使用例:
/// ```dart
/// final controller = TextEditingController();
///
/// TextInputField(
///   controller: controller,
///   hintText: 'ここに入力してください',
///   onClear: () => controller.clear(),
/// )
/// ```
class TextInputField extends StatelessWidget {
  /// テキスト編集コントローラー
  final TextEditingController controller;

  /// ヒントテキスト（プレースホルダー）
  final String? hintText;

  /// 最大入力文字数（デフォルト: 1000文字）
  final int maxLength;

  /// クリアボタンタップ時のコールバック
  /// nullの場合、クリアボタンは表示されない
  final VoidCallback? onClear;

  /// 入力が有効かどうか
  final bool enabled;

  /// 読み取り専用かどうか
  final bool readOnly;

  /// TextInputFieldを作成する
  ///
  /// [controller] - テキスト編集コントローラー（必須）
  /// [hintText] - ヒントテキスト（オプション）
  /// [maxLength] - 最大文字数（デフォルト: 1000）
  /// [onClear] - クリアボタンのコールバック（nullでボタン非表示）
  /// [enabled] - 有効状態（デフォルト: true）
  /// [readOnly] - 読み取り専用（デフォルト: false）
  const TextInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength = AppSizes.maxInputLength,
    this.onClear,
    this.enabled = true,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      maxLength: maxLength,
      maxLines: null, // 複数行入力を許可
      enabled: enabled,
      readOnly: readOnly,
      style: const TextStyle(
        fontSize: AppSizes.fontSizeLarge, // 24px
      ),
      decoration: InputDecoration(
        hintText: hintText ?? '文字を入力してください',
        border: const OutlineInputBorder(),
        suffixIcon: onClear != null
            ? IconButton(
                icon: const Icon(Icons.clear),
                onPressed: onClear,
                iconSize: AppSizes.iconSizeMedium,
                tooltip: 'クリア',
              )
            : null,
      ),
    );
  }
}
