import 'package:flutter/material.dart';
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
  });

  final VoidCallback? onFavoritePressed;
  final FontSize fontSize;

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
        maxLines: 3,
        minLines: 1,
        keyboardType: TextInputType.multiline,
        textInputAction: TextInputAction.done,
        inputFormatters: [
          LengthLimitingTextInputFormatter(InputBufferNotifier.maxLength),
        ],
        onChanged: ref.read(inputBufferProvider.notifier).setText,
        decoration: InputDecoration(
          border: InputBorder.none,
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
            icon: const Icon(Icons.favorite_border),
          ),
        ),
      ),
    );
  }
}
