/// 永続化状態の導出テスト（ADR-005 / Phase 3 WP-1）
///
/// box のオープン結果から PersistenceState を導く純関数を検証する。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';

void main() {
  group('resolvePersistenceState', () {
    test('全areaがオープン済みならReady', () {
      final state = resolvePersistenceState(
        openedAreas: PersistedArea.values.toSet(),
      );

      expect(state, isA<PersistenceReady>());
    });

    test('一部areaだけ失敗ならRecoverableFailureで、失敗したareaを保持する', () {
      final state = resolvePersistenceState(
        openedAreas: {PersistedArea.history},
      );

      expect(state, isA<PersistenceRecoverableFailure>());
      expect(
        (state as PersistenceRecoverableFailure).failedAreas,
        containsAll(<PersistedArea>[
          PersistedArea.presetPhrases,
          PersistedArea.favorites,
        ]),
      );
    });

    test('RecoverableFailureのfailedAreasに成功したareaは含まれない', () {
      final state = resolvePersistenceState(
        openedAreas: {PersistedArea.history, PersistedArea.favorites},
      ) as PersistenceRecoverableFailure;

      expect(state.failedAreas, isNot(contains(PersistedArea.history)));
      expect(state.failedAreas, isNot(contains(PersistedArea.favorites)));
    });

    // 【補足】: Hive の初期化自体（initFlutter）が失敗した場合も
    // 「開いている box が無い」としてこのケースに合流する。初期化の成否を
    // 別の引数で受け取ると同じ事実の出所が2つになるため、そうしていない。
    test('全area失敗ならUnavailable', () {
      final state = resolvePersistenceState(
        openedAreas: const {},
      );

      expect(state, isA<PersistenceUnavailable>());
    });
  });

  group('PersistedArea', () {
    test('boxNameは領域ごとに異なる', () {
      final names = PersistedArea.values.map((a) => a.boxName).toSet();

      expect(names, hasLength(PersistedArea.values.length));
    });

    test('labelは利用者向けに空でない文字列を返す', () {
      for (final area in PersistedArea.values) {
        expect(area.label, isNotEmpty);
      }
    });
  });
}
