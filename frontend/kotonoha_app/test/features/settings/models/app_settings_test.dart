/// AppSettings モデルテスト (TTS速度設定)
///
/// TASK-0049: TTS速度設定（遅い/普通/速い）
/// テストケース: TC-049-001〜TC-049-004, TC-049-011, TC-049-016
///
/// テスト対象: lib/features/settings/models/app_settings.dart
///
/// 【TDD Redフェーズ】: ttsSpeedフィールドが未実装、テストが失敗するはず
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

void main() {
  group('AppSettings - TTS速度設定テスト', () {
    // =========================================================================
    // 正常系テストケース
    // =========================================================================
    group('正常系テスト', () {
      /// TC-049-001: AppSettings.ttsSpeedのデフォルト値確認
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: デフォルト値がnormal（1.0倍速）であること
      test('TC-049-001: AppSettings初期化時にttsSpeedがデフォルト値（normal）であることを確認', () {
        // 【テスト目的】: TTS速度設定がデフォルト値（normal）であることを確認 🔵
        // 【テスト内容】: AppSettingsをデフォルトコンストラクタで初期化し、ttsSpeedフィールドを検証
        // 【期待される動作】: ttsSpeed == TTSSpeed.normal（1.0倍速）
        // 🔵 青信号: interfaces.dart（213-274行目）、requirements.md（79-84行目）に基づく

        // Given: 【テストデータ準備】: アプリ初回起動時の状態を模擬（shared_preferencesが空）
        // 【初期条件設定】: デフォルトコンストラクタでAppSettingsを作成
        // 【前提条件確認】: TTS速度が未設定であることを確認
        const appSettings = AppSettings();

        // Then: 【結果検証】: ttsSpeedがnormalに設定されたことを確認
        // 【期待値確認】: REQ-404の3段階選択要件を満たすため
        // 【品質保証】: ユーザーが明示的に速度を選択するまで、標準的な速度（1.0倍速）で読み上げが行われることを保証
        expect(appSettings.ttsSpeed,
            TTSSpeed.normal); // 【確認内容】: デフォルト速度がnormalであることを確認 🔵
      });

      /// TC-049-002: AppSettings.copyWith()でttsSpeedを更新
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: copyWithでttsSpeedのみを変更し、他のフィールドが保持されること
      test('TC-049-002: copyWithメソッドでttsSpeedのみを変更し、他のフィールドが保持されることを確認', () {
        // 【テスト目的】: copyWithでttsSpeedのみを変更し、他のフィールドが保持されることを確認 🔵
        // 【テスト内容】: copyWith(ttsSpeed: TTSSpeed.slow)を呼び出し、他のフィールドが元の値を保持することを検証
        // 【期待される動作】: ttsSpeedが変更され、fontSize、themeは元の値を保持
        // 🔵 青信号: Dartの不変オブジェクトパターン、既存テスト（settings_provider_test.dart TC-002）と同じパターン

        // Given: 【テストデータ準備】: カスタマイズされた設定を持つAppSettingsを作成
        // 【初期条件設定】: ユーザーが既に設定をカスタマイズしている状態（フォントサイズ「大」、ダークモード）
        const original = AppSettings(
          fontSize: FontSize.large,
          theme: AppTheme.dark,
          ttsSpeed: TTSSpeed.normal,
        );

        // When: 【実際の処理実行】: copyWithでttsSpeedのみを変更
        // 【処理内容】: TTS速度のみを「遅い」に変更する
        final updated = original.copyWith(ttsSpeed: TTSSpeed.slow);

        // Then: 【結果検証】: ttsSpeedが変更され、他のフィールドが保持されていることを確認
        // 【期待値確認】: 不変オブジェクトパターンの正しい実装を保証
        // 【品質保証】: 設定の一部のみを変更する際に、他の設定が意図せず変更されないことを確認
        expect(
            updated.ttsSpeed, TTSSpeed.slow); // 【確認内容】: ttsSpeedが変更されたことを確認 🔵
        expect(
            updated.fontSize, FontSize.large); // 【確認内容】: fontSizeが保持されたことを確認 🔵
        expect(updated.theme, AppTheme.dark); // 【確認内容】: themeが保持されたことを確認 🔵
        expect(identical(original, updated),
            isFalse); // 【確認内容】: 新しいインスタンスが生成されたことを確認 🔵
      });

      /// TC-049-003: AppSettings.toJson()でttsSpeedがシリアライズされる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: toJsonでttsSpeedが文字列形式に変換されること
      test('TC-049-003: toJson()メソッドでttsSpeedが正しくJSON形式に変換されることを確認', () {
        // 【テスト目的】: toJsonでttsSpeedが正しくJSON形式に変換されることを確認 🔵
        // 【テスト内容】: toJson()を呼び出し、ttsSpeedフィールドが文字列形式（'slow'/'normal'/'fast'）でJSONに含まれることを検証
        // 【期待される動作】: JSONオブジェクトに'tts_speed'キーが含まれ、値はenum名の文字列
        // 🔵 青信号: requirements.md（82-84行目）で定義された保存形式（String型、'slow'/'normal'/'fast'）

        // Given: 【テストデータ準備】: 速度を「速い」に設定したAppSettingsを作成
        // 【初期条件設定】: ユーザーが速度を「速い」に設定した状態を模擬
        const settings = AppSettings(ttsSpeed: TTSSpeed.fast);

        // When: 【実際の処理実行】: toJson()を呼び出す
        // 【処理内容】: shared_preferencesに保存する際のシリアライズ処理
        final json = settings.toJson();

        // Then: 【結果検証】: ttsSpeedが文字列形式で含まれていることを確認
        // 【期待値確認】: shared_preferencesへの保存前に、AppSettingsが正しくJSON形式に変換されることを確認
        // 【品質保証】: 永続化データの形式が仕様通りであることを保証
        expect(
            json['tts_speed'], 'fast'); // 【確認内容】: ttsSpeedが'fast'に変換されたことを確認 🔵
      });

      /// TC-049-004: AppSettings.fromJson()でttsSpeedがデシリアライズされる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-5003
      /// 検証内容: fromJsonでJSON形式からttsSpeedが復元されること
      test('TC-049-004: fromJson()メソッドでJSON形式からttsSpeedが正しく復元されることを確認', () {
        // 【テスト目的】: fromJsonでJSON形式からttsSpeedが正しく復元されることを確認 🔵
        // 【テスト内容】: fromJson({'tts_speed': 'slow'})を呼び出し、ttsSpeedフィールドがTTSSpeed.slowに正しく変換されることを検証
        // 【期待される動作】: JSON文字列からenum値への変換が正しく行われる
        // 🔵 青信号: requirements.md（133-136行目）、REQ-5003に基づく

        // Given: 【テストデータ準備】: shared_preferencesから読み込んだJSON形式のデータ
        // 【初期条件設定】: アプリ再起動時の設定復元処理を模擬
        final json = {
          'tts_speed': 'slow',
          'font_size': 'large',
          'theme': 'dark',
        };

        // When: 【実際の処理実行】: fromJson()を呼び出す
        // 【処理内容】: JSON文字列からAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 【結果検証】: ttsSpeedが正しく復元されたことを確認
        // 【期待値確認】: アプリ再起動時に、保存されたTTS速度が正しく復元されることを確認
        // 【品質保証】: データの永続化・復元サイクルが正しく機能することを保証
        expect(settings.ttsSpeed,
            TTSSpeed.slow); // 【確認内容】: ttsSpeedがslowに復元されたことを確認 🔵
        expect(settings.fontSize,
            FontSize.large); // 【確認内容】: fontSizeも正しく復元されたことを確認 🔵
        expect(settings.theme, AppTheme.dark); // 【確認内容】: themeも正しく復元されたことを確認 🔵
      });
    });

    // =========================================================================
    // 正常系テストケース（verySlow追加）
    // =========================================================================
    group('正常系テスト（verySlow追加）', () {
      /// TTC-VS-011: SharedPreferencesへの"verySlow"文字列の保存・復元
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: 「とても遅い」設定の永続化が正しく動作すること
      test('TTC-VS-011: AppSettings.fromJson()で"verySlow"が正しく復元されることを確認', () {
        // 【テスト目的】: 「とても遅い」設定の永続化が正しく動作することを確認 🔵
        // 【テスト内容】: fromJson({'tts_speed': 'verySlow'})を呼び出し、ttsSpeedがTTSSpeed.verySlowに変換されることを検証
        // 【期待される動作】: 文字列→enum変換が正確、保存→復元のサイクルで値が変わらない
        // 🔵 青信号: 既存テスト（tts_speed_integration_test.dart TC-049-015）のパターンに基づく

        // Given: 【テストデータ準備】: verySlowを含むJSONデータ
        // 【初期条件設定】: ユーザーが「とても遅い」を設定してアプリを閉じ、再度開く場合を模擬
        final json = {
          'tts_speed': 'verySlow',
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 【実際の処理実行】: fromJson()を呼び出す
        // 【処理内容】: JSON文字列からAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 【結果検証】: ttsSpeedがverySlowに復元されたことを確認
        // 【期待値確認】: 永続化データからの復元が正しく行われる
        // 【品質保証】: アプリ再起動後も設定が保持されることを保証
        expect(settings.ttsSpeed,
            TTSSpeed.verySlow); // 【確認内容】: ttsSpeedがverySlowに復元されたことを確認 🔵
      });

      /// TTC-VS-011b: AppSettings.toJson()で"verySlow"が正しく保存される
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: 「とても遅い」設定のシリアライズが正しく動作すること
      test(
          'TTC-VS-011b: AppSettings.toJson()でverySlowが"verySlow"文字列に変換されることを確認',
          () {
        // 【テスト目的】: 「とても遅い」設定のシリアライズが正しく動作することを確認 🔵
        // 【テスト内容】: toJson()を呼び出し、ttsSpeedが"verySlow"文字列に変換されることを検証
        // 【期待される動作】: enum→文字列変換が正確
        // 🔵 青信号: 既存テスト（TC-049-003）と同じパターン

        // Given: 【テストデータ準備】: 速度を「とても遅い」に設定したAppSettingsを作成
        // 【初期条件設定】: ユーザーが速度を「とても遅い」に設定した状態を模擬
        const settings = AppSettings(ttsSpeed: TTSSpeed.verySlow);

        // When: 【実際の処理実行】: toJson()を呼び出す
        // 【処理内容】: shared_preferencesに保存する際のシリアライズ処理
        final json = settings.toJson();

        // Then: 【結果検証】: ttsSpeedが"verySlow"文字列に変換されることを確認
        // 【期待値確認】: shared_preferencesへの保存前に正しく変換される
        // 【品質保証】: 永続化データの形式が仕様通りであることを保証
        expect(json['tts_speed'],
            'verySlow'); // 【確認内容】: ttsSpeedが'verySlow'に変換されたことを確認 🔵
      });

      /// TTC-VS-011c: AppSettings.copyWith()でttsSpeedをverySlowに更新できる
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: copyWithでverySlowへの変更が正しく動作すること
      test('TTC-VS-011c: copyWithメソッドでttsSpeedをverySlowに変更し、他のフィールドが保持されることを確認',
          () {
        // 【テスト目的】: copyWithでverySlowへの変更が正しく動作することを確認 🔵
        // 【テスト内容】: copyWith(ttsSpeed: TTSSpeed.verySlow)を呼び出し、他のフィールドが保持されることを検証
        // 【期待される動作】: ttsSpeedが変更され、fontSize、themeは元の値を保持
        // 🔵 青信号: 既存テスト（TC-049-002）と同じパターン

        // Given: 【テストデータ準備】: カスタマイズされた設定を持つAppSettingsを作成
        // 【初期条件設定】: ユーザーが既に設定をカスタマイズしている状態
        const original = AppSettings(
          fontSize: FontSize.large,
          theme: AppTheme.dark,
          ttsSpeed: TTSSpeed.normal,
        );

        // When: 【実際の処理実行】: copyWithでttsSpeedをverySlowに変更
        // 【処理内容】: TTS速度のみを「とても遅い」に変更する
        final updated = original.copyWith(ttsSpeed: TTSSpeed.verySlow);

        // Then: 【結果検証】: ttsSpeedが変更され、他のフィールドが保持されていることを確認
        // 【期待値確認】: 不変オブジェクトパターンの正しい実装を保証
        // 【品質保証】: 設定の一部のみを変更する際に、他の設定が意図せず変更されないことを確認
        expect(updated.ttsSpeed,
            TTSSpeed.verySlow); // 【確認内容】: ttsSpeedがverySlowに変更されたことを確認 🔵
        expect(
            updated.fontSize, FontSize.large); // 【確認内容】: fontSizeが保持されたことを確認 🔵
        expect(updated.theme, AppTheme.dark); // 【確認内容】: themeが保持されたことを確認 🔵
      });
    });

    // =========================================================================
    // 異常系テストケース
    // =========================================================================
    group('異常系テスト', () {
      /// TTC-VS-007: 不正な速度値からのフォールバック
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書、NFR-301
      /// 検証内容: 不正な値に対する安全な動作（verySlowを含む4段階対応）
      test(
          'TTC-VS-007: shared_preferencesに不正な値（\'invalid\'）が保存されている場合、デフォルト値（normal）にフォールバックすることを確認',
          () {
        // 【テスト目的】: 不正な値に対する安全な動作を確認（4段階速度対応後） 🔵
        // 【テスト内容】: fromJson()で不正な値（'invalid'）を渡した場合、デフォルト値（normal）にフォールバックすることを検証
        // 【期待される動作】: アプリがクラッシュせず、デフォルト速度で動作継続する
        // 🔵 青信号: 要件定義書のエラーケース仕様に基づく

        // Given: 【テストデータ準備】: 不正な値を含むJSONデータ
        // 【初期条件設定】: ストレージデータが破損している場合を模擬
        final json = {
          'tts_speed': 'invalid',
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 【実際の処理実行】: fromJson()を呼び出す
        // 【処理内容】: 不正な値からAppSettingsインスタンスを生成しようとする
        final settings = AppSettings.fromJson(json);

        // Then: 【結果検証】: デフォルト値にフォールバックされたことを確認
        // 【期待値確認】: エラーハンドリングの堅牢性を確認
        // 【システムの安全性】: エラー発生でもアプリがクラッシュしない
        expect(settings.ttsSpeed,
            TTSSpeed.normal); // 【確認内容】: デフォルト値normalにフォールバックしたことを確認 🔵
      });

      /// TTC-VS-008: 既存設定（"slow", "normal", "fast"）の後方互換性
      ///
      /// 優先度: P0（必須）
      /// 関連要件: TDD-TTS-SLOWER-SPEED要件定義書
      /// 検証内容: 古いバージョンの設定ファイルからの移行
      test('TTC-VS-008: 既存の3段階設定（slow/normal/fast）が正常に読み込まれることを確認', () {
        // 【テスト目的】: 既存の設定値が新バージョンでも正常に読み込まれることを確認 🔵
        // 【テスト内容】: 古いバージョンの設定（slow/normal/fast）が引き続き動作することを検証
        // 【期待される動作】: 既存ユーザーの設定が失われない
        // 🔵 青信号: 要件定義書の「後方互換性」セクションに基づく

        // Given: 【テストデータ準備】: 各既存設定のJSONデータ
        // 【初期条件設定】: アプリアップデート後の初回起動を模擬

        // slow: 既存の「遅い」設定
        final slowJson = {
          'tts_speed': 'slow',
          'font_size': 'medium',
          'theme': 'light',
        };
        final slowSettings = AppSettings.fromJson(slowJson);
        expect(slowSettings.ttsSpeed,
            TTSSpeed.slow); // 【確認内容】: slowが正しく復元されることを確認 🔵

        // normal: 既存の「普通」設定
        final normalJson = {
          'tts_speed': 'normal',
          'font_size': 'medium',
          'theme': 'light',
        };
        final normalSettings = AppSettings.fromJson(normalJson);
        expect(normalSettings.ttsSpeed,
            TTSSpeed.normal); // 【確認内容】: normalが正しく復元されることを確認 🔵

        // fast: 既存の「速い」設定
        final fastJson = {
          'tts_speed': 'fast',
          'font_size': 'medium',
          'theme': 'light',
        };
        final fastSettings = AppSettings.fromJson(fastJson);
        expect(fastSettings.ttsSpeed,
            TTSSpeed.fast); // 【確認内容】: fastが正しく復元されることを確認 🔵

        // 【確認ポイント】: ユーザーの既存設定が保持される
        // 【確認ポイント】: 既存ユーザーへの影響を最小化
      });

      /// TC-049-011: 不正な速度値がshared_preferencesに保存されている場合、デフォルト値にフォールバック
      ///
      /// 優先度: P1（高優先度）
      /// 関連要件: NFR-301, EDGE-3
      /// 検証内容: 不正な値に対する安全な動作
      test(
          'TC-049-011: shared_preferencesに不正な値（\'invalid\'）が保存されている場合、デフォルト値（normal）にフォールバックすることを確認',
          () {
        // 【テスト目的】: 不正な値に対する安全な動作を確認 🟡
        // 【テスト内容】: fromJson()で不正な値（'invalid'）を渡した場合、デフォルト値（normal）にフォールバックすることを検証
        // 【期待される動作】: アプリがクラッシュせず、デフォルト速度で動作継続する
        // 🟡 黄信号: requirements.md（310-319行目）のEDGE-3、NFR-301から類推

        // Given: 【テストデータ準備】: 不正な値を含むJSONデータ
        // 【初期条件設定】: ストレージデータが破損している場合を模擬
        // 【実際の発生シナリオ】: アプリのバージョンアップで速度の種類が変更された場合
        final json = {
          'tts_speed': 'invalid', // 不正な値
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 【実際の処理実行】: fromJson()を呼び出す
        // 【処理内容】: 不正な値からAppSettingsインスタンスを生成しようとする
        final settings = AppSettings.fromJson(json);

        // Then: 【結果検証】: デフォルト値にフォールバックされたことを確認
        // 【期待値確認】: エラーハンドリングの堅牢性を確認
        // 【システムの安全性】: エラー発生でもアプリがクラッシュしない
        expect(settings.ttsSpeed,
            TTSSpeed.normal); // 【確認内容】: デフォルト値normalにフォールバックしたことを確認 🟡
      });
    });

    // =========================================================================
    // 境界値テストケース
    // =========================================================================
    group('境界値テスト', () {
      /// TC-049-016: shared_preferencesに速度設定が存在しない場合、デフォルト値（normal）を使用
      ///
      /// 優先度: P0（必須）
      /// 関連要件: REQ-404
      /// 検証内容: null安全性の確認
      test(
          'TC-049-016: shared_preferencesに\'tts_speed\'キーが存在しない場合、デフォルト値（normal）が使用されることを確認',
          () {
        // 【テスト目的】: null安全性を確認 🔵
        // 【テスト内容】: fromJson()で'tts_speed'キーが存在しないJSONを渡した場合、デフォルト値（normal）が使用されることを検証
        // 【期待される動作】: データが存在しない場合の安全なフォールバック
        // 🔵 青信号: Dart Null Safetyの基本動作、既存テスト（settings_provider_test.dart TC-014）のパターンに基づく

        // Given: 【テストデータ準備】: 'tts_speed'キーが存在しないJSONデータ
        // 【初期条件設定】: アプリ初回起動時の状態を模擬
        // 【実際の使用場面】: アンインストール後の再インストール、ストレージクリア後
        final json = {
          'font_size': 'medium',
          'theme': 'light',
          // 'tts_speed'キーなし
        };

        // When: 【実際の処理実行】: fromJson()を呼び出す
        // 【処理内容】: 'tts_speed'キーが存在しないJSONからAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 【結果検証】: デフォルト値（normal）が使用されたことを確認
        // 【期待値確認】: null安全性を確認
        // 【堅牢性の確認】: データが存在しない極端な条件でも安定動作する
        expect(settings.ttsSpeed,
            TTSSpeed.normal); // 【確認内容】: デフォルト値normalが使用されたことを確認 🔵
      });
    });
  });
}
