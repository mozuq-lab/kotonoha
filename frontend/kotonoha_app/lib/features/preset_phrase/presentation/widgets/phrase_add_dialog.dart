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

/// 復元した下書きのIDが、実boxのどのレコードに当たるか。
enum PhraseDraftOwnership {
  /// boxに無い、または自分が書いたレコード。同じIDのまま保存を通す
  owned,

  /// 本文・カテゴリまで同じレコードが既にある＝この下書きは保存済み。本体へは書かない
  saved,

  /// 別内容のレコードがある。保存を拒否する
  conflict,
}

/// 機能概要: 定型文追加ダイアログ
/// 実装方針: AlertDialogベースでPhraseFormContentを使用
/// 新しい定型文を追加するためのダイアログ。
/// 内容入力、カテゴリ選択、保存・キャンセル機能を提供。
class PhraseAddDialog extends StatefulWidget {
  /// パラメータ定義: 保存時のコールバック
  final Future<bool> Function(String content, String category)? onSave;

  final PhraseDrafts? drafts;

  /// 復元した（または新しく起こした）下書きのIDを実boxと照合する。
  final PhraseDraftOwnership Function(PhraseDraft draft)? onRestore;

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
  bool _clearFailed = false;
  static const _savedClearFailure = '定型文は保存済みですが、下書きを消せませんでした。閉じると次回も残ります。';
  static const _clearFailure = '下書きを消せませんでした。閉じると次回も残ります。';
  static const _loadFailure = '下書きを読み込めませんでした。入力は保存できますが、下書きは残りません。';
  String? _id;

  /// 下書きの読み書きができる状態か。読めていない間は一切書かない。
  bool get _draftsReady => widget.drafts != null && _loaded;

  @override
  void initState() {
    super.initState();
    _loaded = widget.drafts == null;
    if (!_loaded) _load();
  }

  PhraseDraft _fresh() => (
        id: const Uuid().v4(),
        content: '',
        category: PhraseConstants.defaultCategory
      );

  Future<void> _load() async {
    setState(() => _loading = true);
    final loaded = await widget.drafts!.initialize();
    if (!mounted) return;
    if (!loaded) {
      setState(() {
        _loading = false;
        _loaded = false;
        // 下書きは補助機能。読めなくても追加そのものは止めない（ADR-005）。
        _errorMessage = _loadFailure;
      });
      return;
    }
    var draft = widget.drafts!.readAdd() ?? _fresh();
    var ownership = widget.onRestore?.call(draft) ?? PhraseDraftOwnership.owned;
    var cleared = true;
    if (ownership == PhraseDraftOwnership.saved) {
      // 本体は保存済み。残っている下書きを消して、空の追加フォームで開く。
      cleared = await widget.drafts!.removeAdd();
      if (!mounted) return;
      if (cleared) {
        draft = _fresh();
        ownership = widget.onRestore?.call(draft) ?? PhraseDraftOwnership.owned;
      }
    }
    setState(() {
      _loading = false;
      _loaded = true;
      _id = draft.id;
      _contentController.text = draft.content;
      _selectedCategory = draft.category;
      if (!cleared) {
        // 消せないまま編集させると保存済みの本体を書き換えてしまう。
        _committed = true;
        _clearFailed = true;
        _errorMessage = _savedClearFailure;
      } else {
        _errorMessage = ownership == PhraseDraftOwnership.conflict
            ? widget.rejectionMessage?.call() ?? '保存先を確認できません。入力内容を残しています。'
            : null;
      }
    });
  }

  void _changeDraft() {
    if (_draftsReady && !_saving && !_committed && _id != null) {
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
    if (_saving || _loading) return;
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
    // 未読のまま保存する経路では、下書きへは読み書きとも一切触らない。
    final ready = _draftsReady;
    try {
      if (_committed) {
        succeeded = await widget.drafts!.removeAdd();
      } else {
        // trimや切詰めをせず、保存と同じsnapshotを先に下書きへ送る。
        if (ready && _id != null) {
          widget.drafts!.changeAdd((
            id: _id!,
            content: _contentController.text,
            category: _selectedCategory
          ));
        }
        if (!ready || await widget.drafts!.flush()) {
          succeeded = await widget.onSave
                  ?.call(_contentController.text, _selectedCategory) ??
              false;
          if (!succeeded) rejection = widget.rejectionMessage?.call();
          if (succeeded && ready) {
            _committed = true;
            // 消去が例外で返っても「成功」を持ち越さない。
            succeeded = false;
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
        // 本体は保存済みで消去だけ失敗した＝閉じても失うものが無い。
        if (_committed) _clearFailed = true;
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
    if (!_draftsReady) {
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
        // 消せないまま閉じ込めない。閉じても下書きは残るので失うものは無い。
        _clearFailed = true;
        _errorMessage = _committed ? _savedClearFailure : _clearFailure;
      });
    }
  }

  /// メソッド: テキスト変更時の処理
  /// 実装内容: エラーメッセージをクリアしてUIを更新
  void _onTextChanged() {
    if (_saving || _loading || _committed) return;
    _changeDraft();
    setState(() {
      // 読めていないことは入力のたびに消えてはいけない事実なので残す。
      _errorMessage = _loaded ? null : _loadFailure;
    });
  }

  /// メソッド: カテゴリ変更時の処理
  void _onCategoryChanged(String category) {
    if (_saving || _loading || _committed) return;
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
          excluding: _loading || _committed,
          child: AbsorbPointer(
              absorbing: _loading || _committed,
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
        // 消去が失敗し続けても閉じられる出口。下書きは消さずに残す
        // （閉じられないとモーダルの下の緊急ボタンへ到達できない）
        if (_clearFailed)
          TextButton(
            onPressed: _saving ? null : () => Navigator.of(context).pop(),
            child: const Text('閉じる'),
          ),
        // キャンセルボタン: ダイアログを閉じる
        TextButton(
          onPressed: _saving ? null : _onCancel,
          child: const Text('キャンセル'),
        ),
        // 保存ボタン: バリデーション後に保存
        ElevatedButton(
          onPressed: _saving || _loading ? null : _onSave,
          child: const Text('保存'),
        ),
      ],
    );
    // 戻る操作は閉じるだけで、下書きを消さない（本文が空でも同じ）。
    // 消えるのは「キャンセル」と、確認で「破棄する」を選んだときだけ。
    return _saving
        ? PopScope(
            canPop: false,
            child: ExcludeFocus(child: AbsorbPointer(child: dialog)),
          )
        : DiscardInputGuard(
            // 消去に失敗した後は、backも再試行で止まらずそのまま閉じる。
            // 閉じても下書きは残るので、確認して守るものが無い
            hasInput:
                !_clearFailed && _contentController.text.trim().isNotEmpty,
            onDiscard: _onCancel,
            child: dialog,
          );
  }
}
