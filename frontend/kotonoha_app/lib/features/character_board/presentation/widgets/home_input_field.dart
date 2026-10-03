import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart' show CupertinoIcons;
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/core/constants/app_sizes.dart';

/// 文字盤と OS キーボードが同じ入力バッファを編集する欄。
class HomeInputField extends ConsumerStatefulWidget {
  const HomeInputField({
    super.key,
    required this.onFavoritePressed,
    this.fontSize = FontSize.medium,
    this.maxLines = 3,
  });

  final VoidCallback? onFavoritePressed;
  final FontSize fontSize;

  /// 入力が伸びるときの最大の行数。高さの上限はこれで守り、欄そのものを
  /// 押しつぶさない（押しつぶすとラベルと文字が重なる）。2 未満は 2 として扱う。
  final int maxLines;

  @override
  ConsumerState<HomeInputField> createState() => _HomeInputFieldState();
}

class _HomeInputFieldState extends ConsumerState<HomeInputField> {
  late final TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(inputBufferProvider));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final buffer = ref.watch(inputBufferProvider);
    final size = switch (widget.fontSize) {
      FontSize.small => AppSizes.fontSizeSmall,
      FontSize.medium => AppSizes.fontSizeMedium,
      FontSize.large => AppSizes.fontSizeLarge,
    };
    ref.listen<String>(inputBufferProvider, (_, next) {
      if (_controller.text == next) return;
      _controller.value = TextEditingValue(
        text: next,
        selection: TextSelection.collapsed(offset: next.length),
      );
    });
    return Semantics(
      liveRegion: true,
      child: TextField(
        key: const Key('home_input_field'),
        controller: _controller,
        style:
            TextStyle(fontSize: size, height: 1.5, fontWeight: FontWeight.w600),
        // 1 にしない: 最大行数が 1 だと Flutter が改行を消す処理を自動で差し込み、
        // 定型文や貼り付けで入った改行が、キーボードで 1 文字打つだけで黙って消える
        maxLines: widget.maxLines < 2 ? 2 : widget.maxLines,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          LengthLimitingTextInputFormatter(InputBufferNotifier.maxLength),
        ],
        onChanged: ref.read(inputBufferProvider.notifier).setText,
        decoration: InputDecoration(
          // 枠は外側の囲み（home_input_area）が描く。状態ごとの枠も消さないと
          // 高コントラストのテーマの枠を引き継いで二重になる
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          disabledBorder: InputBorder.none,
          hintText: '入力してください...',
          labelText: '入力欄',
          labelStyle: const TextStyle(fontSize: 16),
          floatingLabelStyle: const TextStyle(fontSize: 16),
          floatingLabelBehavior: FloatingLabelBehavior.always,
          contentPadding:
              const EdgeInsets.symmetric(vertical: AppSizes.paddingSmall),
          suffixIcon: IconButton(
            key: const Key('favorite_current_input'),
            tooltip: '入力中の文をお気に入りに登録',
            onPressed: buffer.trim().isEmpty ? null : widget.onFavoritePressed,
            icon: const Icon(CupertinoIcons.heart),
          ),
        ),
      ),
    );
  }
}
