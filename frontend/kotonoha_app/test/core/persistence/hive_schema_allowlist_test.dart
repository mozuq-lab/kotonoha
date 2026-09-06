/// Hive スキーマ許可リスト（ADR-005 の「検査」条項 / ADR-007 リリース条件1d）
///
/// **何を守るのか**: 端末内にしか無い利用者のデータ（履歴・定型文・お気に入り）が、
/// 永続化スキーマの無断変更で読めなくなること。実例は WP2 にある——`PresetPhrase` の
/// フィールド番号を詰めると、旧バイト列で `fields[3]`（bool）を `displayOrder`（int）
/// として読んで `TypeError` が出る。`hive_init.dart` の `_isCorruptionError` は
/// `TypeError` を破損とみなさないので「環境起因」に落ち、**box を開けないまま null を
/// 返す**。利用者から見ると定型文が全消えし、アプリは無言でインメモリ動作を続ける。
/// 発話で訂正できず端末内にしかデータが無い利用者にとって、これが最悪の事象である。
///
/// **どの経路を守るのか（WP5 着手時に決めた。台帳 L-31 への回答）**:
/// **本番の登録経路そのもの**。この検査は `registerPersistedTypeAdapters()` を
/// 呼ぶ——`initHive()` が呼ぶのと同じ関数である。テストが本番と別の登録手順を
/// 再現すると、本番側にだけ足された永続面を見逃す（L-31 が指摘した形）。
/// `initHive()` 全体は `Hive.initFlutter()`（path_provider プラグイン）を通るため
/// テストから呼べないので、**登録の段だけを本番と共有する**形にしてある。
///
/// **なぜ自作の検出器ではないのか（ADR-008 / `verification-principles.md` P1 の処方箋）**:
/// 3つの検査はいずれも**権威の出力を消費する**だけで、権威を再実装していない。
///
/// | 検査 | 権威 | 消費するもの |
/// |---|---|---|
/// | A. 面が増えていないか | Hive のレジストリ | `Hive.isAdapterRegistered` の応答 |
/// | B. 面の形が変わっていないか | TypeAdapter 自身 | `write()` が出す呼び出し列 |
/// | C. box が増えていないか | `PersistedArea` | enum の値と `boxName` |
///
/// **`lib/` のソースを文字列照合してはいけない**（台帳 L-32 で236行の検出器を規約違反
/// として削除している）。この検査は1行もソースを読まない。
///
/// **完全一致で比較していることについて**: プロジェクトの規律は「完全一致アサーションを
/// 書かない（実装を安全側に変えたときに落ちるアサーションは仕様ではない）」だが、
/// **ここでは完全一致が仕様である。** リリース条件1d は「増えたら CI で落とす」ことを
/// 求めており、安全な追加（末尾へのフィールド追加）でも人が確認するまで赤にするのが目的。
/// これを「スナップショットだから」と削除しないこと。
///
/// **赤にしたときの直し方**: 差分が意図したものなら、下の許可リストを更新し、
/// **根拠となる ADR をコミットメッセージに引用する**（AGENTS.md「負債を作る行為には
/// 理由が要る」— 永続化面の追加）。番号を詰め直していないかを必ず確認すること。
///
/// **`testWidgets` を使わない理由**: 実 Hive を触るテストは FakeAsync と待ち合って
/// ハングする（`verification-principles.md` §3）。素の `test()` で書いている。
library;

import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:kotonoha_app/core/persistence/persistence_state.dart';
import 'package:kotonoha_app/core/utils/hive_init.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';

// ---------------------------------------------------------------------------
// 許可リスト本体。**ここを増やすときは ADR の引用が要る。**
// ---------------------------------------------------------------------------

/// 検査A: 本番の登録経路が Hive へ登録してよい typeId
///
/// typeId を増やす＝新しい永続化面を足すこと。
const _allowedTypeIds = <int>{0, 1, 2};

/// 検査C: 開いてよい box の名前（`PersistedArea` の値 → box 名）
///
/// box を増やす＝新しい永続化面を足すこと。
const _allowedBoxNames = <String, String>{
  'history': 'history',
  'presetPhrases': 'presetPhrases',
  'favorites': 'favorites',
};

/// 検査B: 各 TypeAdapter の `write()` が出す呼び出し列
///
/// `byte(N)` は `writeByte(N)`、`write(T)` は `write()` に渡った値の実行時型。
/// 先頭の `byte(N)` がフィールド数、以降は「フィールド番号, 値」の繰り返し。
/// **欠番はここに現れない**（`PresetPhrase` に 3 が無いのは旧 `isFavorite` の欠番）。
const _allowedWriteCalls = <String, List<String>>{
  'HistoryItemAdapter': <String>[
    'byte(4)',
    'byte(0)', 'write(String)', // id
    'byte(1)', 'write(String)', // content
    'byte(2)', 'write(DateTime)', // createdAt
    'byte(3)', 'write(String)', // type
    // 欠番 4: 旧 isFavorite（WP2 Stage 4 で削除）。番号は詰めない
  ],
  'PresetPhraseAdapter': <String>[
    'byte(6)',
    'byte(0)', 'write(String)', // id
    'byte(1)', 'write(String)', // content
    'byte(2)', 'write(String)', // category
    // 欠番 3: 旧 isFavorite（WP2 Stage 3b で削除）。**詰めると旧データが読めなくなる**
    'byte(4)', 'write(int)', // displayOrder
    'byte(5)', 'write(DateTime)', // createdAt
    'byte(6)', 'write(DateTime)', // updatedAt
  ],
  'FavoriteItemAdapter': <String>[
    'byte(6)',
    'byte(0)', 'write(String)', // id
    'byte(1)', 'write(String)', // content
    'byte(2)', 'write(DateTime)', // createdAt
    'byte(3)', 'write(int)', // displayOrder
    'byte(4)', 'write(String)', // sourceType（String?。fixture は非 null）
    'byte(5)', 'write(String)', // sourceId（String?。fixture は非 null）
  ],
};

/// 検査B に使う値。**アダプタごとに1つ必ず要る**（無ければ検査が空振りする）。
///
/// キーはアダプタのクラス名。**本番の登録経路が返した実体**に対してこの値を
/// 書かせる（テスト側で `XxxAdapter()` を new し直すと、typeId を据え置いたまま
/// クラスを差し替える変更が素通りする）。
Map<String, Object> buildFixtures() => <String, Object>{
      'HistoryItemAdapter': HistoryItem(
        id: 'fixture-history',
        content: 'みずをください',
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
        type: 'manualInput',
      ),
      'PresetPhraseAdapter': PresetPhrase(
        id: 'fixture-preset',
        content: 'ありがとう',
        category: 'daily',
        displayOrder: 3,
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
        updatedAt: DateTime(2026, 2, 3, 4, 5, 6),
      ),
      'FavoriteItemAdapter': FavoriteItem(
        id: 'fixture-favorite',
        content: 'おはようございます',
        createdAt: DateTime(2026, 1, 2, 3, 4, 5),
        displayOrder: 5,
        sourceType: 'preset_phrase',
        sourceId: 'fixture-preset',
      ),
    };

void main() {
  group('Hive スキーマ許可リスト', () {
    /// 本番の登録経路が登録したアダプタの実体
    late List<TypeAdapter<dynamic>> registered;

    setUp(() {
      // 権威をまっさらにする: 既定アダプタも消えるが、この検査は
      // エンコードを行わないので影響しない（hive 2.2.3 `HiveInterface.resetAdapters`）。
      //
      // **このファイルに「実 box へ書く」テストを足さないこと。**
      // hive 2.2.3 の `HiveImpl` は既定アダプタ（DateTime 等）を
      // コンストラクタでしか登録しないため、reset 後は再登録されず、
      // 実書き込みは `HiveError: Cannot write, unknown type: DateTime` で落ちる。
      Hive.resetAdapters();

      // 本番と同じ関数を呼ぶ: 検査 A も B も、この1回の呼び出しの結果だけを見る。
      registered = <TypeAdapter<dynamic>>[];
      registerPersistedTypeAdapters(onRegistered: registered.add);
    });

    // -----------------------------------------------------------------------
    // 検査A: 本番の登録経路が、許可された typeId しか登録しない
    // -----------------------------------------------------------------------
    group('A. 永続化面（typeId）が無断で増えていない', () {
      test('Hive が「登録済み」と答える typeId が許可リストと一致する', () {
        expect(
          _registeredTypeIds(),
          _allowedTypeIds,
          reason: '永続化面を増やしたなら、根拠 ADR を引用して許可リストを更新すること。'
              '**その際 _allowedWriteCalls と buildFixtures() にも必ず足すこと**'
              '（足さないと、そのアダプタのフィールドは以後どの検査も見ない）',
        );
      });

      test('本番が登録するアダプタの typeId 列が、重複なく許可リストと一致する', () {
        // 集合ではなく列で比べる理由: 集合だと同じアダプタを2回登録する
        // 変更が素通りする。順序と重複まで固定する。
        expect(
          registered.map((adapter) => adapter.typeId).toList(),
          _allowedTypeIds.toList(),
        );
      });
    });

    // -----------------------------------------------------------------------
    // 検査B: 永続フィールドの並びと型が変わっていない
    // -----------------------------------------------------------------------
    group('B. 永続フィールドの形が変わっていない', () {
      test('検査対象のアダプタ集合が、本番の登録経路と一致する', () {
        // これが A と B をつなぐ: 許可リスト B に載っていないアダプタが
        // 本番で登録されていたら赤にする。これが無いと、typeId だけ許可リストに
        // 足した4つ目のアダプタが恒久的に無検査になる。
        expect(
          registered.map((adapter) => adapter.runtimeType.toString()).toSet(),
          _allowedWriteCalls.keys.toSet(),
          reason: '本番が登録するアダプタと、形を固定してある一覧がずれている',
        );
      });

      test('各アダプタの write() が出す呼び出し列が許可リストと一致する', () {
        final fixtures = buildFixtures();

        for (final adapter in registered) {
          final name = adapter.runtimeType.toString();
          final fixture = fixtures[name];
          expect(
            fixture,
            isNotNull,
            reason: '$name に対応する fixture が無い。fixture が無いとこの検査は空振りする',
          );

          final recorder = _RecordingBinaryWriter();
          // 権威: テストで new し直さず、**本番の登録経路が返した実体**に書かせる。
          adapter.write(recorder, fixture!);

          expect(
            recorder.calls,
            _allowedWriteCalls[name],
            reason: '$name の永続フィールドの並び・型・数が変わっている。'
                '**残るフィールドの番号を詰め直していないか**を必ず確認すること'
                '（詰めると端末の既存データが TypeError で読めなくなり、'
                'box が開かないまま無言でインメモリ動作になる）',
          );
        }
      });
    });

    // -----------------------------------------------------------------------
    // 検査C: box が無断で増えていない
    // -----------------------------------------------------------------------
    test('C. 開く box が許可リストと一致する', () {
      final actual = <String, String>{
        for (final area in PersistedArea.values) area.name: area.boxName,
      };

      expect(
        actual,
        _allowedBoxNames,
        reason: 'box を増やす／名前を変えるのは永続化面の変更。'
            '根拠 ADR を引用して許可リストを更新すること',
      );
    });
  });
}

/// Hive のレジストリに問い合わせて、登録済みの typeId を集める
///
/// **権威（Hive 本体）の応答をそのまま読む。** `lib/` のソースは一切見ない。
/// hive 2.2.3 は typeId 0〜223 のみ許可し、範囲外は `HiveError` を投げる
/// （`type_registry_impl.dart` の `isAdapterRegistered`）。
Set<int> _registeredTypeIds() => <int>{
      for (var typeId = 0; typeId <= 223; typeId++)
        if (Hive.isAdapterRegistered(typeId)) typeId,
    };

/// `TypeAdapter.write()` が呼んだ内容を記録するだけの [BinaryWriter]
///
/// **これは権威の再実装ではない。** バイト列を組み立てず、渡された呼び出しを
/// そのまま文字列にして並べるだけの観測器である。何が永続化されるかを決めるのは
/// あくまで各 TypeAdapter 自身。
///
/// アダプタが `write()` 以外の書き込みメソッドを使い始めた場合も、
/// 別のトークンとして記録されるので許可リストとの差分になる（フェイルクローズ）。
class _RecordingBinaryWriter implements BinaryWriter {
  /// 記録された呼び出し列
  final List<String> calls = <String>[];

  @override
  void writeByte(int byte) => calls.add('byte($byte)');

  @override
  void write<T>(T value, {bool writeTypeId = true}) =>
      calls.add('write(${value.runtimeType})');

  @override
  void writeWord(int value) => calls.add('word');

  @override
  void writeInt32(int value) => calls.add('int32');

  @override
  void writeUint32(int value) => calls.add('uint32');

  @override
  void writeInt(int value) => calls.add('int');

  @override
  void writeDouble(double value) => calls.add('double');

  @override
  void writeBool(bool value) => calls.add('bool');

  @override
  void writeString(
    String value, {
    bool writeByteCount = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) =>
      calls.add('string');

  @override
  void writeByteList(List<int> bytes, {bool writeLength = true}) =>
      calls.add('byteList');

  @override
  void writeIntList(List<int> list, {bool writeLength = true}) =>
      calls.add('intList');

  @override
  void writeDoubleList(List<double> list, {bool writeLength = true}) =>
      calls.add('doubleList');

  @override
  void writeBoolList(List<bool> list, {bool writeLength = true}) =>
      calls.add('boolList');

  @override
  void writeStringList(
    List<String> list, {
    bool writeLength = true,
    Converter<String, List<int>> encoder = BinaryWriter.utf8Encoder,
  }) =>
      calls.add('stringList');

  @override
  void writeList(List<dynamic> list, {bool writeLength = true}) =>
      calls.add('list');

  @override
  void writeMap(Map<dynamic, dynamic> map, {bool writeLength = true}) =>
      calls.add('map');

  // ignore の理由: hive 2.2.3 の `HiveList` は experimental 指定だが、
  // `BinaryWriter` を implements する以上このメソッドの実装は省けない。
  // 本アプリは HiveList を使っていないので、記録するだけで呼ばれることはない。
  @override
  // ignore: experimental_member_use
  void writeHiveList(HiveList<dynamic> list, {bool writeLength = true}) =>
      calls.add('hiveList');
}
