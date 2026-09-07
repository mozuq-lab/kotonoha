/// PresetPhraseNotifier - 定型文状態管理
/// 定型文の追加・編集・削除機能
/// お気に入り定型文を一覧上部に優先表示
/// 初期データとして50-100個の汎用定型文を提供
/// 定型文をお気に入りとして登録
/// UUID形式の一意識別子を自動付与
/// お気に入りフラグを切り替える機能
/// createdAt/updatedAtタイムスタンプを自動設定
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/features/preset_phrase/data/default_phrases.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:uuid/uuid.dart';

/// 状態管理: 定型文一覧の状態
class PresetPhraseState {
  /// 定型文一覧
  final List<PresetPhrase> phrases;

  /// ローディング状態
  final bool isLoading;

  /// エラーメッセージ
  final String? error;

  const PresetPhraseState({
    this.phrases = const [],
    this.isLoading = false,
    this.error,
  });

  /// 状態コピー: 指定したフィールドのみを更新した新しい状態を返す
  /// エラーの扱い: `error` を省略した場合は現在のエラーを保持する。
  /// 明示的に消したい場合は `clearError: true` を指定すること。
  /// AIConversionState.copyWith と同じ「clearXxxフラグ方式」に統一している。
  PresetPhraseState copyWith({
    List<PresetPhrase>? phrases,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return PresetPhraseState(
      phrases: phrases ?? this.phrases,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

/// 機能概要: 定型文状態管理Notifier
/// 実装方針: Riverpod StateNotifierで状態管理
/// 定型文のCRUD操作を提供するStateNotifier。
/// 追加、更新、削除、お気に入り切り替え機能を実装。
/// お気に入り操作時はFavoriteNotifierと連動する。
/// エラー状態の方針: PresetPhraseScreen は `state.error != null` のとき
/// リスト全体をエラー表示に差し替える。エラーを設定するのは
/// initializeDefaultPhrases の失敗のみで、同メソッドは phrases が非空だと
/// 早期returnするため、一度エラーが付いたまま定型文が1件でも増えると
/// 二度と解除できなくなる。これを防ぐため、成功した操作の完了時には
/// `clearError: true` を明示して状態を復帰させる。
class PresetPhraseNotifier extends Notifier<PresetPhraseState> {
  /// お気に入りの正: FavoriteNotifier を必要になった時点で引く
  /// 設計変更: Phase 3 / WP-2 / Stage 3b - 以前は build で
  /// `late FavoriteNotifier?` に保持していたが、build を差し替えた
  /// テスト用 Notifier では初期化されず LateInitializationError になる。
  /// 参照は使う場所で引けばよい。
  FavoriteNotifier get _favoriteNotifier => ref.read(favoriteProvider.notifier);

  @override
  PresetPhraseState build() {
    // 永続化配線: Repositoryが利用可能（Boxオープン済み）の場合はHiveから初期化
    // フォールバック: repo==nilまたはデータ無しの場合は従来どおり空状態
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      final items = repo.loadAllSync();
      if (items.isNotEmpty) {
        return PresetPhraseState(phrases: _sortPhrases(items));
      }
    }
    return const PresetPhraseState();
  }

  /// UUID生成用インスタンス
  static const _uuid = Uuid();

  /// メソッド: 定型文を追加する
  /// 実装内容: 新しい定型文をUUID付きで追加
  Future<void> addPhrase(String content, String category) async {
    final now = DateTime.now();
    final newPhrase = PresetPhrase(
      id: _uuid.v4(), // UUID形式のID自動生成
      content: content,
      category: category,
      displayOrder: state.phrases.length,
      createdAt: now, // タイムスタンプ自動設定
      updatedAt: now,
    );

    // 状態を更新し、お気に入り順でソート
    // エラークリア: 操作が成功したので直前のエラーは解消したとみなす
    final updatedPhrases = [...state.phrases, newPhrase];
    state = state.copyWith(
      phrases: _sortPhrases(updatedPhrases),
      clearError: true,
    );

    // 永続化: repoがあればHiveに保存
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      await repo.save(newPhrase);
    }
  }

  /// メソッド: 定型文を更新する
  /// 実装内容: 指定IDの定型文を更新
  Future<void> updatePhrase(
    String id, {
    String? content,
    String? category,
  }) async {
    // 対象の定型文を検索 (対応)
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      // 存在しないIDの場合は何もしない
      return;
    }

    final original = state.phrases[index];
    final updatedPhrase = original.copyWith(
      content: content ?? original.content,
      category: category ?? original.category,
      updatedAt: DateTime.now(), // タイムスタンプ更新
    );

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases[index] = updatedPhrase;
    // エラークリア: 操作が成功したので直前のエラーは解消したとみなす
    state = state.copyWith(
      phrases: _sortPhrases(updatedPhrases),
      clearError: true,
    );

    // 永続化: repoがあればHiveに保存
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      await repo.save(updatedPhrase);
    }
  }

  /// メソッド: 定型文を削除する
  /// 実装内容: 指定IDの定型文を削除し、お気に入りの場合はFavoriteからも削除
  Future<void> deletePhrase(String id) async {
    // 対象の定型文を検索 (対応)
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      // 存在しないIDの場合は何もしない
      return;
    }

    // 連動処理: 定型文を削除したら、対応するお気に入りも消す
    // 無条件で呼ぶ理由: Phase 3 / WP-2 / Stage 3b で PresetPhrase.isFavorite が
    // 無くなったので、お気に入りかどうかは favoriteProvider しか知らない。
    // deleteFavoriteBySourceId は該当が無ければ何もしないため、無条件でよい。
    await _favoriteNotifier.deleteFavoriteBySourceId(id);

    final updatedPhrases = List<PresetPhrase>.from(state.phrases);
    updatedPhrases.removeAt(index);
    // エラークリア: 操作が成功したので直前のエラーは解消したとみなす
    state = state.copyWith(phrases: updatedPhrases, clearError: true);

    // 永続化: repoがあればHiveから削除
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      await repo.delete(id);
    }
  }

  /// メソッド: お気に入りを切り替える
  /// 実装内容: favoriteProvider へ委譲する。定型文レコードは変えない
  /// 設計変更: Phase 3 / WP-2 / Stage 3b - お気に入りの正は favoriteProvider
  /// だけになった（ADR-005「1概念1真実」）。以前は PresetPhrase.isFavorite を
  /// 反転して Hive に書き戻し、さらに FavoriteNotifier へ連動させる双方向同期
  /// だったが、真実が2つあると必ず食い違う。
  /// 定型文レコードを書き換えない: 定型文そのものは変わらないので
  /// `repo.save` は呼ばず、`updatedAt` も動かさない。
  Future<void> toggleFavorite(String id) async {
    final index = state.phrases.indexWhere((p) => p.id == id);
    if (index == -1) {
      return;
    }

    final phrase = state.phrases[index];

    // 現在の状態: お気に入りかどうかは favoriteProvider に問う。
    // 履歴由来（sourceType == 'history'）が混ざらないよう sourceType で絞る。
    final isFavorite = ref.read(favoriteProvider).favorites.any(
          (f) => f.sourceType == 'preset_phrase' && f.sourceId == id,
        );

    if (isFavorite) {
      await _favoriteNotifier.deleteFavoriteBySourceId(id);
    } else {
      await _favoriteNotifier.addFavoriteFromPresetPhrase(
        phrase.content,
        phrase.id,
      );
    }

    // エラークリア: 操作が成功したので直前のエラーは解消したとみなす。
    // phrases は変えない（お気に入りは定型文の属性ではなくなった）。
    state = state.copyWith(clearError: true);
  }

  /// メソッド: 定型文一覧を読み込む
  /// 実装内容: Hive（Boxオープン時）から定型文を読み込み、お気に入り順で反映
  /// フォールバック: repo==nilの場合は従来どおりインメモリ管理のみ
  Future<void> loadPhrases() async {
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      // 永続化: Hiveから読み込み、お気に入り順でソートして反映
      // エラークリア: 読み込みに成功したので直前のエラーは明示的に消す
      state = state.copyWith(
        phrases: _sortPhrases(repo.loadAllSync()),
        isLoading: false,
        clearError: true,
      );
      return;
    }
    // フォールバック: インメモリ管理のみ
    state = state.copyWith(isLoading: false, clearError: true);
  }

  /// メソッド: 初期定型文データを投入する
  /// 実装内容: DefaultPhrasesから70個程度の定型文を読み込み、状態に追加
  /// 初回起動時に呼び出され、デフォルトの定型文を投入する。
  /// 既に定型文が存在する場合は何もしない（重複投入防止）。
  Future<void> initializeDefaultPhrases() async {
    // 既にデータがある場合は何もしない
    if (state.phrases.isNotEmpty) {
      return;
    }

    // エラークリア: 再試行なので前回の失敗メッセージを残さない
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final allPhrases = DefaultPhrases.getAllPhrases();
      final now = DateTime.now();
      final phrases = <PresetPhrase>[];
      var displayOrder = 0;

      // カテゴリ順: daily -> health -> other
      for (final category in ['daily', 'health', 'other']) {
        final categoryPhrases = allPhrases[category] ?? [];
        for (final content in categoryPhrases) {
          phrases.add(PresetPhrase(
            id: _uuid.v4(),
            content: content,
            category: category,
            displayOrder: displayOrder++,
            createdAt: now,
            updatedAt: now,
          ));
        }
      }

      // 永続化: repoがあればHiveに一括保存
      final repo = ref.read(presetPhraseRepositoryProvider);
      if (repo != null) {
        await repo.saveAll(phrases);
      }

      // エラークリア: 冒頭のクリアに依存せず、成功パスでも明示的に消す。
      // await repo.saveAll の待機中に他経路がエラーを設定し得るため。
      state = state.copyWith(
        phrases: phrases,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: '初期データの読み込みに失敗しました: $e',
      );
    }
  }

  /// メソッド: 定型文データをリセットする
  /// 実装内容: 全定型文を削除し、初期データを再投入
  /// 設定画面等から呼び出され、定型文を初期状態に戻す。
  Future<void> resetToDefaults() async {
    // 永続化: repoがあればHiveの定型文を全削除してから再投入
    final repo = ref.read(presetPhraseRepositoryProvider);
    if (repo != null) {
      await repo.deleteAll();
    }
    // エラークリア: ここでは行わない。phrasesを空にした直後なので
    // 続く initializeDefaultPhrases が早期returnせず必ず clearError する。
    state = state.copyWith(phrases: [], isLoading: true);
    await initializeDefaultPhrases();
  }

  /// プライベートメソッド: 定型文を表示順で並べ替える
  /// 設計変更: Phase 3 / WP-2 / Stage 3b - お気に入りを先頭へ寄せる規則は
  /// ここから外した。お気に入り優先表示は PhraseListWidget のセクション分割
  /// （Stage 3a）が担っており、ここでも並べ替えると同じ規則が2箇所に散る。
  List<PresetPhrase> _sortPhrases(List<PresetPhrase> phrases) {
    final sorted = List<PresetPhrase>.from(phrases);
    sorted.sort((a, b) => a.displayOrder.compareTo(b.displayOrder));
    return sorted;
  }
}

/// Provider定義: PresetPhraseNotifierのProvider
/// 実装内容: FavoriteNotifierを渡してお気に入り連動を有効化
final presetPhraseNotifierProvider =
    NotifierProvider<PresetPhraseNotifier, PresetPhraseState>(
  PresetPhraseNotifier.new,
);
