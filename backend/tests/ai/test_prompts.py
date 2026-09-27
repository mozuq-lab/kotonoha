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


def test_fidelity_rules_reach_every_conversion_and_regeneration() -> None:
    # 利用者は変換結果を声で訂正できない（守る約束 ③）。意味を守る決まりが、どの丁寧さでも再生成でも効くこと
    prompts = [conversion_prompt("いたくない", level) for level in PolitenessLevel]
    prompts.append(regeneration_prompt("いたくない", PolitenessLevel.POLITE, "痛くございません"))
    for prompt in prompts:
        for rule in ("本人", "否定", "足さない", "尊敬語", "症状"):
            assert rule in prompt.system, rule


def test_output_cap_fits_a_short_sentence() -> None:
    # 変換結果は短い文。上限を小さくして 1 回の費用の上限を抑える（切れたら provider が失敗にする）
    assert conversion_prompt("あ", PolitenessLevel.POLITE).max_tokens == 256


def test_polite_level_does_not_invite_archaic_adjective_forms() -> None:
    # 「〜でございます」を例に挙げると「痛うございます」「寒うございます」と古風になった（2026-09-27 実測）
    polite = conversion_prompt("いたい", PolitenessLevel.POLITE)
    assert "でございます" not in polite.user
    assert "うございます" in polite.system  # 使わない、と明記する


def test_bare_word_inputs_are_not_expanded_into_guessed_actions() -> None:
    # 「トイレ」が「トイレに行きたいです」になった（言っていない動作を足す。2026-09-27 実測）
    system = conversion_prompt("トイレ", PolitenessLevel.NORMAL).system
    assert "推測" in system and "トイレ" in system
