import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/character_board_widget.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_all_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/delete_button.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/home_input_field.dart';
import 'package:kotonoha_app/features/character_board/presentation/widgets/input_limit_notice.dart';
import 'package:kotonoha_app/features/character_board/providers/input_buffer_provider.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';

/// 相手向きの表示とは独立した、本人向きの入力欄と文字盤。
class FaceToFaceEditor extends ConsumerWidget {
  const FaceToFaceEditor({super.key, required this.fontSize});

  final FontSize fontSize;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final buffer = ref.watch(inputBufferProvider);
    final notifier = ref.read(inputBufferProvider.notifier);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: Column(children: [
        HomeInputField(
          onFavoritePressed: null,
          showFavoriteButton: false,
          fontSize: fontSize,
          maxLines: 2,
        ),
        const InputLimitNotice(),
        Row(children: [
          Expanded(
              child: DeleteButton(
            showLabel: true,
            enabled: buffer.isNotEmpty,
            onPressed: notifier.deleteLastCharacter,
          )),
          const SizedBox(width: 8),
          Expanded(
              child: ClearAllButton(
            showLabel: true,
            enabled: buffer.isNotEmpty,
            onConfirmed: notifier.clear,
          )),
        ]),
        const SizedBox(height: 8),
        Expanded(
            child: CharacterBoardWidget(
          fontSize: fontSize,
          onCharacterTap: (character) {
            FocusScope.of(context).unfocus();
            if (CharacterData.isDakutenKey(character)) {
              notifier.applyDakuten();
            } else if (CharacterData.isHandakutenKey(character)) {
              notifier.applyHandakuten();
            } else {
              notifier.addCharacter(character);
            }
          },
        )),
      ]),
    );
  }
}
