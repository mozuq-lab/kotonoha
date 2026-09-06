# Features

機能ごとにモジュール化されたコードを格納するディレクトリです。
各機能は独立したサブディレクトリとして管理され、Clean Architectureの原則に従って構造化されています。

## ディレクトリ構成

### character_board/
文字盤入力機能

- `data/`: データソース、リポジトリ実装
- `domain/`: エンティティ、ユースケース
- `presentation/`: UI（画面、ウィジェット）
- `providers/`: Riverpod状態管理プロバイダー

### preset_phrases/
定型文機能（よく使うフレーズの登録・使用）

### large_buttons/
大ボタン機能（はい/いいえボタン）

### emergency/
緊急呼び出し機能

### tts/
音声読み上げ（TTS）機能

### history/
履歴管理機能

### favorites/
お気に入り管理機能

### settings/
設定画面機能（フォントサイズ、テーマ、その他設定）

## 機能モジュールの構造

各機能モジュールは以下の構造を推奨します：

```
feature_name/
├── data/
│   ├── models/          # データモデル
│   ├── repositories/    # リポジトリ実装
│   └── datasources/     # データソース（ローカル/リモート）
├── domain/
│   ├── entities/        # ドメインエンティティ
│   ├── repositories/    # リポジトリインターフェース
│   └── usecases/        # ユースケース
├── presentation/
│   ├── screens/         # 画面
│   ├── widgets/         # ウィジェット
│   └── state/           # 状態管理（オプション）
└── providers/           # Riverpodプロバイダー
```

## 実装予定

各機能は以下のタスクで段階的に実装されます：

- TASK-0021〜0025: 文字盤入力機能
- TASK-0026〜0030: 定型文・大ボタン機能
- TASK-0031〜0035: TTS・履歴機能
- TASK-0036〜0040: お気に入り・設定機能
