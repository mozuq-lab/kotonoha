# kotonoha_app

文字盤コミュニケーション支援アプリケーション - Flutterフロントエンド

## 概要

発話困難な方が「できるだけ少ない操作で、自分の言いたいことを、適切な丁寧さで、安全に伝えられる」ことを目的としたタブレット向けコミュニケーション支援アプリです。

**対象ユーザー**: 脳梗塞・ALS・筋疾患などで発話が困難だが、タブレットのタップ操作がある程度可能な方々

## 技術スタック

- **Flutter**: 3.38.1
- **Dart**: 3.10+
- **状態管理**: Riverpod 2.x
- **ルーティング**: go_router
- **ローカルストレージ**: Hive + shared_preferences
- **HTTP通信**: dio + retrofit
- **TTS**: flutter_tts

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
│   ├── preset_phrases/       # 定型文
│   ├── large_buttons/        # 大ボタン（はい/いいえ）
│   ├── emergency/            # 緊急呼び出し
│   ├── tts/                  # 音声読み上げ
│   ├── history/              # 履歴管理
│   ├── favorites/            # お気に入り
│   └── settings/             # 設定
├── shared/                   # 共有コンポーネント
│   ├── widgets/              # 再利用可能ウィジェット
│   ├── models/               # 共通データモデル
│   └── services/             # 共通サービス
└── l10n/                     # 多言語化リソース
    └── app_ja.arb
```

各ディレクトリには詳細な説明を記載した `README.md` が配置されています。

## セットアップ

### 前提条件
- Flutter SDK 3.38.1以上
- Dart 3.10以上

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
```

### 静的解析
```bash
flutter analyze
```

## アクセシビリティ要件

- **タップターゲットサイズ**: 最小44px × 44px、推奨60px × 60px（REQ-5001）
- **フォントサイズ**: 小/中/大の3段階（REQ-801）
- **テーマ**: ライト/ダーク/高コントラストの3種類（REQ-803）
- **高コントラストモード**: WCAG 2.1 AAレベル（コントラスト比4.5:1以上）（REQ-5006）

## 開発状況

### 完了
- [x] TASK-0005: Flutter開発環境セットアップ
- [x] TASK-0011: プロジェクトディレクトリ構造設計・実装

### 予定
- [ ] TASK-0012: Flutter依存パッケージ追加
- [ ] TASK-0013: Riverpod状態管理セットアップ
- [ ] TASK-0014: Hiveローカルストレージセットアップ
- [ ] TASK-0015: go_routerナビゲーション設定
- [ ] TASK-0016: テーマ実装
- [ ] TASK-0017: 共通UIコンポーネント実装

## 関連ドキュメント

- [プロジェクト全体README](../../README.md)
- [技術スタック定義](../../docs/tech-stack.md)
- [アーキテクチャ設計](../../docs/design/kotonoha/architecture.md)
- [要件定義書](../../docs/spec/kotonoha-requirements.md)
