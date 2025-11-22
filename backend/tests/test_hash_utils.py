"""
TASK-0024: ハッシュ化ユーティリティのテスト

TDD Red Phase: ハッシュ化機能に関するテストケースを定義する。
テストケース仕様書（testcases.md）のUT-011〜UT-014に対応。

テスト対象:
    - hash_text関数（SHA-256ハッシュ化）
    - 空文字列、Unicode文字列、長い文字列の処理
    - ハッシュ値のフォーマット検証
"""

import re
import time


class TestHashTextFunction:
    """
    ハッシュ化ユーティリティのテストクラス

    FR-002: テキストハッシュ化機能のテスト
    - SHA-256アルゴリズムで64文字の16進数文字列を出力
    - 同一入力に対して同一ハッシュ値を返す
    - 異なる入力に対して異なるハッシュ値を返す
    """

    def test_hash_text_empty_string(self) -> None:
        """
        UT-011: 空文字列のハッシュ化

        テスト手順:
            1. 空文字列""に対してhash_textを実行

        期待結果:
            - 64文字のハッシュ値が返される
            - 例外が発生しない

        関連要件ID: FR-002
        優先度: 低
        """
        from app.utils.hash_utils import hash_text

        # 空文字列をハッシュ化
        result = hash_text("")

        # 64文字のハッシュ値が返される
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        # 16進数文字列である
        assert re.match(r"^[0-9a-f]{64}$", result), f"Invalid hex format: {result}"

    def test_hash_text_unicode_japanese(self) -> None:
        """
        UT-012: Unicode文字列のハッシュ化（日本語）

        テスト手順:
            1. 日本語文字列"お水をください"に対してhash_textを実行

        期待結果:
            - 64文字のハッシュ値が返される
            - 例外が発生しない

        関連要件ID: FR-002
        優先度: 中
        """
        from app.utils.hash_utils import hash_text

        # 日本語文字列をハッシュ化
        result = hash_text("お水をください")

        # 64文字のハッシュ値が返される
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        # 16進数文字列である
        assert re.match(r"^[0-9a-f]{64}$", result), f"Invalid hex format: {result}"

    def test_hash_text_unicode_emoji(self) -> None:
        """
        UT-012: Unicode文字列のハッシュ化（絵文字含む）

        テスト手順:
            1. 絵文字を含む文字列に対してhash_textを実行

        期待結果:
            - 64文字のハッシュ値が返される
            - 例外が発生しない

        関連要件ID: FR-002
        優先度: 中
        """
        from app.utils.hash_utils import hash_text

        # 絵文字を含む文字列をハッシュ化
        result = hash_text("ありがとう! 😊🎉")

        # 64文字のハッシュ値が返される
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        # 16進数文字列である
        assert re.match(r"^[0-9a-f]{64}$", result), f"Invalid hex format: {result}"

    def test_hash_text_long_string(self) -> None:
        """
        UT-013: 長い文字列のハッシュ化

        テスト手順:
            1. 10,000文字の文字列に対してhash_textを実行

        期待結果:
            - 64文字のハッシュ値が返される（入力長に依存しない）
            - 処理時間が許容範囲内（1秒以内）

        関連要件ID: FR-002
        優先度: 低
        """
        from app.utils.hash_utils import hash_text

        # 10,000文字の文字列を生成
        long_text = "あ" * 10000

        # 処理時間を計測
        start_time = time.time()
        result = hash_text(long_text)
        elapsed_time = time.time() - start_time

        # 64文字のハッシュ値が返される
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        # 16進数文字列である
        assert re.match(r"^[0-9a-f]{64}$", result), f"Invalid hex format: {result}"
        # 処理時間が1秒以内
        assert elapsed_time < 1.0, f"Processing took too long: {elapsed_time:.3f}s"

    def test_hash_text_format(self) -> None:
        """
        UT-014: ハッシュ値のフォーマット検証

        テスト手順:
            1. 任意のテキストに対してhash_textを実行
            2. 結果のフォーマットを検証

        期待結果:
            - 結果が64文字である
            - 結果が16進数文字列である（0-9, a-f のみ）
            - 結果が小文字である

        関連要件ID: FR-002, NFR-001
        優先度: 中
        """
        from app.utils.hash_utils import hash_text

        # 任意のテキストをハッシュ化
        result = hash_text("テスト用テキスト")

        # 64文字である
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        # 16進数文字列である（0-9, a-f のみ）
        assert re.match(r"^[0-9a-f]+$", result), f"Invalid hex characters: {result}"
        # 小文字である（大文字が含まれていない）
        assert result == result.lower(), f"Hash contains uppercase: {result}"

    def test_hash_text_consistency(self) -> None:
        """
        UT-002: ハッシュ化の一貫性

        テスト手順:
            1. 同一テキスト"ありがとう"に対してhash_textを2回実行
            2. 2つのハッシュ値を比較

        期待結果:
            - hash1 == hash2（同一のハッシュ値が返される）
            - len(hash1) == 64（SHA-256の出力長）

        関連要件ID: FR-002, AC-002
        優先度: 高
        """
        from app.utils.hash_utils import hash_text

        # 同一テキストを2回ハッシュ化
        text = "ありがとう"
        hash1 = hash_text(text)
        hash2 = hash_text(text)

        # 同一のハッシュ値が返される
        assert hash1 == hash2, f"Hash values differ: {hash1} != {hash2}"
        # SHA-256の出力長
        assert len(hash1) == 64, f"Expected 64 characters, got {len(hash1)}"

    def test_hash_text_different_inputs(self) -> None:
        """
        UT-003: 異なるテキストで異なるハッシュ

        テスト手順:
            1. "ありがとう"に対してhash_textを実行
            2. "こんにちは"に対してhash_textを実行
            3. 2つのハッシュ値を比較

        期待結果:
            - hash1 != hash2（異なるハッシュ値が返される）

        関連要件ID: FR-002, AC-003
        優先度: 高
        """
        from app.utils.hash_utils import hash_text

        # 異なるテキストをハッシュ化
        hash1 = hash_text("ありがとう")
        hash2 = hash_text("こんにちは")

        # 異なるハッシュ値が返される
        assert hash1 != hash2, f"Hash values should differ: {hash1} == {hash2}"

    def test_hash_text_sha256_known_value(self) -> None:
        """
        SHA-256の既知値検証

        テスト手順:
            1. 既知の入力に対してhash_textを実行
            2. 期待されるSHA-256ハッシュ値と比較

        期待結果:
            - SHA-256の標準実装と一致する

        関連要件ID: FR-002
        優先度: 高
        """
        from app.utils.hash_utils import hash_text

        # 空文字列のSHA-256ハッシュ値（既知の値）
        # echo -n "" | sha256sum
        empty_hash = hash_text("")
        expected_empty_hash = "e3b0c44298fc1c149afbf4c8996fb92427ae41e4649b934ca495991b7852b855"
        assert empty_hash == expected_empty_hash, f"Empty string hash mismatch: {empty_hash}"

        # "hello"のSHA-256ハッシュ値（既知の値）
        # echo -n "hello" | sha256sum
        hello_hash = hash_text("hello")
        expected_hello_hash = "2cf24dba5fb0a30e26e83b2ac5b9e29e1b161e5c1fa7425e73043362938b9824"
        assert hello_hash == expected_hello_hash, f"Hello hash mismatch: {hello_hash}"

    def test_hash_text_whitespace_handling(self) -> None:
        """
        空白文字を含むテキストのハッシュ化

        テスト手順:
            1. 空白を含むテキストをハッシュ化
            2. 同じテキスト（空白含む）を再度ハッシュ化
            3. 空白なしのテキストと比較

        期待結果:
            - 空白を含むテキストは空白を含む状態でハッシュ化される
            - "hello world"と"helloworld"は異なるハッシュ値

        関連要件ID: FR-002
        優先度: 中
        """
        from app.utils.hash_utils import hash_text

        # 空白を含むテキスト
        hash_with_space = hash_text("hello world")
        hash_without_space = hash_text("helloworld")

        # 64文字のハッシュ値
        assert len(hash_with_space) == 64
        assert len(hash_without_space) == 64

        # 空白の有無でハッシュ値が異なる
        assert hash_with_space != hash_without_space, "Whitespace should affect hash value"

    def test_hash_text_special_characters(self) -> None:
        """
        特殊文字を含むテキストのハッシュ化

        テスト手順:
            1. 特殊文字を含むテキストをハッシュ化

        期待結果:
            - 64文字のハッシュ値が返される
            - 例外が発生しない

        関連要件ID: FR-002
        優先度: 低
        """
        from app.utils.hash_utils import hash_text

        # 特殊文字を含むテキスト
        special_text = "Hello!@#$%^&*()_+-=[]{}|;':\",./<>?"
        result = hash_text(special_text)

        # 64文字のハッシュ値が返される
        assert len(result) == 64, f"Expected 64 characters, got {len(result)}"
        assert re.match(r"^[0-9a-f]{64}$", result), f"Invalid hex format: {result}"

    def test_hash_text_newline_characters(self) -> None:
        """
        改行文字を含むテキストのハッシュ化

        テスト手順:
            1. 改行文字を含むテキストをハッシュ化

        期待結果:
            - 64文字のハッシュ値が返される
            - 改行を含むテキストと含まないテキストは異なるハッシュ値

        関連要件ID: FR-002
        優先度: 低
        """
        from app.utils.hash_utils import hash_text

        # 改行を含むテキスト
        text_with_newline = "line1\nline2"
        text_without_newline = "line1line2"

        hash_with_newline = hash_text(text_with_newline)
        hash_without_newline = hash_text(text_without_newline)

        # 64文字のハッシュ値
        assert len(hash_with_newline) == 64
        assert len(hash_without_newline) == 64

        # 改行の有無でハッシュ値が異なる
        assert hash_with_newline != hash_without_newline, "Newline should affect hash value"
