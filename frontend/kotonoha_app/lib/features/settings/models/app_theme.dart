/// 機能概要: アプリテーマ設定のenum定義
/// 実装方針: interfaces.dartで定義されたAppTheme enumを再利用
library;

// 実装内容: テーマの3種類（ライト・ダーク・高コントラスト）を定義
// 対応: アクセシビリティ要件として3種類のテーマ選択を提供
enum AppTheme {
  // ライトモード: 明るい環境でアプリを使用するユーザー向け
  // で定義された標準テーマ
  light('ライトモード'),

  // ダークモード: 夜間や暗い環境でアプリを使用するユーザー向け（目への負担軽減）
  // で定義されたダークモード
  dark('ダークモード'),

  // 高コントラストモード: 強い視覚障害のあるユーザー向け（WCAG 2.1 AA準拠）
  // で定義されたWCAG準拠テーマ
  highContrast('高コントラストモード');

  // 表示名: UI上に表示するための日本語名
  // interfaces.dartの定義に基づく
  final String displayName;

  // コンストラクタ: enumの各値に表示名を関連付け
  const AppTheme(this.displayName);
}
