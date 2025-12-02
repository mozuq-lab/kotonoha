/// PresetPhraseScreen - 定型文画面
///
/// TASK-0083: 定型文E2Eテスト
/// TDD Greenフェーズ: 定型文画面の実装
///
/// 信頼性レベル: 🔵 青信号（REQ-101, REQ-102, REQ-103, REQ-104, REQ-105, REQ-106, REQ-107に基づく）
///
/// 定型文一覧を表示し、選択・編集・削除・追加機能を提供する画面。
/// お気に入り優先表示、カテゴリ別分類、即座読み上げ機能を実装。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_add_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_delete_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_edit_dialog.dart';
import 'package:kotonoha_app/features/preset_phrase/presentation/widgets/phrase_list_widget.dart';
import 'package:kotonoha_app/features/preset_phrase/providers/preset_phrase_notifier.dart';
import 'package:kotonoha_app/features/tts/providers/tts_provider.dart';
import 'package:kotonoha_app/features/history/providers/history_provider.dart'
    show historyProvider;
import 'package:kotonoha_app/features/history/domain/models/history_type.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

/// 【機能概要】: 定型文画面
/// 【実装方針】: Scaffoldベースでお気に入り・カテゴリ別定型文リストを表示
/// 🔵 信頼性レベル: 青信号 - REQ-101〜107に基づく
///
/// 定型文の一覧表示、選択時の即座読み上げ、CRUD操作を提供。
class PresetPhraseScreen extends ConsumerStatefulWidget {
  /// 定型文画面を作成する。
  const PresetPhraseScreen({super.key});

  @override
  ConsumerState<PresetPhraseScreen> createState() => _PresetPhraseScreenState();
}

class _PresetPhraseScreenState extends ConsumerState<PresetPhraseScreen> {
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

    return Scaffold(
      appBar: AppBar(
        title: const Text('定型文'),
      ),
      body: _buildBody(phrasesState),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddDialog(context),
        tooltip: '定型文を追加',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// 【メソッド】: 本体を構築
  Widget _buildBody(PresetPhraseState state) {
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
      onPhraseSelected: _onPhraseSelected,
      onFavoriteToggle: _onFavoriteToggle,
      onEdit: _onEdit,
      onDelete: _onDelete,
    );
  }

  /// 【メソッド】: 定型文選択時の処理
  /// 【実装内容】: 即座にTTS読み上げを開始し、履歴に保存
  /// 🔵 信頼性レベル: 青信号 - REQ-103、NFR-001に基づく
  void _onPhraseSelected(PresetPhrase phrase) {
    // TTS読み上げを開始
    ref.read(ttsProvider.notifier).speak(phrase.content);

    // 履歴に保存
    ref.read(historyProvider.notifier).addHistory(
          phrase.content,
          HistoryType.preset,
        );
  }

  /// 【メソッド】: お気に入り切り替え処理
  /// 🔵 信頼性レベル: 青信号 - REQ-105に基づく
  void _onFavoriteToggle(PresetPhrase phrase) {
    ref.read(presetPhraseNotifierProvider.notifier).toggleFavorite(phrase.id);
  }

  /// 【メソッド】: 編集処理
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  void _onEdit(PresetPhrase phrase) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseEditDialog(
        phrase: phrase,
        onSave: (updatedPhrase) {
          ref.read(presetPhraseNotifierProvider.notifier).updatePhrase(
                updatedPhrase.id,
                content: updatedPhrase.content,
                category: updatedPhrase.category,
              );
        },
      ),
    );
  }

  /// 【メソッド】: 削除処理
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  void _onDelete(PresetPhrase phrase) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseDeleteDialog(
        phrase: phrase,
        onConfirm: () {
          ref
              .read(presetPhraseNotifierProvider.notifier)
              .deletePhrase(phrase.id);
        },
      ),
    );
  }

  /// 【メソッド】: 追加ダイアログを表示
  /// 🔵 信頼性レベル: 青信号 - REQ-104に基づく
  void _showAddDialog(BuildContext context) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => PhraseAddDialog(
        onSave: (content, category) {
          ref.read(presetPhraseNotifierProvider.notifier).addPhrase(
                content,
                category,
              );
        },
      ),
    );
  }
}
