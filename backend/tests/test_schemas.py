from __future__ import annotations

import pytest
from pydantic import ValidationError

from app.ai.prompts import PolitenessLevel
from app.schemas import ConversionRequest, RegenerateRequest


def test_input_is_trimmed() -> None:
    request = ConversionRequest(input_text="  水 ぬるく  ", politeness_level=PolitenessLevel.NORMAL)
    assert request.input_text == "水 ぬるく"


@pytest.mark.parametrize("text", ["あい", "あ" * 500, "🙂🙂", "がき"])  # 結合文字も文字数で数える
def test_boundary_inputs_are_accepted(text: str) -> None:
    assert ConversionRequest(input_text=text, politeness_level="polite").input_text == text


@pytest.mark.parametrize("text", ["", "   ", "あ", "あ" * 501, "🙂"])
def test_out_of_range_inputs_are_rejected(text: str) -> None:
    with pytest.raises(ValidationError):
        ConversionRequest(input_text=text, politeness_level="normal")


def test_unknown_politeness_is_rejected() -> None:
    with pytest.raises(ValidationError):
        ConversionRequest(input_text="水 ぬるく", politeness_level="rude")


@pytest.mark.parametrize("previous", ["", "  ", "あ" * 1001])
def test_previous_result_bounds(previous: str) -> None:
    with pytest.raises(ValidationError):
        RegenerateRequest(
            input_text="水 ぬるく", politeness_level="normal", previous_result=previous
        )


def test_previous_result_is_trimmed() -> None:
    request = RegenerateRequest(
        input_text="水 ぬるく", politeness_level="normal", previous_result=" 前 "
    )
    assert request.previous_result == "前"
