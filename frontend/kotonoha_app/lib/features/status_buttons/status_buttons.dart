/// Status Buttons Feature バレルエクスポート
///
/// TASK-0044: 状態ボタン（「痛い」「トイレ」等8-12個）実装
///
/// 状態ボタン機能の全コンポーネントをまとめてエクスポート。
///
/// 使用例:
/// ```dart
/// import 'package:kotonoha_app/features/status_buttons/status_buttons.dart';
///
/// // ドメイン層
/// StatusButtonType.pain.label; // '痛い'
///
/// // プレゼンテーション層
/// StatusButton(statusType: StatusButtonType.pain, ...);
/// StatusButtons(onStatus: (type) => ..., ...);
/// ```
library;

export 'domain/domain.dart';
export 'presentation/presentation.dart';
