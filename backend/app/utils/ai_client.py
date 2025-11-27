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

import logging
import time
from typing import Literal

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

        # Anthropic クライアント初期化
        if settings.ANTHROPIC_API_KEY:
            try:
                import httpx
                from anthropic import AsyncAnthropic

                # httpxクライアントを明示的に作成（プロキシ設定を無視）
                http_client = httpx.AsyncClient(timeout=settings.AI_API_TIMEOUT)
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
            response = await self.anthropic_client.messages.create(
                model="claude-3-5-sonnet-20241022",
                max_tokens=1024,
                messages=[{"role": "user", "content": prompt}],
            )

            converted_text = response.content[0].text.strip()
            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"Claude conversion completed in {conversion_time_ms}ms: "
                f"'{input_text[:20]}...' -> '{converted_text[:20]}...'"
            )

            return converted_text, conversion_time_ms

        except Exception as e:
            error_message = str(e)
            logger.error(f"Claude API error: {error_message}")

            # タイムアウト判定
            if "timeout" in error_message.lower():
                raise AITimeoutException(f"Claude API timeout: {error_message}") from e

            # レート制限判定
            if "rate" in error_message.lower() or "429" in error_message:
                raise AIRateLimitException(f"Claude API rate limit: {error_message}") from e

            # その他のエラー
            raise AIConversionException(f"Claude API error: {error_message}") from e

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
            response = await self.openai_client.chat.completions.create(
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

            converted_text = response.choices[0].message.content.strip()
            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"OpenAI conversion completed in {conversion_time_ms}ms: "
                f"'{input_text[:20]}...' -> '{converted_text[:20]}...'"
            )

            return converted_text, conversion_time_ms

        except Exception as e:
            error_message = str(e)
            logger.error(f"OpenAI API error: {error_message}")

            # タイムアウト判定
            if "timeout" in error_message.lower():
                raise AITimeoutException(f"OpenAI API timeout: {error_message}") from e

            # レート制限判定
            if "rate" in error_message.lower() or "429" in error_message:
                raise AIRateLimitException(f"OpenAI API rate limit: {error_message}") from e

            # その他のエラー
            raise AIConversionException(f"OpenAI API error: {error_message}") from e

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

                response = await self.anthropic_client.messages.create(
                    model="claude-3-5-sonnet-20241022",
                    max_tokens=1024,
                    messages=[{"role": "user", "content": prompt}],
                )

                converted_text = response.content[0].text.strip()

            elif provider == "openai":
                if not self.openai_client:
                    raise AIProviderException("OpenAI API key is not configured")

                response = await self.openai_client.chat.completions.create(
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

                converted_text = response.choices[0].message.content.strip()

            else:
                raise AIProviderException(f"Unknown AI provider: {provider}")

            conversion_time_ms = int((time.time() - start_time) * 1000)

            logger.info(
                f"AI regeneration completed in {conversion_time_ms}ms: "
                f"'{input_text[:20]}...' -> '{converted_text[:20]}...'"
            )

            return converted_text, conversion_time_ms

        except AIProviderException:
            raise
        except Exception as e:
            error_message = str(e)
            logger.error(f"AI regeneration error: {error_message}")

            # タイムアウト判定
            if "timeout" in error_message.lower():
                raise AITimeoutException(f"AI API timeout: {error_message}") from e

            # レート制限判定
            if "rate" in error_message.lower() or "429" in error_message:
                raise AIRateLimitException(f"AI API rate limit: {error_message}") from e

            # その他のエラー
            raise AIConversionException(f"AI API error: {error_message}") from e


# シングルトンインスタンス
ai_client = AIClient()
