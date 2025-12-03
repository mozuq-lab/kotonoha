# kotonoha_app

文字盤コミュニケーション支援アプリケーション - Flutterフロントエンド

## 概要

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリです。

**対象ユーザー**: 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

## プロジェクト状況

**リリース準備完了** (2025-12-03)

| 指標 | 値 |
|------|-----|
| テストカバレッジ | 87.86% |
| テスト件数 | 1414件成功 |
| 機能要件達成率 | 100% (46/46件) |
| 非機能要件達成率 | 100% (23/23件) |

## 技術スタック

- **Flutter**: 3.38.1
- **Dart**: 3.10+
- **状態管理**: Riverpod 2.x
- **ルーティング**: go_router
- **ローカルストレージ**: Hive + shared_preferences
- **HTTP通信**: dio + retrofit
- **TTS**: flutter_tts

## 主要機能

### コア機能
- **文字盤入力**: 五十音配列での文字入力（タップ応答100ms以内）
- **定型文**: 100件以上の定型文、カテゴリ分類、お気に入り機能
- **大ボタン**: はい/いいえ/わからない、状態ボタン（痛い/トイレ等）
- **緊急ボタン**: 2段階確認、緊急音・画面赤表示
- **TTS読み上げ**: OS標準TTS使用（開始1秒以内）、速度3段階
- **対面表示**: 180度回転、拡大表示モード
- **履歴**: 最大50件自動保存、ワンタップ再読み上げ
- **お気に入り**: 登録・並び順変更、優先表示
- **AI変換**: 短文→丁寧な文章変換、丁寧さ3段階（平均3秒以内）

### アクセシビリティ
- **フォントサイズ**: 小(16px)/中(20px)/大(24px) の3段階
- **テーマ**: ライト/ダーク/高コントラスト
- **タップターゲット**: 最小44px、推奨60px以上
- **WCAG 2.1 AA準拠**: 高コントラストモードでコントラスト比4.5:1以上

### オフライン対応
- 文字盤入力・定型文・履歴・TTSはオフラインで動作
- AI変換のみオンライン必須（オフライン時はフォールバック）

## ディレクトリ構造

```
lib/
├── main.dart                 # エントリーポイント
├── app.dart                  # アプリルート
├── core/                     # 共通基盤
│   ├── constants/            # 定数（カラー、サイズ、テキストスタイル）
│   ├── themes/               # テーマ（ライト/ダーク/高コントラスト）
│   ├── router/               # ルーティング設定
│   └── utils/                # ユーティリティ
├── features/                 # 機能モジュール
│   ├── character_board/      # 文字盤入力
│   ├── preset_phrase/        # 定型文
│   ├── large_buttons/        # 大ボタン（はい/いいえ）
│   ├── status_buttons/       # 状態ボタン（痛い/トイレ等）
│   ├── emergency/            # 緊急呼び出し
│   ├── tts/                  # 音声読み上げ
│   ├── history/              # 履歴管理
│   ├── favorite/             # お気に入り
│   ├── ai_conversion/        # AI変換
│   ├── settings/             # 設定
│   └── network/              # ネットワーク状態管理
├── shared/                   # 共有コンポーネント
│   ├── widgets/              # 再利用可能ウィジェット
│   ├── models/               # 共通データモデル
│   └── services/             # 共通サービス
└── l10n/                     # 多言語化リソース
    └── app_ja.arb
```

## セットアップ

### 前提条件
- Flutter SDK 3.38.1以上
- Dart 3.10以上
- iOS: Xcode 15+
- Android: Android Studio + SDK 33+

### 依存関係のインストール
```bash
cd frontend/kotonoha_app
flutter pub get
```

### コード生成
```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 実行
```bash
# Web
flutter run -d chrome

# iOS（macOS環境）
flutter run -d "iPhone 15 Pro"

# Android
flutter run -d <device_id>
```

## テスト

### 単体テスト実行
```bash
flutter test
```

### カバレッジ測定
```bash
flutter test --coverage

# カバレッジ率計算
awk -F: '/^LF:/{lf+=$2} /^LH:/{lh+=$2} END{printf "Coverage: %.2f%%\n", (lh/lf)*100}' coverage/lcov.info
```

### 静的解析
```bash
flutter analyze
```

### E2Eテスト
```bash
flutter test integration_test/
```

## ビルド

### Webビルド
```bash
flutter build web --release
```

### iOSビルド
```bash
flutter build ios --release
```

### Androidビルド
```bash
flutter build apk --release
# または
flutter build appbundle --release
```

## 品質基準

- **テストカバレッジ**: 80%以上（達成: 87.86%）
- **パフォーマンス**:
  - 文字盤タップ応答: 100ms以内
  - TTS読み上げ開始: 1秒以内
  - 定型文一覧表示: 1秒以内
  - AI変換応答: 平均3秒以内
- **コード品質**: flutter_lints準拠

## 開発完了タスク

### Phase 1: 開発環境構築・基盤実装
- [x] TASK-0005: Flutter開発環境セットアップ
- [x] TASK-0011〜0015: プロジェクト構造・依存関係設定
- [x] TASK-0016〜0020: テーマ・共通コンポーネント実装

### Phase 3: フロントエンド基本機能
- [x] TASK-0037〜0042: 文字盤・定型文UI
- [x] TASK-0043〜0048: 大ボタン・緊急ボタン
- [x] TASK-0049〜0054: TTS読み上げ・対面表示
- [x] TASK-0055〜0060: ローカルストレージ・状態管理

### Phase 4: フロントエンド応用機能
- [x] TASK-0061〜0065: 履歴・お気に入り
- [x] TASK-0066〜0070: AI変換連携UI
- [x] TASK-0071〜0075: 設定画面・アクセシビリティ
- [x] TASK-0076〜0080: オフライン対応・エラーハンドリング

### Phase 5: 統合・テスト・リリース準備
- [x] TASK-0081〜0090: E2E・パフォーマンステスト
- [x] TASK-0091〜0095: モバイルビルド・CI/CD
- [x] TASK-0096〜0100: カバレッジ・ドキュメント・リリース準備

## 関連ドキュメント

- [プロジェクト全体README](../../README.md)
- [技術スタック定義](../../docs/tech-stack.md)
- [アーキテクチャ設計](../../docs/design/kotonoha/architecture.md)
- [要件定義書](../../docs/spec/kotonoha-requirements.md)
- [リリースチェックリスト](../../docs/implements/kotonoha/TASK-0100/release-checklist.md)
- [ユーザーガイド](../../docs/user-guide/index.md)

## ライセンス

MIT License
