# コントリビューションガイド

kotonohaプロジェクトへのコントリビューションを歓迎します。このドキュメントでは、プロジェクトに貢献するためのガイドラインを説明します。

## 目次

1. [行動規範](#行動規範)
2. [コントリビューションの方法](#コントリビューションの方法)
3. [開発環境のセットアップ](#開発環境のセットアップ)
4. [コーディング規約](#コーディング規約)
5. [コミットメッセージ](#コミットメッセージ)
6. [プルリクエスト](#プルリクエスト)
7. [Issue](#issue)
8. [テスト](#テスト)
9. [ドキュメント](#ドキュメント)

## 行動規範

- すべての参加者を尊重してください
- 建設的なフィードバックを心がけてください
- このプロジェクトの対象ユーザー（発話困難な方々）に配慮した発言をしてください
- 多様性と包括性を重視してください

## コントリビューションの方法

### バグ報告

バグを見つけた場合は、Issue を作成してください。以下の情報を含めてください:

- バグの詳細な説明
- 再現手順
- 期待される動作
- 実際の動作
- 環境情報（OS、Flutter/Python バージョン等）
- 可能であればスクリーンショットやログ

### 機能リクエスト

新機能のアイデアがある場合は、Issue を作成して提案してください。以下を含めてください:

- 機能の詳細な説明
- この機能が必要な理由
- 想定されるユースケース
- 可能であればモックアップやワイヤーフレーム

### コード貢献

1. プロジェクトをフォークする
2. 機能ブランチを作成する (`git checkout -b feature/amazing-feature`)
3. 変更をコミットする (`git commit -m 'Add some amazing feature'`)
4. ブランチにプッシュする (`git push origin feature/amazing-feature`)
5. プルリクエストを作成する

## 開発環境のセットアップ

詳細な手順は [docs/SETUP.md](docs/SETUP.md) を参照してください。

### クイックスタート

```bash
# リポジトリをクローン
git clone https://github.com/yourusername/kotonoha.git
cd kotonoha

# 環境変数を設定
cp .env.example .env

# Docker環境を起動
docker-compose up -d

# バックエンドセットアップ
cd backend
python -m venv venv
source venv/bin/activate
pip install -r requirements.txt
alembic upgrade head

# フロントエンドセットアップ
cd ../frontend/kotonoha_app
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## コーディング規約

### Flutter / Dart

#### 一般的なルール

- Null Safety を有効にする
- `const` コンストラクタを可能な限り使用する
- ウィジェットは `key` パラメータを持つ
- ファイル名はスネークケース（`my_widget.dart`）
- クラス名はパスカルケース（`MyWidget`）
- 変数名・関数名はキャメルケース（`myVariable`, `myFunction`）

#### Lintルール

`flutter_lints` パッケージの推奨ルールに従います。

```yaml
# analysis_options.yaml
include: package:flutter_lints/flutter.yaml

linter:
  rules:
    - prefer_const_constructors
    - prefer_const_literals_to_create_immutables
    - avoid_print
    - use_key_in_widget_constructors
```

#### コードスタイル

```dart
// Good
class MyWidget extends StatelessWidget {
  const MyWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}

// Bad
class MyWidget extends StatelessWidget {
  MyWidget();  // const がない、key がない

  @override
  Widget build(BuildContext context) {
    return SizedBox.shrink();  // const がない
  }
}
```

### Python / FastAPI

#### 一般的なルール

- 型ヒントを必須とする
- 行長は100文字以内
- docstring は Google Style で記述
- ファイル名はスネークケース（`my_module.py`）
- クラス名はパスカルケース（`MyClass`）
- 変数名・関数名はスネークケース（`my_variable`, `my_function`）

#### Linter / Formatter

- **Ruff**: 静的解析
- **Black**: コードフォーマット

```bash
# Lintチェック
ruff check app tests

# フォーマット
ruff format app tests
# または
black app tests
```

#### コードスタイル

```python
# Good
from typing import Optional

def get_user_by_id(user_id: int) -> Optional[User]:
    """ユーザーIDからユーザーを取得する。

    Args:
        user_id: 取得するユーザーのID

    Returns:
        見つかった場合はUserオブジェクト、見つからない場合はNone
    """
    return db.query(User).filter(User.id == user_id).first()

# Bad
def get_user_by_id(user_id):  # 型ヒントがない
    return db.query(User).filter(User.id == user_id).first()  # docstringがない
```

### アクセシビリティガイドライン

このプロジェクトは発話困難な方々を対象としているため、アクセシビリティは最重要事項です:

- タップターゲットサイズ: 最小44px x 44px、推奨60px x 60px
- コントラスト比: WCAG 2.1 AA準拠（4.5:1以上）
- セマンティックウィジェットを使用する
- スクリーンリーダー対応を考慮する

```dart
// Good - 推奨タップターゲットサイズを使用
SizedBox(
  width: AppSizes.recommendedTapTarget,  // 60px
  height: AppSizes.recommendedTapTarget,
  child: ElevatedButton(
    onPressed: () {},
    child: const Text('ボタン'),
  ),
)
```

## コミットメッセージ

### フォーマット

```
<タイプ>: <件名>

<本文>（オプション）

<フッター>（オプション）
```

### タイプ

- `feat`: 新機能
- `fix`: バグ修正
- `docs`: ドキュメントのみの変更
- `style`: コードの意味に影響しない変更（空白、フォーマット等）
- `refactor`: バグ修正でも新機能でもないコード変更
- `test`: テストの追加・修正
- `chore`: ビルドプロセスやツールの変更

### 例

```
feat: 緊急ボタンウィジェットを追加

- 60x60pxの赤い丸ボタンを実装
- タップ時にコールバックを実行
- アクセシビリティ対応（セマンティクス追加）

Refs: TASK-0017
```

### Tsumikiタスクとの連携

タスク完了時のコミットメッセージは以下の形式を推奨:

```
<タスク内容> (TASK-XXXX)
```

例:
```
共通UIコンポーネント実装（LargeButton, TextInputField, EmergencyButton） (TASK-0017)
```

## プルリクエスト

### 作成手順

1. 最新の `main` ブランチから機能ブランチを作成
2. 変更を実装
3. テストを追加・実行
4. Lintチェックを通過させる
5. プルリクエストを作成

### プルリクエストの内容

以下の情報を含めてください:

```markdown
## 概要
変更内容の簡潔な説明

## 変更内容
- 変更点1
- 変更点2
- 変更点3

## テスト
- [ ] 単体テストを追加した
- [ ] 既存のテストが通過する
- [ ] 手動テストを行った

## スクリーンショット（UIの変更がある場合）
（該当する場合は添付）

## 関連Issue
Fixes #123
```

### レビュープロセス

1. 自動チェック（CI/CD）が通過すること
2. コードレビューで承認を受けること
3. すべてのコメントに対応すること
4. マージ前に最新の `main` ブランチをリベース

## Issue

### ラベル

- `bug`: バグ報告
- `enhancement`: 機能改善
- `feature`: 新機能
- `documentation`: ドキュメント関連
- `accessibility`: アクセシビリティ関連
- `good first issue`: 初心者向け
- `help wanted`: ヘルプ募集中

### 優先度

- `priority: high`: 高優先度
- `priority: medium`: 中優先度
- `priority: low`: 低優先度

## テスト

### テストの種類

1. **単体テスト**: 個々の関数やクラスのテスト
2. **ウィジェットテスト**: Flutterウィジェットのテスト
3. **統合テスト**: 複数のコンポーネントの結合テスト

### テストの実行

```bash
# バックエンド
cd backend
pytest                    # 全テスト
pytest --cov=app         # カバレッジ付き

# フロントエンド
cd frontend/kotonoha_app
flutter test              # 全テスト
flutter test --coverage  # カバレッジ付き
```

### テストのガイドライン

- 新機能には必ずテストを追加する
- カバレッジ80%以上を維持する
- テスト名は日本語でもOK（明確であれば）

```dart
void main() {
  group('LargeButton', () {
    testWidgets('タップ時にコールバックが実行される', (tester) async {
      // テスト実装
    });

    testWidgets('サイズが推奨値以上である', (tester) async {
      // テスト実装
    });
  });
}
```

## ドキュメント

### 更新が必要な場合

- 新機能を追加した場合
- API を変更した場合
- 設定方法が変わった場合
- 依存関係を追加/変更した場合

### ドキュメントの場所

- `README.md`: プロジェクト概要
- `CONTRIBUTING.md`: コントリビューションガイド（このファイル）
- `docs/SETUP.md`: 開発環境セットアップ
- `docs/tech-stack.md`: 技術スタック定義
- `CHANGELOG.md`: 変更履歴

### ドキュメントの言語

- 日本語で記述
- コードサンプルは英語（変数名、コメント等）
- 技術用語は英語のままでも可

## 質問・サポート

質問がある場合は:

1. まず既存の Issue を検索
2. 見つからない場合は新しい Issue を作成
3. 「質問」ラベルを付ける

---

皆様のコントリビューションをお待ちしています!
