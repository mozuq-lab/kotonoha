/// PresetPhraseScreen - 定型文画面
/// 定型文一覧を表示し、選択・編集・削除・追加機能を提供する画面。
/// お気に入り優先表示、カテゴリ別分類、即座読み上げ機能を実装。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import 'package:kotonoha_app/core/persistence/programming_error_report.dart';
import 'package:kotonoha_app/features/preset_phrase/domain/phrase_constants.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_widget.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/quick_response/presentation/mixins/debounce_mixin.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart'
    show historyProvider;
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:kotonoha_app/shared/widgets/confirmation_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/phrase_draft_provider.dart';

/// 機能概要: 定型文画面
/// 実装方針: Scaffoldベースでお気に入り・カテゴリ別定型文リストを表示
/// 定型文の一覧表示、選択時の即座読み上げ、CRUD操作を提供。
class PresetPhraseScreen extends ConsumerStatefulWidget {
  /// 定型文画面を作成する。
  const PresetPhraseScreen({super.key});

  @override
  ConsumerState<PresetPhraseScreen> createState() => _PresetPhraseScreenState();
}

class _PresetPhraseScreenState extends ConsumerState<PresetPhraseScreen>
    with DebounceMixin<PresetPhraseScreen> {
  @override
  void initState() {
    super.initState();
    // 初期データを読み込む
    Future.microtask(() {
      ref
          .read(presetPhraseNotifierProvider.notifier)
          .initializeDefaultPhrases();
    });
  }

  @override
  Widget build(BuildContext context) {
    // 定型文一覧を監視
    final phrasesState = ref.watch(presetPhraseNotifierProvider);
    // 設計変更: Phase 3 / WP-2 / Stage 3a - お気に入りの正はfavoriteProvider
    // （ADR-005）。定型文由来（sourceType == 'preset_phrase'）のお気に入りの
    // sourceId集合を作り、下位ウィジェットへ渡す。履歴由来（sourceType ==
    // 'history'）が混ざらないようsourceTypeで絞る。
    final favoriteState = ref.watch(favoriteProvider);
    final favoritePresetIds = favoriteState.favorites
        .where((f) => f.sourceType == 'preset_phrase' && f.sourceId != null)
        .map((f) => f.sourceId!)
        .toSet();

    return Scaffold(
      appBar: AppBar(
        title: const Text('定型文'),
        actions: [
          TextButton(
            onPressed: _showDrafts,
            child: const Text('下書き'),
          ),
        ],
      ),
      body: _buildBody(phrasesState, favoritePresetIds),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: '定型文を追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// メソッド: 本体を構築
  Widget _buildBody(PresetPhraseState state, Set<String> favoritePresetIds) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text('エラーが発生しました: ${state.error}'),
      );
    }

    return PhraseListWidget(
      phrases: state.phrases,
      favoritePresetIds: favoritePresetIds,
      onPhraseSelected: _onPhraseSelected,
      onFavoriteToggle: _onFavoriteToggle,
      onEdit: _onEdit,
      onDelete: _onDelete,
    );
  }

  /// メソッド: 定型文選択時の処理
  /// 実装内容: 即座にTTS読み上げを開始し、履歴に保存
  /// バグ修正: DebounceMixin未適用で誤タップによる連続発話が発生し得たため
  /// 他画面（クイック応答ボタン等）と同様にデバウンスを適用した。
  void _onPhraseSelected(PresetPhrase phrase) {
    // デバウンス期間内の連続タップは無視する（誤タップによる連続発話防止）
    if (!checkDebounce()) return;

    // TTS読み上げを開始
    ref.read(ttsProvider.notifier).speak(phrase.content);

    // 履歴に保存
    ref.read(historyProvider.notifier).addHistory(
          phrase.content,
          HistoryType.preset,
        );
  }

  /// メソッド: お気に入り切り替え処理
  void _onFavoriteToggle(PresetPhrase phrase) {
    ref.read(presetPhraseNotifierProvider.notifier).toggleFavorite(phrase.id);
  }

  /// メソッド: 編集処理
  /// [phrase] が null なら、元の定型文が消えた下書き（[draftId]）を開く。
  void _onEdit(PresetPhrase? phrase, [String? draftId]) {
    final notifier = ref.read(presetPhraseNotifierProvider.notifier);
    final drafts = ref.read(phraseDraftProvider);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseEditDialog(
        phrase: phrase,
        draftId: draftId,
        drafts: drafts,
        onSave: (updatedPhrase) {
          return notifier.updatePhrase(
            updatedPhrase.id,
            content: updatedPhrase.content,
            category: updatedPhrase.category,
          );
        },
      ),
    );
  }

  /// メソッド: 削除処理
  /// 定型文を削除してもお気に入りは残る（ADR-005、2026-09-13）ので、
  /// 確認ダイアログにお気に入りの告知は出さない。
  void _onDelete(PresetPhrase phrase) {
    final notifier = ref.read(presetPhraseNotifierProvider.notifier);
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseDeleteDialog(
        phrase: phrase,
        onConfirm: () {
          notifier.deletePhrase(phrase.id);
        },
      ),
    );
  }

  /// メソッド: 編集の下書き（元の定型文が消えたものも含む）を選んで開く入口
  Future<void> _showDrafts() async {
    final container = ProviderScope.containerOf(context, listen: false);
    final repo = ref.read(presetPhraseRepositoryProvider);
    final drafts = ref.read(phraseDraftProvider);
    // 先に一覧のダイアログを開き、読込はその中で待つ。待つ間はモーダルの
    // バリアが画面全体を覆うので、別のフォームも入口の再押下も届かない
    // （下書きの消去は 1 つのモーダルが 1 つの操作を待つ前提）。画面の route を
    // 見る判定は、画面が ShellRoute の内側の Navigator にありダイアログが root に
    // 積まれる実アプリでは効かなかった（Task 2 再レビュー F-8・再監査 N-1）。
    final loaded = drafts.initialize();
    final picked = await showDialog<PhraseDraft>(
      context: context,
      // バリアを押しても閉じない（押し損じで待機中の一覧が消えないように。
      // 閉じるのは「閉じる」か戻る操作）。
      barrierDismissible: false,
      builder: (dialogContext) => ConfirmationDialogLayout.build(
        title: const Text('編集の下書き'),
        content: FutureBuilder<bool>(
          future: loaded,
          builder: (context, snapshot) => Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              if (snapshot.connectionState != ConnectionState.done)
                const Text('下書きを読み込んでいます。')
              // 読めないことを「下書きが無い」にしない。未読のmapには触れない。
              else if (snapshot.data != true)
                const Text('下書きを読み込めませんでした。閉じてから、もう一度「下書き」を押してください。')
              else if (drafts.edits.isEmpty)
                const Text('編集の下書きはありません')
              else
                for (final draft in drafts.edits)
                  TextButton(
                    style:
                        TextButton.styleFrom(alignment: Alignment.centerLeft),
                    onPressed: () => Navigator.of(dialogContext).pop(draft),
                    child: Text(
                      '${PhraseConstants.getCategoryLabel(draft.category)}: '
                      '${draft.content}',
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
            ],
          ),
        ),
        // 閉じても何も消さない。
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('閉じる'),
          ),
        ],
      ),
    );
    if (picked == null || !mounted) return;
    // 選んだ後の現在で、元の定型文の有無を確かめる。確かめられないことを
    // 「無い」にしない（残っている定型文から切り離した孤立として開いてしまう）。
    bool? exists;
    try {
      final state = container.read(presetPhraseNotifierProvider);
      final inState = state.phrases.any((p) => p.id == picked.id);
      if (!state.isLoading &&
          state.error == null &&
          repo != null &&
          inState == repo.loadAllSync().any((p) => p.id == picked.id)) {
        exists = inState;
      }
    } catch (e, s) {
      reportDraftProgrammingError(e, s);
    }
    if (!mounted) return;
    if (exists == null) {
      return _notify('元の定型文を確認できませんでした。下書きは残っています。');
    }
    // 本文が下書きと本体で違うのは編集の目的なので、追加の所有権照合は写さない。
    _onEdit(
        exists
            ? container
                .read(presetPhraseNotifierProvider)
                .phrases
                .firstWhere((p) => p.id == picked.id)
            : null,
        picked.id);
  }

  /// 利用者が閉じるまで残る告知（自動で消える SnackBar は使わない）。
  Future<void> _notify(String message) => showDialog<void>(
        context: context,
        builder: (dialogContext) => ConfirmationDialogLayout.build(
          title: const Text('編集の下書き'),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(dialogContext).pop(),
              child: const Text('閉じる'),
            ),
          ],
        ),
      );

  /// メソッド: 追加ダイアログを表示
  void _showAddDialog(BuildContext context) {
    final container = ProviderScope.containerOf(context, listen: false);
    final notifier = ref.read(presetPhraseNotifierProvider.notifier);
    final repo = ref.read(presetPhraseRepositoryProvider);
    final drafts = ref.read(phraseDraftProvider);
    // 下書きが読めなかったときは復元自体が起きない（照合する相手がいない）。
    // その場合でも再試行が同じkeyへ届くよう、ダイアログごとに固定IDを1つ持つ
    // （L-143。毎回新しいIDだと、一次putが届いてから失敗したとき2件になる）。
    final fallbackId = const Uuid().v4();
    PhraseDraft? initial;
    PhraseDraft? attempt;
    PhraseDraft? reflected;
    String? rejectionMessage;
    PhraseDraftOwnership rejectConflict() {
      rejectionMessage = '保存先が下書きと一致しません。入力をコピーしてから下書きを破棄できます。';
      return PhraseDraftOwnership.conflict;
    }

    /// 実boxを真実に、下書きのIDが誰のレコードかを復元時と保存のたびに照合する。
    /// [pending] はこれから保存しようとしている内容（復元時はnull）。
    PhraseDraftOwnership ownsId({PhraseDraft? pending}) {
      rejectionMessage = null;
      final draft = initial;
      try {
        if (repo == null) return PhraseDraftOwnership.conflict;
        if (draft == null) return PhraseDraftOwnership.owned;
        bool same(PresetPhrase phrase, PhraseDraft other) =>
            phrase.content == other.content &&
            phrase.category == other.category;
        final state = container
            .read(presetPhraseNotifierProvider)
            .phrases
            .where((p) => p.id == draft.id)
            .toList();
        final stored =
            repo.loadAllSync().where((p) => p.id == draft.id).toList();
        final records = [...state, ...stored];
        if (records.isEmpty) return PhraseDraftOwnership.owned;
        // このレコードは自分が書いた／復元した内容か。
        bool mine(PresetPhrase phrase) =>
            same(phrase, draft) ||
            (attempt != null && same(phrase, attempt!)) ||
            (reflected != null && same(phrase, reflected!));
        // 同じIDに同じ内容が既にある＝この下書きの保存は済んでいる。
        // ただし「自分の」レコードと一致するときだけ。衝突で拒否されている
        // 間に相手と同じ本文へ打ち替えただけでは保存済みにしない。
        // 化けると、衝突の出口（コピー案内）が無言の成功になる（台帳 L-168）。
        if (records.every((p) => same(p, pending ?? draft) && mine(p))) {
          return PhraseDraftOwnership.saved;
        }
        final owned = records.every(mine);
        if (!owned) return rejectConflict();
        // 次のattemptがput前に失敗しても、実boxで確認した自分の本文を忘れない。
        if (stored.isNotEmpty) {
          final phrase = stored.first;
          reflected = (
            id: phrase.id,
            content: phrase.content,
            category: phrase.category
          );
        }
        return PhraseDraftOwnership.owned;
      } catch (e, s) {
        // 照合できない以上は拒否する。ただしプログラムの誤りは
        // 利用者向けの穏当な文に隠さず、端末内のログへ出す。
        reportDraftProgrammingError(e, s);
        return PhraseDraftOwnership.conflict;
      }
    }

    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseAddDialog(
        drafts: drafts,
        rejectionMessage: () => rejectionMessage,
        onRestore: (draft) {
          initial = draft;
          attempt = null;
          reflected = null;
          return ownsId();
        },
        onSave: (content, category) {
          // dialog側のflush完了後、実boxとの照合からenqueueまでawaitしない。
          final draft = initial;
          final pending = draft == null
              ? null
              : (id: draft.id, content: content, category: category);
          switch (ownsId(pending: pending)) {
            case PhraseDraftOwnership.conflict:
              return Future.value(false);
            case PhraseDraftOwnership.saved:
              // 本体は書かない。dialog側が下書きの消去だけ再試行する。
              return Future.value(true);
            case PhraseDraftOwnership.owned:
              attempt = pending;
              return notifier.addPhrase(
                content,
                category,
                id: draft?.id ?? fallbackId,
              );
          }
        },
      ),
    );
  }
}
