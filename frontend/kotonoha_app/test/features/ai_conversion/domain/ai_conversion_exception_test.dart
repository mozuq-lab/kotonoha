/// AIConversionException テスト
///
/// TASK-0067: AI変換APIクライアント実装
/// 【TDD Redフェーズ】: TC-067-018
///
/// 信頼性レベル: 🔵 青信号（api-endpoints.mdベース）
/// 関連要件: EDGE-001, EDGE-002
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:kotonoha_app/features/ai_conversion/domain/exceptions/ai_conversion_exception.dart';

void main() {
  group('AIConversionException テスト', () {
    // =========================================================================
    // TC-067-018: AIConversionExceptionが正しく動作する
    // =========================================================================

    group('TC-067-018: AIConversionExceptionが正しく動作する', () {
      // 【テスト目的】: 例外クラスが適切なプロパティを持つことを確認
      // 【テスト内容】: code, messageプロパティとtoStringの動作を検証
      // 【期待される動作】: エラー情報を適切に保持し、文字列表現を返す
      // 🔵 青信号: api-endpoints.mdのエラーコード一覧に基づく

      test('codeとmessageプロパティにアクセスできる', () {
        // 【テストデータ準備】: 典型的なエラー情報で例外を作成
        // 【初期条件設定】: EDGE-002のAI_API_ERRORケース
        const exception = AIConversionException(
          code: 'AI_API_ERROR',
          message: 'AI変換APIからのレスポンスに失敗しました。',
        );

        // 【結果検証】: codeプロパティが正しく取得できる
        // 【確認内容】: api-endpoints.mdで定義されたエラーコード 🔵
        expect(exception.code, 'AI_API_ERROR');

        // 【結果検証】: messageプロパティが正しく取得できる
        // 【確認内容】: ユーザーに表示するエラーメッセージ 🔵
        expect(exception.message, 'AI変換APIからのレスポンスに失敗しました。');
      });

      test('toStringが適切な形式を返す', () {
        // 【テストデータ準備】: タイムアウトエラーで例外を作成
        // 【初期条件設定】: EDGE-001のAI_API_TIMEOUTケース
        const exception = AIConversionException(
          code: 'AI_API_TIMEOUT',
          message: 'AI変換APIがタイムアウトしました。',
        );

        // 【結果検証】: toStringがcode-message形式を返す
        // 【確認内容】: デバッグやログ出力で使いやすい形式 🔵
        expect(
          exception.toString(),
          'AIConversionException: AI_API_TIMEOUT - AI変換APIがタイムアウトしました。',
        );
      });

      test('NETWORK_ERRORコードで例外を作成できる', () {
        // 【テストデータ準備】: ネットワークエラーで例外を作成
        // 【初期条件設定】: REQ-1002関連のオフライン状態
        const exception = AIConversionException(
          code: 'NETWORK_ERROR',
          message: 'ネットワーク接続を確認してください。',
        );

        // 【確認内容】: オフライン時のエラーコード 🔵
        expect(exception.code, 'NETWORK_ERROR');
        expect(exception.message, 'ネットワーク接続を確認してください。');
      });

      test('RATE_LIMIT_EXCEEDEDコードで例外を作成できる', () {
        // 【テストデータ準備】: レート制限エラーで例外を作成
        // 【初期条件設定】: api-endpoints.mdのレート制限仕様
        const exception = AIConversionException(
          code: 'RATE_LIMIT_EXCEEDED',
          message: 'リクエスト数が上限に達しました。1分後に再試行してください。',
        );

        // 【確認内容】: レート制限エラーコード 🔵
        expect(exception.code, 'RATE_LIMIT_EXCEEDED');
      });

      test('VALIDATION_ERRORコードで例外を作成できる', () {
        // 【テストデータ準備】: バリデーションエラーで例外を作成
        // 【初期条件設定】: 文字数制限違反など
        const exception = AIConversionException(
          code: 'VALIDATION_ERROR',
          message: '入力文字列は2文字以上500文字以下にしてください。',
        );

        // 【確認内容】: バリデーションエラーコード 🟡（API仕様から推測）
        expect(exception.code, 'VALIDATION_ERROR');
      });
    });
  });
}
