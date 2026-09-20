/// 誤操作防止ダイアログが、どれも同じ並びの契約を満たすこと（台帳 L-130・L-131）
///
/// 契約そのものと、なぜそれが要るのかは `confirmation_dialog_contract.dart` に書いた。
/// ここでは「取り消し ＋ 取り消せない実行」の二択を出す**すべての**ダイアログに
/// それを当てる。新しくこの形のダイアログを足したら、この一覧にも足すこと。
library;

import 'package:kotonoha_app/features/character_board/presentation/widgets/clear_confirmation_dialog.dart';
import 'package:kotonoha_app/features/emergency/presentation/widgets/emergency_confirmation_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';

import 'confirmation_dialog_contract.dart';

void main() {
  expectMeetsContract(
    '全消去の確認',
    dialog: (_) => ClearConfirmationDialog(
      onConfirmed: () {},
      onCancelled: () {},
    ),
    cancelLabel: 'いいえ',
    confirmLabel: 'はい',
  );

  expectMeetsContract(
    '定型文の削除',
    dialog: (_) => PhraseDeleteDialog(
      phrase: PresetPhrase(
        id: 'p1',
        content: 'テスト',
        category: 'daily',
        displayOrder: 0,
        createdAt: DateTime(2026, 9, 1),
        updatedAt: DateTime(2026, 9, 1),
      ),
    ),
    cancelLabel: 'キャンセル',
    confirmLabel: '削除',
  );

  // 緊急呼び出しだけは `ConfirmationDialog` を使わず自前で組む（色・連続タップ
  // 防止・補足行のため）。並びは同じ `ConfirmationDialogLayout` から取っているが、
  // 「取っているつもり」で済ませず、契約そのものを当てて確かめる
  expectMeetsContract(
    '緊急呼び出しの確認',
    dialog: (_) => EmergencyConfirmationDialog(
      onConfirm: () {},
      onCancel: () {},
    ),
    cancelLabel: EmergencyConfirmationDialog.cancelLabel,
    confirmLabel: EmergencyConfirmationDialog.confirmLabel,
  );

  // 入力欄の置き換え・AI 変換の同意・お気に入りと履歴の削除は、画面の中で
  // `ConfirmationDialog` を直接組んでいる。ラベルと kind の組み合わせを
  // ここで代表させる（ウィジェット自体に契約が入っているので、組み合わせが
  // 増えても並びは変わらない）
  expectMeetsContract(
    '入力欄の置き換え',
    dialog: (context) => ConfirmationDialog(
      title: '入力欄へ',
      message: '入力中の内容を置き換えて入力欄にセットします。よろしいですか？',
      cancelLabel: 'キャンセル',
      confirmLabel: '置き換える',
      onCancel: () {},
      onConfirm: () {},
    ),
    cancelLabel: 'キャンセル',
    confirmLabel: '置き換える',
  );

  expectMeetsContract(
    'AI変換の利用確認',
    dialog: (context) => ConfirmationDialog(
      title: 'AI変換の利用確認',
      message: 'AI変換では入力した文章を外部のAIサービスへ送信します。'
          '送信前に内容を確認し、同意できる場合のみ利用してください。',
      cancelLabel: '同意しない',
      confirmLabel: '同意して利用',
      kind: ConfirmKind.normal,
      onCancel: () {},
      onConfirm: () {},
    ),
    cancelLabel: '同意しない',
    confirmLabel: '同意して利用',
  );
}
