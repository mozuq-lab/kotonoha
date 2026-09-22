/// PhraseAddDialog - 定型文追加ダイアログ
/// 定型文追加ダイアログを提供
/// 内容とカテゴリを入力できるフォーム
/// 500文字制限
/// 空入力拒否
/// タップターゲット44px以上
library;

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/phrase_draft_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/preset_phrase_validator.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_form_content.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/shared/widgets/discard_input_guard.dart';

/// 機能概要: 定型文追加ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用
/// 新しい定型文を追加するためのダイアログ。
/// 内容入力、カテゴリ選択、保存・キャンセル機能を提供。
class PhraseAddDialog extends StatefulWidget {
  /// パラメータ定義: 保存時のコールバック
  final Future<bool> Function(String content, String category)? onSave;

  final PhraseDrafts? drafts;
  final bool Function(PhraseDraft draft)? onRestore;

  /// 直前の所有権照合で保存を拒否した理由。SDKの書込失敗とは区別する。
  final String? Function()? rejectionMessage;

  /// PhraseAddDialogを作成する
  const PhraseAddDialog({
    super.key,
    this.onSave,
    this.drafts,
    this.onRestore,
    this.rejectionMessage,
  });

  @override
  State<PhraseAddDialog> createState() => _PhraseAddDialogState();
}

class _PhraseAddDialogState extends State<PhraseAddDialog> {
  final _contentController = TextEditingController();
  String _selectedCategory = PhraseConstants.defaultCategory;
  String? _errorMessage;
  bool _saving = false;
  bool _loaded = false;
  bool _loading = false;
  bool _committed = false;
  static const _savedClearFailure = '定型文は保存済みですが、下書きの消去に失敗しました。保存で消去を再試行できます。';
  String? _id;

  @override
  void initState() {
    super.initState();
    _loaded = widget.drafts == null;
    if (!_loaded) _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await widget.drafts!.initialize();
    if (!mounted) return;
    setState(() {
      _loading = false;
      _loaded = loaded;
      if (!loaded) {
        _errorMessage = '下書きの読み込みに失敗しました。再読み込みしてください。';
        return;
      }
      final draft = widget.drafts!.readAdd() ??
          (
            id: const Uuid().v4(),
            content: '',
            category: PhraseConstants.defaultCategory
          );
      _id = draft.id;
      _contentController.text = draft.content;
      _selectedCategory = draft.category;
      _errorMessage = widget.onRestore?.call(draft) == false
          ? widget.rejectionMessage?.call() ?? '保存先を確認できません。入力内容を残しています。'
          : null;
    });
  }

  void _changeDraft() {
    if (_loaded && !_saving && !_committed && _id != null) {
      widget.drafts?.changeAdd((
        id: _id!,
        content: _contentController.text,
        category: _selectedCategory
      ));
    }
  }

  @override
  void dispose() {
    _contentController.dispose();
    super.dispose();
  }

  /// メソッド: 保存ボタン押下時の処理
  /// 実装内容: バリデーション実行後、コールバック発火
  Future<void> _onSave() async {
    if (_saving || !_loaded) return;
    final validationError = PresetPhraseValidator.validateContent(
      _contentController.text,
    );

    if (validationError != null) {
      setState(() {
        _errorMessage = validationError;
      });
      return;
    }

    setState(() => _saving = true);
    var succeeded = false;
    String? rejection;
    try {
      if (_committed) {
        succeeded = await widget.drafts!.removeAdd();
      } else {
        // trimや切詰めをせず、保存と同じsnapshotを先に下書きへ送る。
        if (_id != null) {
          widget.drafts!.changeAdd((
            id: _id!,
            content: _contentController.text,
            category: _selectedCategory
          ));
        }
        if (widget.drafts == null || await widget.drafts!.flush()) {
          succeeded = await widget.onSave
                  ?.call(_contentController.text, _selectedCategory) ??
              false;
          if (!succeeded) rejection = widget.rejectionMessage?.call();
          if (succeeded && widget.drafts != null) {
            _committed = true;
            succeeded = await widget.drafts!.removeAdd();
          }
        }
      }
    } catch (_) {
      // 入力を残し、同じ場所で再試行できるようにする。
    }
    if (!mounted) return;
    if (succeeded) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorMessage = _committed
            ? _savedClearFailure
            : rejection ?? '保存を確認できませんでした。入力内容を残しています。';
      });
    }
  }

  /// メソッド: キャンセルボタン押下時の処理
  Future<void> _onCancel() async {
    if (_saving) return;
    // 未読mapは閉じるだけで残す。空本文/categoryだけの下書きも明示破棄する。
    if (widget.drafts == null || !_loaded) {
      Navigator.of(context).pop();
      return;
    }
    setState(() => _saving = true);
    final cleared = await widget.drafts!.removeAdd();
    if (!mounted) return;
    if (cleared) {
      Navigator.of(context).pop();
    } else {
      setState(() {
        _saving = false;
        _errorMessage =
            _committed ? _savedClearFailure : '下書きの消去に失敗しました。入力内容を残しています。';
      });
    }
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  void _onTextChanged() {
    if (_saving || !_loaded || _committed) return;
    _changeDraft();
    setState(() {
      _errorMessage = null;
    });
  }

  /// メソッド: カテゴリ変更時の処理
  void _onCategoryChanged(String category) {
    if (_saving || !_loaded || _committed) return;
    setState(() {
      _selectedCategory = category;
    });
    _changeDraft();
  }

  @override
  Widget build(BuildContext context) {
    // 並びは `ConfirmationDialog` と同じものを使う（台帳 L-130）。
    // 本文がフォーム（文字数カウンタ・カテゴリ選択・エラー表示）なので
    // `ConfirmationDialog`（本文は String）には入らないが、**「キャンセル」と
    // 「保存」が接すると、打った文がそのまま消える**のは同じ。
    // 指定が無いと `AlertDialog` の既定のままで、幅 320・倍率 1.3 で 0.0px に
    // なる（2026-09-20 実測）。
    //
    // なお `ConfirmKind.destructive` が置いている「取り消せない実行だけを塗って
    // 見分けられるようにする」という決定は、**この 2 つには当てはまらない**。
    // **取り消せないのは「キャンセル」側**で、押すと
    // 打った文がそのまま消える。
    // だから「保存」は塗らない（台帳 L-137）。
    // 端末の戻るボタンは `barrierDismissible: false` では塞げない。
    // 入力があるうちは、閉じる前に確認する（台帳 L-136）。
    // 新しく打った文があるかどうか。空なら捨てるものが無い
    final dialog = ConfirmationDialogLayout.build(
      title: const Text('定型文を追加'),
      // 自前の `SingleChildScrollView` は持たない。
      // `ConfirmationDialogLayout.build` が `scrollable: true` を渡すので、
      // `AlertDialog` が title と content をスクロールに入れる。重ねると
      // 内側は無限高さ制約で `maxScrollExtent = 0` になり、ドラッグを取らない
      // 死んだ仕組みになる（ADR-008。台帳 L-138）
      content: ExcludeFocus(
          excluding: !_loaded || _committed,
          child: AbsorbPointer(
              absorbing: !_loaded || _committed,
              child: PhraseFormContent(
                controller: _contentController,
                selectedCategory: _selectedCategory,
                onCategoryChanged: _onCategoryChanged,
                currentLength: _contentController.text.length,
                errorMessage: _errorMessage,
                onTextChanged: _onTextChanged,
              ))),
      actions: [
        if (!_loaded && !_loading)
          TextButton(onPressed: _load, child: const Text('再読み込み')),
        // キャンセルボタン: ダイアログを閉じる
        TextButton(
          onPressed: _saving ? null : _onCancel,
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        ElevatedButton(
          onPressed: _saving || !_loaded ? null : _onSave,
          child: const Text('保存'),
        ),
      ],
    );
    return _saving
        ? PopScope(
            canPop: false,
            child: ExcludeFocus(child: AbsorbPointer(child: dialog)),
          )
        : widget.drafts != null && _contentController.text.trim().isEmpty
            ? PopScope(
                canPop: false,
                onPopInvokedWithResult: (didPop, _) {
                  if (!didPop) _onCancel();
                },
                child: dialog,
              )
            : DiscardInputGuard(
                hasInput: _contentController.text.trim().isNotEmpty,
                onDiscard: _onCancel,
                child: dialog,
              );
  }
}
