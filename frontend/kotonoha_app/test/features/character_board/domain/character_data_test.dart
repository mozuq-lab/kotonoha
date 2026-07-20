/// CharacterData 特殊キー（濁点・半濁点・空白）テスト
///
/// 基本タブのスペーサーセル位置に配置した特殊キーの定義・判定・表示ラベルを検証する。
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/character_board/domain/character_data.dart';

void main() {
  group('CharacterData 特殊キー配置', () {
    test('基本タブに濁点キーが含まれる', () {
      expect(CharacterData.basic, contains(CharacterData.dakutenKey));
    });

    test('基本タブに半濁点キーが含まれる', () {
      expect(CharacterData.basic, contains(CharacterData.handakutenKey));
    });

    test('基本タブに空白キーが含まれる', () {
      expect(CharacterData.basic, contains(CharacterData.spaceKey));
    });

    test('特殊キー追加後も行数が変わらない（50セルのまま）', () {
      // 【設計意図】: 既存のスペーサー（空文字）セルを転用しているため、
      // basicリストの要素数は変化しない。
      expect(CharacterData.basic.length, 50);
    });

    test('既存の五十音文字（や・ゆ・よ・わ・を・ん）はそのまま残っている', () {
      expect(CharacterData.basic, containsAll(['や', 'ゆ', 'よ', 'わ', 'を', 'ん']));
    });
  });

  group('CharacterData.isDakutenKey / isHandakutenKey / isSpaceKey', () {
    test('isDakutenKeyは濁点キーに対してtrueを返す', () {
      expect(CharacterData.isDakutenKey(CharacterData.dakutenKey), isTrue);
    });

    test('isDakutenKeyは通常文字に対してfalseを返す', () {
      expect(CharacterData.isDakutenKey('か'), isFalse);
    });

    test('isHandakutenKeyは半濁点キーに対してtrueを返す', () {
      expect(
        CharacterData.isHandakutenKey(CharacterData.handakutenKey),
        isTrue,
      );
    });

    test('isHandakutenKeyは通常文字に対してfalseを返す', () {
      expect(CharacterData.isHandakutenKey('は'), isFalse);
    });

    test('isSpaceKeyは空白キーに対してtrueを返す', () {
      expect(CharacterData.isSpaceKey(CharacterData.spaceKey), isTrue);
    });

    test('isSpaceKeyは通常文字に対してfalseを返す', () {
      expect(CharacterData.isSpaceKey('あ'), isFalse);
    });
  });

  group('CharacterData.getDisplayLabel', () {
    test('空白キーは「空白」というラベルを返す', () {
      expect(CharacterData.getDisplayLabel(CharacterData.spaceKey), '空白');
    });

    test('濁点キーはそのままの記号を返す', () {
      expect(
        CharacterData.getDisplayLabel(CharacterData.dakutenKey),
        CharacterData.dakutenKey,
      );
    });

    test('通常文字はそのまま返す', () {
      expect(CharacterData.getDisplayLabel('あ'), 'あ');
    });
  });

  group('CharacterData.getAccessibilityLabel', () {
    test('濁点キーは「濁点」というラベルを返す', () {
      expect(
        CharacterData.getAccessibilityLabel(CharacterData.dakutenKey),
        '濁点',
      );
    });

    test('半濁点キーは「半濁点」というラベルを返す', () {
      expect(
        CharacterData.getAccessibilityLabel(CharacterData.handakutenKey),
        '半濁点',
      );
    });

    test('空白キーは「空白」というラベルを返す', () {
      expect(
        CharacterData.getAccessibilityLabel(CharacterData.spaceKey),
        '空白',
      );
    });

    test('通常文字はそのまま返す', () {
      expect(CharacterData.getAccessibilityLabel('あ'), 'あ');
    });
  });
}
