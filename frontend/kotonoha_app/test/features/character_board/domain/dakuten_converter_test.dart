/// DakutenConverter テスト
///
/// 濁音・半濁音キー「゛」「゜」タップ時の変換ロジックを検証する。
/// 濁音20文字・半濁音5文字の全パターンを網羅する。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/domain/dakuten_converter.dart';

void main() {
  group('DakutenConverter.applyDakuten', () {
    const seionToDakuon = {
      'か': 'が',
      'き': 'ぎ',
      'く': 'ぐ',
      'け': 'げ',
      'こ': 'ご',
      'さ': 'ざ',
      'し': 'じ',
      'す': 'ず',
      'せ': 'ぜ',
      'そ': 'ぞ',
      'た': 'だ',
      'ち': 'ぢ',
      'つ': 'づ',
      'て': 'で',
      'と': 'ど',
      'は': 'ば',
      'ひ': 'び',
      'ふ': 'ぶ',
      'へ': 'べ',
      'ほ': 'ぼ',
    };

    seionToDakuon.forEach((seion, dakuon) {
      test('清音「$seion」は濁音「$dakuon」に変換される', () {
        expect(DakutenConverter.applyDakuten(seion), dakuon);
      });

      test('濁音「$dakuon」は清音「$seion」にトグルで戻る', () {
        expect(DakutenConverter.applyDakuten(dakuon), seion);
      });
    });

    const seionToHandakuon = {
      'は': 'ぱ',
      'ひ': 'ぴ',
      'ふ': 'ぷ',
      'へ': 'ぺ',
      'ほ': 'ぽ',
    };

    seionToHandakuon.forEach((seion, handakuon) {
      final dakuon = seionToDakuon[seion]!;
      test('半濁音「$handakuon」に「゛」を押すと濁音「$dakuon」に変換される（は行内変換）', () {
        expect(DakutenConverter.applyDakuten(handakuon), dakuon);
      });
    });

    test('変換不能な文字（母音「あ」）はnullを返す', () {
      expect(DakutenConverter.applyDakuten('あ'), isNull);
    });

    test('変換不能な文字（拗音「ゃ」）はnullを返す', () {
      expect(DakutenConverter.applyDakuten('ゃ'), isNull);
    });

    test('変換不能な文字（記号「。」）はnullを返す', () {
      expect(DakutenConverter.applyDakuten('。'), isNull);
    });
  });

  group('DakutenConverter.applyHandakuten', () {
    const seionToHandakuon = {
      'は': 'ぱ',
      'ひ': 'ぴ',
      'ふ': 'ぷ',
      'へ': 'ぺ',
      'ほ': 'ぽ',
    };

    seionToHandakuon.forEach((seion, handakuon) {
      test('清音「$seion」は半濁音「$handakuon」に変換される', () {
        expect(DakutenConverter.applyHandakuten(seion), handakuon);
      });

      test('半濁音「$handakuon」は清音「$seion」にトグルで戻る', () {
        expect(DakutenConverter.applyHandakuten(handakuon), seion);
      });

      test('濁音に「゜」を押すと半濁音に変換される（は行内変換）', () {
        const seionToDakuonForHaRow = {
          'は': 'ば',
          'ひ': 'び',
          'ふ': 'ぶ',
          'へ': 'べ',
          'ほ': 'ぼ',
        };
        final dakuon = seionToDakuonForHaRow[seion]!;
        expect(DakutenConverter.applyHandakuten(dakuon), handakuon);
      });
    });

    test('半濁音化不能な清音（か行）はnullを返す', () {
      expect(DakutenConverter.applyHandakuten('か'), isNull);
    });

    test('半濁音化不能な濁音（が）はnullを返す', () {
      expect(DakutenConverter.applyHandakuten('が'), isNull);
    });

    test('変換不能な文字（母音「あ」）はnullを返す', () {
      expect(DakutenConverter.applyHandakuten('あ'), isNull);
    });
  });
}
