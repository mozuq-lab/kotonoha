/// Emergency Feature バレルエクスポート
///
/// TASK-0045: 緊急ボタンUI実装
///
/// 緊急呼び出し機能の全コンポーネントをまとめてエクスポート。
///
/// 使用例:
/// ```dart
/// import 'package:kotonoha_app/features/emergency/emergency.dart';
///
/// // プレゼンテーション層
/// EmergencyButtonWithConfirmation(
///   onEmergencyConfirmed: () => handleEmergency(),
/// );
///
/// // 確認ダイアログ
/// EmergencyConfirmationDialog(
///   onConfirm: () => confirmEmergency(),
///   onCancel: () => cancelEmergency(),
/// );
/// ```
library;

export 'presentation/presentation.dart';
