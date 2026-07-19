/// 緊急音アセットファイルの実データ検証テスト
///
/// 緊急呼び出し機能の中核である緊急音が「0バイトの空ファイル」に
/// 退行しないことを保証するための回帰テスト。
/// 関連要件: REQ-303（緊急音発生）, REQ-2005
///
/// 【背景】: 過去に assets/audio/emergency_alarm.mp3 が0バイトの空ファイルとなっており、
/// 配線（EmergencyAudioService）自体は正しいにもかかわらず実機で音が鳴らない
/// 不具合があった。本テストはアセットファイルの存在・非ゼロサイズを検証することで
/// 同様の退行を検知する。
library;

import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

void main() {
  group('緊急音アセットファイル検証', () {
    /// EmergencyAudioServiceが参照するアセットパスから実ファイルパスを解決する。
    ///
    /// EmergencyAudioServiceはprivateな定数として音声パスを保持しているため、
    /// 直接参照はできない。そのため、AssetSourceに渡される値と同じ規約
    /// （'audio/<filename>' -> 'assets/audio/<filename>'）で解決する。
    /// ファイル名自体は emergency_audio_service_test.dart の
    /// TC-047-004（AssetSourceパス検証）でも 'audio/emergency_alarm.m4a' として
    /// 固定的に検証されており、本テストはそのファイルが実データとして
    /// 存在することを保証する。
    const assetRelativePath = 'audio/emergency_alarm.m4a';

    test('緊急音ファイルがassets/audio配下に実データとして存在する', () {
      final file = File('assets/$assetRelativePath');

      expect(
        file.existsSync(),
        isTrue,
        reason: '緊急音ファイル assets/$assetRelativePath が存在する必要がある',
      );
    });

    test('緊急音ファイルが0バイトの空ファイルではない', () {
      final file = File('assets/$assetRelativePath');
      final sizeBytes = file.lengthSync();

      expect(
        sizeBytes,
        greaterThan(0),
        reason: '緊急音ファイルが0バイトの場合、実機で緊急音が鳴らない致命的な不具合となる',
      );

      // 極端に小さいファイル（壊れたヘッダのみ等）も実質的に無音である可能性があるため、
      // 数百バイト以上のデータが含まれていることも確認する。
      expect(
        sizeBytes,
        greaterThan(500),
        reason: '緊急音ファイルは意味のある音声データを含む必要がある（極小ファイルは実質無音の疑い）',
      );
    });

    test('mp3の空ファイルが残存していない（旧アセットの退行防止）', () {
      final legacyFile = File('assets/audio/emergency_alarm.mp3');

      expect(
        legacyFile.existsSync(),
        isFalse,
        reason: '0バイトだった旧emergency_alarm.mp3は削除済みである必要がある',
      );
    });
  });
}
