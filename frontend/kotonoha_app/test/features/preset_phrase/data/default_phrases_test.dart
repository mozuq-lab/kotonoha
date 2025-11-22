/// DefaultPhrases - 初期定型文データのテスト
///
/// TASK-0042: 定型文初期データ（50-100個サンプル）
///
/// テスト内容:
/// - 定型文データの存在確認
/// - カテゴリ別のデータ件数確認
/// - 定型文の重複チェック
/// - 空文字列のチェック
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/preset_phrase/data/default_phrases.dart';

void main() {
  group('DefaultPhrases', () {
    group('dailyPhrases', () {
      test('日常カテゴリの定型文が20個以上存在すること', () {
        expect(DefaultPhrases.dailyPhrases.length, greaterThanOrEqualTo(20));
      });

      test('日常カテゴリの定型文が空文字を含まないこと', () {
        for (final phrase in DefaultPhrases.dailyPhrases) {
          expect(phrase.trim(), isNotEmpty, reason: 'Empty phrase found');
        }
      });

      test('日常カテゴリの定型文に重複がないこと', () {
        final uniquePhrases = DefaultPhrases.dailyPhrases.toSet();
        expect(
          uniquePhrases.length,
          equals(DefaultPhrases.dailyPhrases.length),
          reason: 'Duplicate phrases found in dailyPhrases',
        );
      });
    });

    group('healthPhrases', () {
      test('体調カテゴリの定型文が20個以上存在すること', () {
        expect(DefaultPhrases.healthPhrases.length, greaterThanOrEqualTo(20));
      });

      test('体調カテゴリの定型文が空文字を含まないこと', () {
        for (final phrase in DefaultPhrases.healthPhrases) {
          expect(phrase.trim(), isNotEmpty, reason: 'Empty phrase found');
        }
      });

      test('体調カテゴリの定型文に重複がないこと', () {
        final uniquePhrases = DefaultPhrases.healthPhrases.toSet();
        expect(
          uniquePhrases.length,
          equals(DefaultPhrases.healthPhrases.length),
          reason: 'Duplicate phrases found in healthPhrases',
        );
      });
    });

    group('otherPhrases', () {
      test('その他カテゴリの定型文が10個以上存在すること', () {
        expect(DefaultPhrases.otherPhrases.length, greaterThanOrEqualTo(10));
      });

      test('その他カテゴリの定型文が空文字を含まないこと', () {
        for (final phrase in DefaultPhrases.otherPhrases) {
          expect(phrase.trim(), isNotEmpty, reason: 'Empty phrase found');
        }
      });

      test('その他カテゴリの定型文に重複がないこと', () {
        final uniquePhrases = DefaultPhrases.otherPhrases.toSet();
        expect(
          uniquePhrases.length,
          equals(DefaultPhrases.otherPhrases.length),
          reason: 'Duplicate phrases found in otherPhrases',
        );
      });
    });

    group('totalCount', () {
      test('全定型文が50個以上存在すること (REQ-107)', () {
        expect(DefaultPhrases.totalCount, greaterThanOrEqualTo(50));
      });

      test('全定型文が100個以下であること', () {
        expect(DefaultPhrases.totalCount, lessThanOrEqualTo(100));
      });

      test('全定型文の合計が正しいこと', () {
        final expectedTotal = DefaultPhrases.dailyPhrases.length +
            DefaultPhrases.healthPhrases.length +
            DefaultPhrases.otherPhrases.length;
        expect(DefaultPhrases.totalCount, equals(expectedTotal));
      });
    });

    group('getAllPhrases', () {
      test('3つのカテゴリが返されること', () {
        final allPhrases = DefaultPhrases.getAllPhrases();
        expect(allPhrases.keys, containsAll(['daily', 'health', 'other']));
        expect(allPhrases.length, equals(3));
      });

      test('各カテゴリのデータが正しいこと', () {
        final allPhrases = DefaultPhrases.getAllPhrases();
        expect(allPhrases['daily'], equals(DefaultPhrases.dailyPhrases));
        expect(allPhrases['health'], equals(DefaultPhrases.healthPhrases));
        expect(allPhrases['other'], equals(DefaultPhrases.otherPhrases));
      });
    });

    group('cross-category uniqueness', () {
      test('全カテゴリ間で定型文の重複がないこと', () {
        final allPhrases = <String>[
          ...DefaultPhrases.dailyPhrases,
          ...DefaultPhrases.healthPhrases,
          ...DefaultPhrases.otherPhrases,
        ];
        final uniquePhrases = allPhrases.toSet();
        expect(
          uniquePhrases.length,
          equals(allPhrases.length),
          reason: 'Duplicate phrases found across categories',
        );
      });
    });
  });
}
