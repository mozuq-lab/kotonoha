/// 音量サービス
///
/// TASK-0051: OS音量0の警告表示
/// OS標準の音量取得機能との連携を提供
///
/// 【機能概要】: OSの現在の音量を取得し、音量0（ミュート）かどうかを判定する機能
/// 【設計方針】:
/// - オフラインファースト: ローカルデバイスの音量情報のみを使用
/// - エラー耐性: エラー時も基本機能は継続動作（NFR-301）
/// 【保守性】: volume_controllerパッケージへの依存を一元管理
library;

import 'package:volume_controller/volume_controller.dart';

/// VolumeControllerのインターフェース
///
/// volume_controller パッケージはシングルトンパターンを使用しているため、
/// テスト用にインターフェースを作成してモック化する。
abstract class VolumeControllerInterface {
  /// 現在の音量を取得（0.0〜1.0）
  Future<double> getVolume();

  /// 音量を設定（0.0〜1.0）
  Future<void> setVolume(double volume);

  /// ミュート状態かどうか
  Future<bool> getMute();
}

/// 音量取得時の例外
///
/// 【用途】: OS音量取得に失敗した場合にスローされる
/// 【対応】: 呼び出し元でキャッチし、警告機能を無効化して読み上げを続行
class VolumeServiceException implements Exception {
  VolumeServiceException(this.message);

  final String message;

  @override
  String toString() => 'VolumeServiceException: $message';
}

/// 音量サービス
///
/// OS標準の音量取得機能を使用して、
/// 現在の音量を取得し、音量0かどうかを判定する。
///
/// 【主要機能】:
/// - 現在のOS音量取得（0.0〜1.0）
/// - 音量0判定（isVolumeZero）
///
/// 【要件対応】:
/// - EDGE-202: OSの音量が0の状態で読み上げを実行した場合の警告
///
/// 【パフォーマンス要件】:
/// - 音量チェック時間: 100ms以内
///
/// 🔵 信頼性レベル: 高（要件定義書ベース）
class VolumeService {
  /// コンストラクタ
  ///
  /// 【パラメータ】:
  /// - [volumeController] VolumeControllerInterfaceインスタンス（テスト時はモックを注入）
  /// - [isSupported] 音量取得がサポートされているかどうか（Web環境ではfalse）
  ///
  /// 【使用例】:
  /// ```dart
  /// // 本番環境
  /// final service = VolumeService();
  ///
  /// // テスト環境
  /// final service = VolumeService(volumeController: mockVolumeController);
  /// ```
  VolumeService({
    VolumeControllerInterface? volumeController,
    this.isSupported = true,
  }) : _volumeController = volumeController;

  /// VolumeControllerインスタンス（テスト用）
  final VolumeControllerInterface? _volumeController;

  /// 音量取得がサポートされているかどうか
  ///
  /// 【用途】: Web環境では音量取得APIが制限されるため、警告機能を無効化
  final bool isSupported;

  /// 初期化済みかどうか
  bool get isInitialized => true;

  /// 現在の音量を取得
  ///
  /// OSの現在の音量を0.0〜1.0の範囲で取得する。
  ///
  /// 【戻り値】:
  /// - 0.0: ミュート（音量なし）
  /// - 0.5: 50%音量
  /// - 1.0: 最大音量
  ///
  /// 【エラーハンドリング】:
  /// - 音量取得に失敗した場合: VolumeServiceExceptionをスロー
  ///
  /// 参照: volume-warning-requirements.md「出力値」セクション
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  ///
  /// Throws:
  /// - [VolumeServiceException] 音量取得に失敗した場合
  Future<double> getCurrentVolume() async {
    if (!isSupported) {
      // Web環境などサポートされていない場合は1.0を返す（警告を出さない）
      return 1.0;
    }

    try {
      if (_volumeController != null) {
        // テスト用モック
        return await _volumeController.getVolume();
      } else {
        // 本番用: volume_controllerパッケージを使用
        final controller = VolumeController();
        final volume = await controller.getVolume();
        return volume;
      }
    } catch (e) {
      throw VolumeServiceException('音量取得に失敗しました: $e');
    }
  }

  /// 音量が0かどうかを判定
  ///
  /// OSの現在の音量が0（ミュート）かどうかを判定する。
  ///
  /// 【戻り値】:
  /// - true: 音量が0（ミュート）
  /// - false: 音量が0より大きい
  ///
  /// 【特記事項】:
  /// - Web環境（isSupported=false）では常にfalseを返す
  /// - エラー時は警告機能を無効化するためfalseを返す
  ///
  /// 参照: volume-warning-requirements.md「出力値」セクション
  /// 🔵 信頼性レベル: 高（要件定義書ベース）
  Future<bool> isVolumeZero() async {
    if (!isSupported) {
      // Web環境などサポートされていない場合は警告を出さない
      return false;
    }

    try {
      final volume = await getCurrentVolume();
      return volume == 0.0;
    } catch (e) {
      // エラー時は警告を出さず、読み上げを続行（NFR-301準拠）
      return false;
    }
  }
}
