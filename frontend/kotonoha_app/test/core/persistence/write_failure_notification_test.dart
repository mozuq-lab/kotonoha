/// 書き込み失敗が利用者に伝わるかの検証（ADR-005 / 台帳 L-13）
/// 何を守るテストか: box が**開いていても**書き込みは失敗しうる
/// （ディスクフル・権限・Web の quota 超過）。hive 2.2.3 の `_writeFrames` は
/// 失敗時にトランザクションを取り消して再送出するだけで box を閉じないため
/// `Hive.isBoxOpen` は true のままになる。
/// つまり「box が開いているか」だけを見ていると
/// **保存に失敗しているのにバナーが出ない**——この製品で最悪の
/// 「保存できたように見えて消える」が起きる。
/// モックの置き場所: Hive の `Box` は外部 SDK の境界なのでモックしてよい。
/// repository・notifier・provider・ウィジェットはすべて実物を通し
/// 検証は描画されたバナーで行う。
library;

import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:kotonoha_app/core/widgets/app_shell.dart';
import 'package:kotonoha_app/features/favorite/providers/favorite_provider.dart';
import 'package:kotonoha_app/shared/models/favorite_item.dart';
import 'package:kotonoha_app/shared/models/history_item.dart';
import 'package:kotonoha_app/shared/models/preset_phrase.dart';
import 'package:kotonoha_app/shared/providers/repository_providers.dart';
import 'package:mocktail/mocktail.dart';

class _MockFavoriteBox extends Mock implements Box<FavoriteItem> {}

class _MockHistoryBox extends Mock implements Box<HistoryItem> {}

class _MockPresetPhraseBox extends Mock implements Box<PresetPhrase> {}

class _FakeFavoriteItem extends Fake implements FavoriteItem {}

void main() {
  setUpAll(() {
    registerFallbackValue(_FakeFavoriteItem());
  });

  /// 準備: 3つの box はすべて開いている。お気に入りの書き込みだけが
  /// ディスクフルで失敗する。
  ProviderContainer buildContainer(Box<FavoriteItem> favoriteBox) {
    final historyBox = _MockHistoryBox();
    when(() => historyBox.values).thenReturn(<HistoryItem>[]);
    final presetBox = _MockPresetPhraseBox();
    when(() => presetBox.values).thenReturn(<PresetPhrase>[]);

    return ProviderContainer(
      overrides: [
        favoriteBoxProvider.overrideWithValue(favoriteBox),
        historyBoxProvider.overrideWithValue(historyBox),
        presetPhraseBoxProvider.overrideWithValue(presetBox),
      ],
    );
  }

  Box<FavoriteItem> failingFavoriteBox() {
    final box = _MockFavoriteBox();
    when(() => box.values).thenReturn(<FavoriteItem>[]);
    when(() => box.put(any<dynamic>(), any())).thenThrow(
      const FileSystemException('No space left on device'),
    );
    return box;
  }

  Box<FavoriteItem> workingFavoriteBox() {
    final box = _MockFavoriteBox();
    when(() => box.values).thenReturn(<FavoriteItem>[]);
    when(() => box.put(any<dynamic>(), any())).thenAnswer((_) async {});
    return box;
  }

  Future<void> pumpShell(
      WidgetTester tester, ProviderContainer container) async {
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: const MaterialApp(
          home: AppShell(child: Scaffold(body: Text('画面本体'))),
        ),
      ),
    );
    await tester.pump();
  }

  group('box は開いているが書き込みが失敗する', () {
    testWidgets('保存に失敗したら、その領域が保存できないと利用者に伝わる', (tester) async {
      final container = buildContainer(failingFavoriteBox());
      addTearDown(container.dispose);

      await pumpShell(tester, container);
      // 前提: 書き込み前は警告が出ていない
      expect(find.textContaining('保存できません'), findsNothing);

      await container.read(favoriteProvider.notifier).addFavorite('みずをください');
      await tester.pump();

      expect(find.textContaining('お気に入り'), findsOneWidget);
      expect(find.textContaining('保存できません'), findsOneWidget);
    });

    testWidgets('失敗しても操作は止まらず、画面本体は使える（NFR-301）', (tester) async {
      final container = buildContainer(failingFavoriteBox());
      addTearDown(container.dispose);

      await pumpShell(tester, container);
      await container.read(favoriteProvider.notifier).addFavorite('みずをください');
      await tester.pump();

      expect(find.text('画面本体'), findsOneWidget);
    });

    testWidgets('書き込みが成功する領域は警告の対象にならない', (tester) async {
      final container = buildContainer(workingFavoriteBox());
      addTearDown(container.dispose);

      await pumpShell(tester, container);
      await container.read(favoriteProvider.notifier).addFavorite('みずをください');
      await tester.pump();

      expect(find.textContaining('保存できません'), findsNothing);
    });

    testWidgets('次の書き込みが成功したら警告は消える（自己回復）', (tester) async {
      // なぜ: ディスクフルは解消しうる。一度の失敗で恒久的に警告を出し
      // 続けると、利用者は直っても分からない。
      final box = _MockFavoriteBox();
      when(() => box.values).thenReturn(<FavoriteItem>[]);
      when(() => box.put(any<dynamic>(), any())).thenThrow(
        const FileSystemException('No space left on device'),
      );

      final container = buildContainer(box);
      addTearDown(container.dispose);

      await pumpShell(tester, container);
      await container.read(favoriteProvider.notifier).addFavorite('みずをください');
      await tester.pump();
      expect(find.textContaining('保存できません'), findsOneWidget);

      when(() => box.put(any<dynamic>(), any())).thenAnswer((_) async {});
      await container.read(favoriteProvider.notifier).addFavorite('ありがとう');
      await tester.pump();

      expect(find.textContaining('保存できません'), findsNothing);
    });
  });
}
