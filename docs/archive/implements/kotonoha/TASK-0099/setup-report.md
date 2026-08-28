# TASK-0099 設定作業実行

## 作業概要

- **タスクID**: TASK-0099
- **作業内容**: App Store/Google Play申請準備
- **実行日時**: 2025-12-03
- **信頼性レベル**: 🔵 青信号（ストア申請要件に基づいた設定）

## 設計文書参照

- **参照文書**:
  - `docs/design/kotonoha/architecture.md` - アーキテクチャ設計
  - `docs/tasks/kotonoha-phase5.md` - Phase 5タスク定義
- **関連要件**: NFR-401（プラットフォーム要件）、NFR-205（ガイド付きアクセス対応）

## 実行した作業

### 1. App Store メタデータ作成（iOS）

**作成ディレクトリ**: `frontend/kotonoha_app/fastlane/metadata/`

#### 日本語 (ja-JP)
| ファイル | 内容 |
|----------|------|
| `name.txt` | ことのは - 文字盤コミュニケーション |
| `subtitle.txt` | 発話困難な方のための支援アプリ |
| `description.txt` | アプリ詳細説明（日本語） |
| `keywords.txt` | コミュニケーション,文字盤,読み上げ,TTS,音声,発話,支援,介護,ALS,脳梗塞 |
| `promotional_text.txt` | プロモーションテキスト |
| `release_notes.txt` | v1.0.0 リリースノート |
| `privacy_url.txt` | プライバシーポリシーURL |
| `support_url.txt` | サポートページURL |

#### 英語 (en-US)
| ファイル | 内容 |
|----------|------|
| `name.txt` | Kotonoha - AAC Communication |
| `subtitle.txt` | Communication aid for speech difficulties |
| `description.txt` | アプリ詳細説明（英語） |
| `keywords.txt` | AAC,communication,speech,aid,TTS,text-to-speech,accessibility,stroke,ALS,disability |
| `promotional_text.txt` | プロモーションテキスト（英語） |
| `release_notes.txt` | v1.0.0 Release Notes |
| `privacy_url.txt` | プライバシーポリシーURL |
| `support_url.txt` | サポートページURL |

### 2. Google Play メタデータ作成（Android）

**作成ディレクトリ**: `frontend/kotonoha_app/android/fastlane/metadata/android/`

#### 日本語 (ja-JP)
| ファイル | 内容 |
|----------|------|
| `title.txt` | ことのは - 文字盤コミュニケーション |
| `short_description.txt` | 簡潔な説明（80文字以内） |
| `full_description.txt` | 詳細説明（HTML形式） |

#### 英語 (en-US)
| ファイル | 内容 |
|----------|------|
| `title.txt` | Kotonoha - AAC Communication |
| `short_description.txt` | 簡潔な説明（英語、80文字以内） |
| `full_description.txt` | 詳細説明（HTML形式、英語） |

### 3. プライバシーポリシー・サポートページ作成

| ファイル | 内容 |
|----------|------|
| `docs/privacy-policy.md` | プライバシーポリシー（日本語・英語） |
| `docs/support.md` | サポートページ（日本語・英語） |
| `docs/store-assets-guide.md` | ストアアセット準備ガイド |

### 4. Fastlane設定ファイル作成

| ファイル | 内容 |
|----------|------|
| `fastlane/Fastfile` | iOS/Android ビルド・デプロイ自動化 |
| `fastlane/Appfile` | iOS アプリ識別情報 |
| `android/fastlane/Appfile` | Android パッケージ情報 |
| `fastlane/metadata/review_information/notes.txt` | 審査用メモ |

### 5. アプリ表示名の更新

#### iOS (Info.plist)
- `CFBundleDisplayName`: `ことのは`
- `CFBundleName`: `ことのは`

#### Android (strings.xml)
- 既に設定済み
  - `values/strings.xml`: `kotonoha`（英語デフォルト）
  - `values-ja/strings.xml`: `ことのは`（日本語）

## 作業結果

- [x] App Store メタデータ作成完了（日本語・英語）
- [x] Google Play メタデータ作成完了（日本語・英語）
- [x] プライバシーポリシー作成完了
- [x] サポートページ作成完了
- [x] Fastlane設定ファイル作成完了
- [x] アプリ表示名更新完了
- [x] ストアアセットガイド作成完了

## 作成ファイル一覧

```
frontend/kotonoha_app/
├── fastlane/
│   ├── Appfile
│   ├── Fastfile
│   └── metadata/
│       ├── ja-JP/
│       │   ├── name.txt
│       │   ├── subtitle.txt
│       │   ├── description.txt
│       │   ├── keywords.txt
│       │   ├── promotional_text.txt
│       │   ├── release_notes.txt
│       │   ├── privacy_url.txt
│       │   └── support_url.txt
│       ├── en-US/
│       │   ├── name.txt
│       │   ├── subtitle.txt
│       │   ├── description.txt
│       │   ├── keywords.txt
│       │   ├── promotional_text.txt
│       │   ├── release_notes.txt
│       │   ├── privacy_url.txt
│       │   └── support_url.txt
│       └── review_information/
│           └── notes.txt
└── android/
    └── fastlane/
        ├── Appfile
        └── metadata/
            └── android/
                ├── ja-JP/
                │   ├── title.txt
                │   ├── short_description.txt
                │   └── full_description.txt
                └── en-US/
                    ├── title.txt
                    ├── short_description.txt
                    └── full_description.txt

docs/
├── privacy-policy.md
├── support.md
└── store-assets-guide.md
```

## 残作業（手動対応が必要）

以下の作業は、開発者アカウント情報が必要なため手動対応が必要です：

### App Store Connect

1. **Apple Developer アカウント情報の設定**
   - `fastlane/Appfile` に Apple ID を設定
   - チームID、App Store Connect チームIDを設定

2. **App Store Connect でのアプリ登録**
   - Bundle ID: `com.kotonoha.kotonoha_app`
   - カテゴリ: ヘルスケア＆フィットネス > 医療
   - 年齢制限: 4+

3. **スクリーンショット準備**
   - iPhone 6.7インチ用 × 5-8枚
   - iPad Pro 12.9インチ用 × 5-8枚
   - `docs/store-assets-guide.md` 参照

4. **App Privacy 設定**
   - データ収集: AI変換時のみ入力テキストを送信
   - トラッキング: なし

### Google Play Console

1. **Google Play Developer アカウント情報の設定**
   - `android/fastlane/Appfile` にクレデンシャルJSONパスを設定

2. **Google Play Console でのアプリ登録**
   - パッケージ名: `com.kotonoha.kotonoha_app`
   - カテゴリ: 医療
   - コンテンツレーティング: 全ユーザー対象

3. **スクリーンショット準備**
   - スマートフォン用 × 4-8枚
   - タブレット 10インチ用 × 4-8枚
   - フィーチャーグラフィック 1024x500

4. **Data Safety セクション**
   - データ収集: AI変換時のみ入力テキストを送信
   - データ共有: なし
   - セキュリティ: HTTPS通信

## 次のステップ

1. `/tsumiki:direct-verify` を実行して設定を確認
2. アプリアイコンの作成（1024x1024、512x512）
3. スクリーンショットの撮影
4. 開発者アカウントへの登録・設定
5. TestFlight / 内部テスト配布でのベータテスト
