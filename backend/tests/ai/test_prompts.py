from __future__ import annotations

import pytest

from app.ai.prompts import PolitenessLevel, conversion_prompt, regeneration_prompt


@pytest.mark.parametrize("level", list(PolitenessLevel))
def test_conversion_prompt_embeds_input_once(level: PolitenessLevel) -> None:
    prompt = conversion_prompt("水 ぬるく", level)
    assert prompt.user.count("水 ぬるく") == 1
    assert prompt.system
    assert 0 < prompt.temperature < 1


def test_regeneration_prompt_asks_for_a_different_wording() -> None:
    prompt = regeneration_prompt("水 ぬるく", PolitenessLevel.POLITE, "お水をください")
    assert "お水をください" in prompt.user and "水 ぬるく" in prompt.user
    assert prompt.temperature > conversion_prompt("水 ぬるく", PolitenessLevel.POLITE).temperature


def test_levels_produce_distinct_instructions() -> None:
    users = {conversion_prompt("あ", level).user for level in PolitenessLevel}
    assert len(users) == 3
