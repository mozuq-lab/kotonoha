/// AppSettings モデルテスト (TTS速度設定)
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/settings/models/app_settings.dart';
import 'package:kotonoha_app/features/settings/models/font_size.dart';
import 'package:kotonoha_app/features/settings/models/app_theme.dart';
import 'package:kotonoha_app/features/tts/domain/models/tts_speed.dart';

void main() {
  group('AppSettings - TTS速度設定テスト', () {
    // 正常系テストケース
    group('正常系テスト', () {
      /// AppSettings.ttsSpeedのデフォルト値確認
      test('TC-049-001: AppSettings初期化時にttsSpeedがデフォルト値（normal）であることを確認', () {
        // Given: テストデータ準備: アプリ初回起動時の状態を模擬（shared_preferencesが空）
        // 初期条件設定: デフォルトコンストラクタでAppSettingsを作成
        // 前提条件TTS速度が未設定であることを確認
        const appSettings = AppSettings();

        // Then: 結果検証: ttsSpeedがnormalに設定されたことを確認
        // の3段階選択要件を満たすため
        // 品質保証: ユーザーが明示的に速度を選択するまで、標準的な速度（1.0倍速）で読み上げが行われることを保証
        expect(appSettings.ttsSpeed, TTSSpeed.normal);
      });

      /// AppSettings.copyWithでttsSpeedを更新
      test('TC-049-002: copyWithメソッドでttsSpeedのみを変更し、他のフィールドが保持されることを確認', () {
        // Given: テストデータ準備: カスタマイズされた設定を持つAppSettingsを作成
        // 初期条件設定: ユーザーが既に設定をカスタマイズしている状態（フォントサイズ「大」、ダークモード）
        const original = AppSettings(
          fontSize: FontSize.large,
          theme: AppTheme.dark,
          ttsSpeed: TTSSpeed.normal,
        );

        // When: 実際の処理実行: copyWithでttsSpeedのみを変更
        // 処理内容: TTS速度のみを「遅い」に変更する
        final updated = original.copyWith(ttsSpeed: TTSSpeed.slow);

        // Then: 結果検証: ttsSpeedが変更され、他のフィールドが保持されていることを確認
        // 不変オブジェクトパターンの正しい実装を保証
        // 品質保証: 設定の一部のみを変更する際に、他の設定が意図せず変更されないことを確認
        expect(updated.ttsSpeed, TTSSpeed.slow);
        expect(updated.fontSize, FontSize.large);
        expect(updated.theme, AppTheme.dark);
        expect(identical(original, updated), isFalse);
      });

      /// AppSettings.toJsonでttsSpeedがシリアライズされる
      test('TC-049-003: toJson()メソッドでttsSpeedが正しくJSON形式に変換されることを確認', () {
        // Given: テストデータ準備: 速度を「速い」に設定したAppSettingsを作成
        // 初期条件設定: ユーザーが速度を「速い」に設定した状態を模擬
        const settings = AppSettings(ttsSpeed: TTSSpeed.fast);

        // When: 実際の処理実行: toJsonを呼び出す
        // 処理内容: shared_preferencesに保存する際のシリアライズ処理
        final json = settings.toJson();

        // Then: 結果検証: ttsSpeedが文字列形式で含まれていることを確認
        // shared_preferencesへの保存前に、AppSettingsが正しくJSON形式に変換されることを確認
        // 品質保証: 永続化データの形式が仕様通りであることを保証
        expect(json['tts_speed'], 'fast');
      });

      /// AppSettings.fromJsonでttsSpeedがデシリアライズされる
      test('TC-049-004: fromJson()メソッドでJSON形式からttsSpeedが正しく復元されることを確認', () {
        // Given: テストデータ準備: shared_preferencesから読み込んだJSON形式のデータ
        // 初期条件設定: アプリ再起動時の設定復元処理を模擬
        final json = {
          'tts_speed': 'slow',
          'font_size': 'large',
          'theme': 'dark',
        };

        // When: 実際の処理実行: fromJsonを呼び出す
        // 処理内容: JSON文字列からAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 結果検証: ttsSpeedが正しく復元されたことを確認
        // アプリ再起動時に、保存されたTTS速度が正しく復元されることを確認
        // 品質保証: データの永続化・復元サイクルが正しく機能することを保証
        expect(settings.ttsSpeed, TTSSpeed.slow);
        expect(settings.fontSize, FontSize.large);
        expect(settings.theme, AppTheme.dark);
      });
    });

    // 正常系テストケース（verySlow追加）
    group('正常系テスト（verySlow追加）', () {
      /// SharedPreferencesへの"verySlow"文字列の保存・復元
      test('TTC-VS-011: AppSettings.fromJson()で"verySlow"が正しく復元されることを確認', () {
        // Given: テストデータ準備: verySlowを含むJSONデータ
        // 初期条件設定: ユーザーが「とても遅い」を設定してアプリを閉じ、再度開く場合を模擬
        final json = {
          'tts_speed': 'verySlow',
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 実際の処理実行: fromJsonを呼び出す
        // 処理内容: JSON文字列からAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 結果検証: ttsSpeedがverySlowに復元されたことを確認
        // 永続化データからの復元が正しく行われる
        // 品質保証: アプリ再起動後も設定が保持されることを保証
        expect(settings.ttsSpeed, TTSSpeed.verySlow);
      });

      /// AppSettings.toJsonで"verySlow"が正しく保存される
      test(
          'TTC-VS-011b: AppSettings.toJson()でverySlowが"verySlow"文字列に変換されることを確認',
          () {
        // Given: テストデータ準備: 速度を「とても遅い」に設定したAppSettingsを作成
        // 初期条件設定: ユーザーが速度を「とても遅い」に設定した状態を模擬
        const settings = AppSettings(ttsSpeed: TTSSpeed.verySlow);

        // When: 実際の処理実行: toJsonを呼び出す
        // 処理内容: shared_preferencesに保存する際のシリアライズ処理
        final json = settings.toJson();

        // Then: 結果検証: ttsSpeedが"verySlow"文字列に変換されることを確認
        // shared_preferencesへの保存前に正しく変換される
        // 品質保証: 永続化データの形式が仕様通りであることを保証
        expect(json['tts_speed'], 'verySlow');
      });

      /// AppSettings.copyWithでttsSpeedをverySlowに更新できる
      test('TTC-VS-011c: copyWithメソッドでttsSpeedをverySlowに変更し、他のフィールドが保持されることを確認',
          () {
        // Given: テストデータ準備: カスタマイズされた設定を持つAppSettingsを作成
        // 初期条件設定: ユーザーが既に設定をカスタマイズしている状態
        const original = AppSettings(
          fontSize: FontSize.large,
          theme: AppTheme.dark,
          ttsSpeed: TTSSpeed.normal,
        );

        // When: 実際の処理実行: copyWithでttsSpeedをverySlowに変更
        // 処理内容: TTS速度のみを「とても遅い」に変更する
        final updated = original.copyWith(ttsSpeed: TTSSpeed.verySlow);

        // Then: 結果検証: ttsSpeedが変更され、他のフィールドが保持されていることを確認
        // 不変オブジェクトパターンの正しい実装を保証
        // 品質保証: 設定の一部のみを変更する際に、他の設定が意図せず変更されないことを確認
        expect(updated.ttsSpeed, TTSSpeed.verySlow);
        expect(updated.fontSize, FontSize.large);
        expect(updated.theme, AppTheme.dark);
      });
    });

    // 異常系テストケース
    group('異常系テスト', () {
      /// 不正な速度値からのフォールバック
      test(
          'TTC-VS-007: shared_preferencesに不正な値（\'invalid\'）が保存されている場合、デフォルト値（normal）にフォールバックすることを確認',
          () {
        // Given: テストデータ準備: 不正な値を含むJSONデータ
        // 初期条件設定: ストレージデータが破損している場合を模擬
        final json = {
          'tts_speed': 'invalid',
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 実際の処理実行: fromJsonを呼び出す
        // 処理内容: 不正な値からAppSettingsインスタンスを生成しようとする
        final settings = AppSettings.fromJson(json);

        // Then: 結果検証: デフォルト値にフォールバックされたことを確認
        // エラーハンドリングの堅牢性を確認
        // システムの安全性: エラー発生でもアプリがクラッシュしない
        expect(settings.ttsSpeed, TTSSpeed.normal);
      });

      /// 既存設定（"slow", "normal", "fast"）の後方互換性
      test('TTC-VS-008: 既存の3段階設定（slow/normal/fast）が正常に読み込まれることを確認', () {
        // Given: テストデータ準備: 各既存設定のJSONデータ
        // 初期条件設定: アプリアップデート後の初回起動を模擬

        // slow: 既存の「遅い」設定
        final slowJson = {
          'tts_speed': 'slow',
          'font_size': 'medium',
          'theme': 'light',
        };
        final slowSettings = AppSettings.fromJson(slowJson);
        expect(slowSettings.ttsSpeed, TTSSpeed.slow);

        // normal: 既存の「普通」設定
        final normalJson = {
          'tts_speed': 'normal',
          'font_size': 'medium',
          'theme': 'light',
        };
        final normalSettings = AppSettings.fromJson(normalJson);
        expect(normalSettings.ttsSpeed, TTSSpeed.normal);

        // fast: 既存の「速い」設定
        final fastJson = {
          'tts_speed': 'fast',
          'font_size': 'medium',
          'theme': 'light',
        };
        final fastSettings = AppSettings.fromJson(fastJson);
        expect(fastSettings.ttsSpeed, TTSSpeed.fast);

        // 確認ポイント: ユーザーの既存設定が保持される
        // 確認ポイント: 既存ユーザーへの影響を最小化
      });

      /// 不正な速度値がshared_preferencesに保存されている場合、デフォルト値にフォールバック
      test(
          'TC-049-011: shared_preferencesに不正な値（\'invalid\'）が保存されている場合、デフォルト値（normal）にフォールバックすることを確認',
          () {
        // Given: テストデータ準備: 不正な値を含むJSONデータ
        // 初期条件設定: ストレージデータが破損している場合を模擬
        // 実際の発生シナリオ: アプリのバージョンアップで速度の種類が変更された場合
        final json = {
          'tts_speed': 'invalid', // 不正な値
          'font_size': 'medium',
          'theme': 'light',
        };

        // When: 実際の処理実行: fromJsonを呼び出す
        // 処理内容: 不正な値からAppSettingsインスタンスを生成しようとする
        final settings = AppSettings.fromJson(json);

        // Then: 結果検証: デフォルト値にフォールバックされたことを確認
        // エラーハンドリングの堅牢性を確認
        // システムの安全性: エラー発生でもアプリがクラッシュしない
        expect(settings.ttsSpeed, TTSSpeed.normal);
      });
    });

    // 境界値テストケース
    group('境界値テスト', () {
      /// shared_preferencesに速度設定が存在しない場合、デフォルト値（normal）を使用
      test(
          'TC-049-016: shared_preferencesに\'tts_speed\'キーが存在しない場合、デフォルト値（normal）が使用されることを確認',
          () {
        // Given: テストデータ準備: 'tts_speed'キーが存在しないJSONデータ
        // 初期条件設定: アプリ初回起動時の状態を模擬
        // 実際の使用場面: アンインストール後の再インストール、ストレージクリア後
        final json = {
          'font_size': 'medium',
          'theme': 'light',
          // 'tts_speed'キーなし
        };

        // When: 実際の処理実行: fromJsonを呼び出す
        // 処理内容: 'tts_speed'キーが存在しないJSONからAppSettingsインスタンスを生成
        final settings = AppSettings.fromJson(json);

        // Then: 結果検証: デフォルト値（normal）が使用されたことを確認
        // null安全性を確認
        // 堅牢性のデータが存在しない極端な条件でも安定動作する
        expect(settings.ttsSpeed, TTSSpeed.normal);
      });
    });
  });
}
