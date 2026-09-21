/// TextInputField ウィジェット
/// 要件: （1000文字制限）、（フォントサイズ）
/// 文字盤入力やテキスト入力に使用するカスタムテキストフィールド。
library;

import 'package:flutter/material.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// テキスト入力欄ウィジェット
/// コミュニケーション支援アプリ用にカスタマイズされたテキスト入力フィールド。
/// 使用例
/// ```dart
/// final controller = TextEditingController;
/// TextInputField(
/// controller: controller
/// hintText: 'ここに入力してください'
/// )
/// ```
class TextInputField extends StatelessWidget {
  /// テキスト編集コントローラー
  final TextEditingController controller;

  /// ヒントテキスト（プレースホルダー）
  final String? hintText;

  /// 最大入力文字数（デフォルト: 1000文字）
  final int maxLength;

  /// 入力が有効かどうか
  final bool enabled;

  /// 読み取り専用かどうか
  final bool readOnly;

  /// TextInputFieldを作成する
  /// [controller] - テキスト編集コントローラー（必須）
  /// [hintText] - ヒントテキスト（オプション）
  /// [maxLength] - 最大文字数（デフォルト: 1000）
  /// [enabled] - 有効状態（デフォルト: true）
  /// [readOnly] - 読み取り専用（デフォルト: false）
  const TextInputField({
    super.key,
    required this.controller,
    this.hintText,
    this.maxLength = AppSizes.maxInputLength,
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
      ),
    );
  }
}
