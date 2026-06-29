"""
AIクライアントモジュール

TASK-0026: 外部AI API連携実装（Claude/GPT プロキシ）
🔵 REQ-901, REQ-902, NFR-002に基づく

【機能概要】: Anthropic Claude API および OpenAI GPT APIとの連携を提供
【実装方針】:
  - 両プロバイダーの非同期クライアントを統合
  - 丁寧さレベルに応じたプロンプト生成
  - 処理時間の測定
  - エラーハンドリング（タイムアウト、レート制限等）
"""

import asyncio
import importlib
import logging
import time
from collections.abc import Awaitable, Callable
from typing import Literal, TypeVar

from app.core.config import settings
from app.utils.exceptions import (
    AIConversionException,
    AIProviderException,
    AIRateLimitException,
    AITimeoutException,
)

logger = logging.getLogger(__name__)

# 丁寧さレベルの型定義
PolitenessLevel = Literal["casual", "normal", "polite"]

# _call_with_retry の戻り値型変数
_T = TypeVar("_T")

# プロバイダーSDKの型付き例外のキャッシュ（(タイムアウト型, レート制限型)）
_PROVIDER_EXCEPTION_TYPES: tuple[tuple[type, ...], tuple[type, ...]] | None = None

# リトライ対象の一時的例外型のキャッシュ
_RETRYABLE_EXCEPTION_TYPES: tuple[type, ...] | None = None


def _provider_exception_types() -> tuple[tuple[type, ...], tuple[type, ...]]:
    """インストール済みSDKのタイムアウト/レート制限例外型を収集する。

    anthropic / openai SDKは `APITimeoutError` `RateLimitError` などの型付き例外を
    提供する。文字列マッチではなく型で判定するために、利用可能な型を一度だけ収集する。

    Returns:
        (タイムアウト例外型のタプル, レート制限例外型のタプル)
    """
    global _PROVIDER_EXCEPTION_TYPES
    if _PROVIDER_EXCEPTION_TYPES is not None:
        return _PROVIDER_EXCEPTION_TYPES

    timeout_types: list[type] = []
    rate_types: list[type] = []
    for module_name in ("anthropic", "openai"):
        try:
            module = importlib.import_module(module_name)
        except ImportError:
            continue
        timeout_type = getattr(module, "APITimeoutError", None)
        if isinstance(timeout_type, type):
            timeout_types.append(timeout_type)
        rate_type = getattr(module, "RateLimitError", None)
        if isinstance(rate_type, type):
            rate_types.append(rate_type)

    _PROVIDER_EXCEPTION_TYPES = (tuple(timeout_types), tuple(rate_types))
    return _PROVIDER_EXCEPTION_TYPES


def _retryable_exception_types() -> tuple[type, ...]:
    """リトライ対象の一時的例外型を収集する（SDK 未インストールでも安全）。

    anthropic / openai の APITimeoutError・RateLimitError・APIConnectionError と
    httpx.TimeoutException をリトライ対象とする。importlib で動的収集するため、
    対象 SDK がインストールされていない環境でも例外を送出しない。

    Returns:
        リトライ対象例外型のタプル（空タプルの場合はリトライしない）。
    """
    global _RETRYABLE_EXCEPTION_TYPES
    if _RETRYABLE_EXCEPTION_TYPES is not None:
        return _RETRYABLE_EXCEPTION_TYPES

    types: list[type] = []
    for module_name in ("anthropic", "openai"):
        try:
            module = importlib.import_module(module_name)
        except ImportError:
            continue
        for exc_name in ("APITimeoutError", "RateLimitError", "APIConnectionError"):
            t = getattr(module, exc_name, None)
            if isinstance(t, type):
                types.append(t)

    try:
        httpx_mod = importlib.import_module("httpx")
        t = getattr(httpx_mod, "TimeoutException", None)
        if isinstance(t, type):
            types.append(t)
    except ImportError:
        pass

    _RETRYABLE_EXCEPTION_TYPES = tuple(types)
    return _RETRYABLE_EXCEPTION_TYPES


def _map_provider_exception(error: Exception, provider_label: str) -> Exception:
    """プロバイダーSDKの例外を、対応するアプリ例外へマッピングする。

    型付き例外（SDKの APITimeoutError / RateLimitError / APIStatusError(429)）を優先し、
    判定できない場合のみ文字列ヒューリスティックにフォールバックする。これにより
    ローカライズやSDKのメッセージ変更でタイムアウト/レート制限の判定が外れるのを防ぐ。

    Args:
        error: SDKが送出した例外
        provider_label: ログ/メッセージ用のプロバイダー名（例: "Claude"）

    Returns:
        Exception: AITimeoutException / AIRateLimitException / AIConversionException
    """
    timeout_types, rate_types = _provider_exception_types()
    message = str(error)

    if timeout_types and isinstance(error, timeout_types):
        return AITimeoutException(f"{provider_label} API timeout: {message}")
    if rate_types and isinstance(error, rate_types):
        return AIRateLimitException(f"{provider_label} API rate limit: {message}")

    # APIStatusError 等は status_code を持つ
    status_code = getattr(error, "status_code", None)
    if status_code == 429:
        return AIRateLimitException(f"{provider_label} API rate limit: {message}")

    # フォールバック: 文字列ヒューリスティック
    lowered = message.lower()
    if "timeout" in lowered:
        return AITimeoutException(f"{provider_label} API timeout: {message}")
    if "rate" in lowered or "429" in message:
        return AIRateLimitException(f"{provider_label} API rate limit: {message}")

    return AIConversionException(f"{provider_label} API error: {message}")


def _extract_anthropic_text(response: object) -> str:
    """Anthropicレスポンスから本文テキストを安全に取り出す。

    空content・textブロック以外・空文字の場合は AIConversionException を送出し、
    AttributeError/IndexError による未捕捉500を防ぐ。
    """
    content = getattr(response, "content", None)
    if not content:
        raise AIConversionException("Claude API returned empty content")
    text = getattr(content[0], "text", None)
    if not isinstance(text, str) or not text.strip():
        raise AIConversionException("Claude API returned no text content")
    return text.strip()


def _extract_openai_text(response: object) -> str:
    """OpenAIレスポンスから本文テキストを安全に取り出す。

    空choices・content=None・空文字の場合は AIConversionException を送出する。
    """
    choices = getattr(response, "choices", None)
    if not choices:
        raise AIConversionException("OpenAI API returned no choices")
    message = getattr(choices[0], "message", None)
    content = getattr(message, "content", None)
    if not isinstance(content, str) or not content.strip():
        raise AIConversionException("OpenAI API returned empty content")
    return content.strip()


class AIClient:
    """
    AI APIクライアント（Claude/GPT統合）

    【機能概要】: Anthropic Claude API と OpenAI GPT API を統合したクライアント
    【実装方針】:
      - 環境変数からAPIキーを取得して初期化
      - プロバイダーごとのクライアントをlazy初期化
      - 丁寧さレベルに応じたプロンプト生成
      - 変換処理時間の測定

    Attributes:
        anthropic_client: Anthropic APIクライアント
        openai_client: OpenAI APIクライアント

    🔵 REQ-901, REQ-902に基づく
    """

    def __init__(self) -> None:
        """
        AIClientの初期化

        【初期化処理】: APIキーが設定されている場合のみクライアントを初期化
        """
        self.anthropic_client = None
        self.openai_client = None
        # 明示生成した httpx クライアントを保持し、shutdown 時にクローズする
        self._anthropic_http_client = None

        # Anthropic クライアント初期化
        if settings.ANTHROPIC_API_KEY:
            try:
                import httpx
                from anthropic import AsyncAnthropic

                # httpxクライアントを明示的に作成（プロキシ設定を無視）
                http_client = httpx.AsyncClient(timeout=settings.AI_API_TIMEOUT)
                self._anthropic_http_client = http_client
                self.anthropic_client = AsyncAnthropic(
                    api_key=settings.ANTHROPIC_API_KEY,
                    http_client=http_client,
                )
                logger.info("Anthropic client initialized")
            except ImportError:
                logger.warning("anthropic package not installed")
            except Exception as e:
                logger.error(f"Failed to initialize Anthropic client: {e}")

        # OpenAI クライアント初期化
        if settings.OPENAI_API_KEY:
            try:
                from openai import AsyncOpenAI

                self.openai_client = AsyncOpenAI(
                    api_key=settings.OPENAI_API_KEY,
                    timeout=settings.AI_API_TIMEOUT,
                )
                logger.info("OpenAI client initialized")
            except ImportError:
                logger.warning("openai package not installed")
            except Exception as e:
                logger.error(f"Failed to initialize OpenAI client: {e}")

    def _get_politeness_instruction(self, level: PolitenessLevel) -> str:
        """
        丁寧さレベルに応じたプロンプト指示を生成

        【機能概要】: 入力された丁寧さレベルに応じた変換指示文を返す
        【実装方針】: 3段階のレベルに対応、無効なレベルはnormalにフォールバック

        Args:
            level: 丁寧さレベル（casual/normal/polite）

        Returns:
            str: 変換指示文

        🔵 REQ-902に基づく
        """
        instructions = {
            "casual": (
                "カジュアルで親しみやすい表現に変換してください。"
                "タメ口や砕けた言い回しを使用します。"
            ),
            "normal": "標準的な丁寧さの「です・ます」調の表現に変換してください。",
            "polite": (
                "非常に丁寧で敬意を込めた敬語表現に変換してください。"
                "尊敬語・謙譲語を適切に使用します。"
            ),
        }
        return instructions.get(level, instructions["normal"])

    async def convert_text_anthropic(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
    ) -> tuple[str, int]:
        """
        Claude APIで文字列変換

        【機能概要】: Anthropic Claude APIを使用してテキストを変換
        【実装方針】:
          - 丁寧さレベルに応じたプロンプトを生成
          - 処理時間を測定
          - エラーハンドリング

        Args:
            input_text: 変換対象のテキスト
            politeness_level: 丁寧さレベル

        Returns:
            tuple[str, int]: (変換後テキスト, 処理時間ミリ秒)

        Raises:
            AIProviderException: APIキーが設定されていない場合
            AITimeoutException: APIタイムアウト時
            AIRateLimitException: レート制限超過時
            AIConversionException: その他の変換エラー

        🔵 REQ-901, NFR-002に基づく
        """
        if not self.anthropic_client:
            raise AIProviderException("Anthropic API key is not configured")

        start_time = time.time()

        instruction = self._get_politeness_instruction(politeness_level)
        prompt = f"""以下の日本語文を{instruction}

入力文: {input_text}

変換後の文のみを出力してください。説明や追加情報は不要です。"""

        try:
            response = await self._call_with_retry(
                lambda: self.anthropic_client.messages.create(
                    model=settings.ANTHROPIC_MODEL,
                    max_tokens=1024,
                    messages=[{"role": "user", "content": prompt}],
                )
            )

            converted_text = _extract_anthropic_text(response)
            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"Claude conversion completed in {conversion_time_ms}ms: "
                f"input_length={len(input_text)}, output_length={len(converted_text)}"
            )

            return converted_text, conversion_time_ms

        except (
            AIProviderException,
            AITimeoutException,
            AIRateLimitException,
            AIConversionException,
        ):
            # 既にマッピング済みのアプリ例外（空content検証含む）はそのまま伝播
            raise
        except Exception as e:
            logger.error(f"Claude API error: {e}")
            raise _map_provider_exception(e, "Claude") from e

    async def convert_text_openai(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
    ) -> tuple[str, int]:
        """
        OpenAI GPT APIで文字列変換

        【機能概要】: OpenAI GPT APIを使用してテキストを変換
        【実装方針】:
          - 丁寧さレベルに応じたプロンプトを生成
          - 処理時間を測定
          - エラーハンドリング

        Args:
            input_text: 変換対象のテキスト
            politeness_level: 丁寧さレベル

        Returns:
            tuple[str, int]: (変換後テキスト, 処理時間ミリ秒)

        Raises:
            AIProviderException: APIキーが設定されていない場合
            AITimeoutException: APIタイムアウト時
            AIRateLimitException: レート制限超過時
            AIConversionException: その他の変換エラー

        🔵 REQ-901, NFR-002に基づく
        """
        if not self.openai_client:
            raise AIProviderException("OpenAI API key is not configured")

        start_time = time.time()

        instruction = self._get_politeness_instruction(politeness_level)
        prompt = f"""以下の日本語文を{instruction}

入力文: {input_text}

変換後の文のみを出力してください。説明や追加情報は不要です。"""

        try:
            response = await self._call_with_retry(
                lambda: self.openai_client.chat.completions.create(
                    model=settings.OPENAI_MODEL,
                    messages=[
                        {
                            "role": "system",
                            "content": "あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。",
                        },
                        {"role": "user", "content": prompt},
                    ],
                    max_tokens=1024,
                    temperature=0.7,
                )
            )

            converted_text = _extract_openai_text(response)
            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"OpenAI conversion completed in {conversion_time_ms}ms: "
                f"input_length={len(input_text)}, output_length={len(converted_text)}"
            )

            return converted_text, conversion_time_ms

        except (
            AIProviderException,
            AITimeoutException,
            AIRateLimitException,
            AIConversionException,
        ):
            raise
        except Exception as e:
            logger.error(f"OpenAI API error: {e}")
            raise _map_provider_exception(e, "OpenAI") from e

    async def convert_text(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
        provider: str | None = None,
    ) -> tuple[str, int]:
        """
        AI変換（プロバイダー自動選択）

        【機能概要】: 指定されたプロバイダー（またはデフォルト）でテキストを変換
        【実装方針】:
          - provider引数でプロバイダーを明示的に指定可能
          - 指定がない場合はDEFAULT_AI_PROVIDERを使用
          - 無効なプロバイダーはAIProviderExceptionを送出

        Args:
            input_text: 変換対象のテキスト
            politeness_level: 丁寧さレベル
            provider: 使用するプロバイダー（"anthropic" or "openai"）

        Returns:
            tuple[str, int]: (変換後テキスト, 処理時間ミリ秒)

        Raises:
            AIProviderException: 無効なプロバイダー指定時

        🔵 api-endpoints.mdに基づく
        """
        provider = provider or settings.DEFAULT_AI_PROVIDER

        if provider == "anthropic":
            return await self.convert_text_anthropic(input_text, politeness_level)
        elif provider == "openai":
            return await self.convert_text_openai(input_text, politeness_level)
        else:
            raise AIProviderException(f"Unknown AI provider: {provider}")

    async def regenerate_text(
        self,
        input_text: str,
        politeness_level: PolitenessLevel,
        previous_result: str,
        provider: str | None = None,
    ) -> tuple[str, int]:
        """
        AI再変換（前回と異なる表現を生成）

        【機能概要】: 前回の変換結果と異なる表現を生成
        【実装方針】:
          - 前回結果を参考にして異なる表現を指示
          - temperature を高めに設定して多様性を確保
          - provider引数でプロバイダーを明示的に指定可能

        Args:
            input_text: 変換対象のテキスト
            politeness_level: 丁寧さレベル
            previous_result: 前回の変換結果（重複回避用）
            provider: 使用するプロバイダー（"anthropic" or "openai"）

        Returns:
            tuple[str, int]: (変換後テキスト, 処理時間ミリ秒)

        Raises:
            AIProviderException: 無効なプロバイダー指定時
            AITimeoutException: APIタイムアウト時
            AIRateLimitException: レート制限超過時
            AIConversionException: その他の変換エラー

        🔵 REQ-904（同じ丁寧さで再変換可能）に基づく
        """
        provider = provider or settings.DEFAULT_AI_PROVIDER

        start_time = time.time()

        instruction = self._get_politeness_instruction(politeness_level)
        prompt = f"""以下の日本語文を{instruction}

元の入力文: {input_text}
前回の変換結果: {previous_result}

前回と**異なる表現**で変換してください。意味は同じでも、言い回しを変えてください。
変換後の文のみを出力してください。説明や追加情報は不要です。"""

        try:
            if provider == "anthropic":
                if not self.anthropic_client:
                    raise AIProviderException("Anthropic API key is not configured")

                response = await self._call_with_retry(
                    lambda: self.anthropic_client.messages.create(
                        model=settings.ANTHROPIC_MODEL,
                        max_tokens=1024,
                        messages=[{"role": "user", "content": prompt}],
                    )
                )

                converted_text = _extract_anthropic_text(response)

            elif provider == "openai":
                if not self.openai_client:
                    raise AIProviderException("OpenAI API key is not configured")

                response = await self._call_with_retry(
                    lambda: self.openai_client.chat.completions.create(
                        model=settings.OPENAI_MODEL,
                        messages=[
                            {
                                "role": "system",
                                "content": "あなたは日本語の文章を適切な丁寧さレベルに変換する専門家です。",
                            },
                            {"role": "user", "content": prompt},
                        ],
                        max_tokens=1024,
                        temperature=0.9,  # 多様性を高める
                    )
                )

                converted_text = _extract_openai_text(response)

            else:
                raise AIProviderException(f"Unknown AI provider: {provider}")

            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"AI regeneration completed in {conversion_time_ms}ms: "
                f"input_length={len(input_text)}, output_length={len(converted_text)}"
            )

            return converted_text, conversion_time_ms

        except (
            AIProviderException,
            AITimeoutException,
            AIRateLimitException,
            AIConversionException,
        ):
            raise
        except Exception as e:
            logger.error(f"AI regeneration error: {e}")
            raise _map_provider_exception(e, "AI") from e

    async def _call_with_retry(self, factory: Callable[[], Awaitable[_T]]) -> _T:
        """リトライ付き API 呼び出し。

        一時的な例外（タイムアウト / レート制限 / 接続エラー）を
        settings.AI_MAX_RETRIES 回まで指数バックオフで再試行する。
        リトライ対象外の例外は即座に伝播させる。
        リトライを使い切った場合は最後の例外を再 raise し、呼び出し元の
        ``except Exception`` ブロックに処理させる。

        Args:
            factory: 呼び出しごとに新しい awaitable を返す 0 引数 callable。

        Returns:
            API レスポンス。

        Raises:
            最後の試行で発生した例外（リトライ対象外の例外はそのまま伝播）。
        """
        max_retries = max(1, settings.AI_MAX_RETRIES)
        retryable = _retryable_exception_types()
        last_exc: BaseException | None = None

        for attempt in range(max_retries):
            try:
                return await factory()
            except Exception as exc:
                if not retryable or not isinstance(exc, retryable):
                    raise
                last_exc = exc
                if attempt < max_retries - 1:
                    await asyncio.sleep(0.5 * (2**attempt))

        raise last_exc  # type: ignore[misc]

    async def aclose(self) -> None:
        """保持しているHTTPクライアントを明示的にクローズする。

        明示生成した httpx.AsyncClient はそのままだとクローズされず、
        「Unclosed client」警告やリソースリークの原因になる。アプリの
        shutdown（lifespan）から呼び出してクリーンアップする。
        """
        if self._anthropic_http_client is not None:
            try:
                await self._anthropic_http_client.aclose()
            except Exception as e:  # クローズ失敗はログのみ（shutdownを阻害しない）
                logger.warning(f"Failed to close Anthropic HTTP client: {e}")
            finally:
                self._anthropic_http_client = None

        if self.openai_client is not None:
            close = getattr(self.openai_client, "close", None)
            if callable(close):
                try:
                    await close()
                except Exception as e:
                    logger.warning(f"Failed to close OpenAI client: {e}")


# シングルトンインスタンス
ai_client = AIClient()
