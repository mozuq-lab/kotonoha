/// 永続化バナー（ADR-005 / Phase 3 WP-1）
///
/// 保存できない状態を利用者に伝え続ける常設バナー。
///
/// 【なぜ常設か】: 対象の利用者は発話で確認・訂正ができず、データは端末内に
/// しか無い。一度きりの通知は見落とすと取り返しがつかないため、保存できない
/// 間はずっと表示する。保存できているとき（[PersistenceReady]）は高さ0で、
/// 画面を1pxも占有しない。
///
/// 【起動はブロックしない】: NFR-301。ストレージが壊れていても文字盤・TTS は
/// 使えるべきなので、伝えたうえで継続する。
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:kotonoha_app/core/constants/app_colors.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/persistence/persistence_state_provider.dart';

/// バナーの前景色と背景色の組
///
/// コントラスト比を測るテストが参照するため公開している。
@immutable
class PersistenceBannerColors {
  /// 文字とアイコンの色
  final Color foreground;

  /// 帯の背景色
  final Color background;

  /// 前景色と背景色を指定して作る
  const PersistenceBannerColors({
    required this.foreground,
    required this.background,
  });
}

/// 何も保存できないときの配色
///
/// 最も強い警告なので `error` / `onError` を使う。3テーマとも
/// コントラスト比を検証済み（`persistence_banner_test.dart`）。
PersistenceBannerColors unavailableBannerColors(ColorScheme scheme) =>
    PersistenceBannerColors(
      foreground: scheme.onError,
      background: scheme.error,
    );

/// 一部だけ保存できないときの配色
///
/// 全滅より一段弱い扱いとして、自前背景を持つ警告表示の既存パターン
/// （音量警告・AI変換不可と同じ [AppColors.warningContainer]）を使う。
///
/// 【`colorScheme.errorContainer` を使わない理由】: 本アプリの3テーマは
/// `ColorScheme.light`/`dark` に `error` だけを渡しており、
/// `errorContainer` は `error` にフォールバックする。そのため全滅と
/// 一部失敗が同じ色になり、区別が付かない（テストで検出した）。
/// テーマに依らない固定色なので ColorScheme は受け取らない。
PersistenceBannerColors recoverableBannerColors() =>
    const PersistenceBannerColors(
      foreground: AppColors.onWarningContainer,
      background: AppColors.warningContainer,
    );

/// 保存できない状態を伝える常設バナー
///
/// `AppShell` の画面本体の先頭に置き、全画面で表示される。
class PersistenceBanner extends ConsumerWidget {
  /// バナーを作る
  const PersistenceBanner({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(persistenceStateProvider);
    final scheme = Theme.of(context).colorScheme;

    final (colors, message) = switch (state) {
      PersistenceReady() => (null, null),
      PersistenceUnavailable() => (
          unavailableBannerColors(scheme),
          '保存できません。アプリを閉じると入力内容は消えます',
        ),
      PersistenceRecoverableFailure(:final failedAreas) => (
          recoverableBannerColors(),
          '${_areaNames(failedAreas)}を保存できません。アプリを閉じると消えます',
        ),
    };

    if (colors == null || message == null) return const SizedBox.shrink();

    return Semantics(
      label: message,
      child: Container(
        width: double.infinity,
        color: colors.background,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.warning_amber_rounded,
                size: 18, color: colors.foreground),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                message,
                style: TextStyle(color: colors.foreground, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// 保存できない領域の名前を、宣言順で読点区切りにする
  ///
  /// Set の反復順に依存すると文言が実行ごとに変わるため、
  /// [PersistedArea] の宣言順に並べ直す。
  String _areaNames(Set<PersistedArea> areas) => PersistedArea.values
      .where(areas.contains)
      .map((area) => area.label)
      .join('、');
}
