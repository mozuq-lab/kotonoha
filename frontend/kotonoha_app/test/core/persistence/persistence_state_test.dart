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
        hiveInitialized: true,
      );

      expect(state, isA<PersistenceReady>());
    });

    test('一部areaだけ失敗ならRecoverableFailureで、失敗したareaを保持する', () {
      final state = resolvePersistenceState(
        openedAreas: {PersistedArea.history},
        hiveInitialized: true,
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
        hiveInitialized: true,
      ) as PersistenceRecoverableFailure;

      expect(state.failedAreas, isNot(contains(PersistedArea.history)));
      expect(state.failedAreas, isNot(contains(PersistedArea.favorites)));
    });

    test('全area失敗ならUnavailable', () {
      final state = resolvePersistenceState(
        openedAreas: const {},
        hiveInitialized: true,
      );

      expect(state, isA<PersistenceUnavailable>());
    });

    test('Hive初期化自体が失敗していればopenedAreasに関わらずUnavailable', () {
      final state = resolvePersistenceState(
        openedAreas: PersistedArea.values.toSet(),
        hiveInitialized: false,
      );

      expect(state, isA<PersistenceUnavailable>());
    });
  });
}
