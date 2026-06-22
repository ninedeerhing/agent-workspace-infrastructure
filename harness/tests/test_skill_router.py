import json
import tempfile
import unittest
from pathlib import Path

from harness import skill_router


class SkillRouterTests(unittest.TestCase):
    def test_discovers_skill_cards_from_skill_md_frontmatter(self) -> None:
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            skill_dir = root / "test-driven-development"
            skill_dir.mkdir()
            (skill_dir / "SKILL.md").write_text(
                "---\n"
                "name: test-driven-development\n"
                "description: Write a failing test before implementation.\n"
                "---\n"
                "# Test Driven Development\n",
                encoding="utf-8",
            )

            cards = skill_router.discover_skill_cards([root])

        self.assertEqual(len(cards), 1)
        self.assertEqual(cards[0].name, "test-driven-development")
        self.assertEqual(cards[0].description, "Write a failing test before implementation.")
        self.assertEqual(cards[0].family, "tdd")

    def test_routes_top_k_with_family_dedupe_and_suppressed_siblings(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="debugging",
                description="General debugging workflow.",
                path="skills/debugging/SKILL.md",
                root="r0",
                family="debug",
            ),
            skill_router.SkillCard(
                name="systematic-debugging",
                description="Root cause debugging with reproduction and verification.",
                path="skills/systematic-debugging/SKILL.md",
                root="r0",
                family="debug",
            ),
            skill_router.SkillCard(
                name="test-driven-development",
                description="Write a failing test before production code.",
                path="skills/test-driven-development/SKILL.md",
                root="r0",
                family="tdd",
            ),
        ]

        result = skill_router.route_skills(
            "debug a failing regression with a reproducible root cause",
            cards,
            top_k=3,
            min_score=0.01,
        )

        self.assertEqual([item.card.name for item in result.selected], ["systematic-debugging"])
        self.assertEqual(result.suppressed_siblings[0]["kept"], "systematic-debugging")
        self.assertEqual(result.suppressed_siblings[0]["suppressed"], ["debugging"])

    def test_low_confidence_query_exposes_no_skills(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="pdf",
                description="Create and inspect PDF files.",
                path="skills/pdf/SKILL.md",
                root="r0",
                family="pdf",
            )
        ]

        result = skill_router.route_skills("what time is it", cards, top_k=5, min_score=0.25)

        self.assertEqual(result.selected, [])
        self.assertEqual(result.decision, "no_skill")

    def test_path_words_do_not_dominate_skill_router_queries(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="local-build-reminder",
                description="Remind the user to rebuild a local fork after TypeScript edits.",
                path="C:/Users/NINEDEER/.codex/skills/local-build-reminder/SKILL.md",
                root="r0",
            ),
            skill_router.SkillCard(
                name="omo-agent-router",
                description="Route tasks to the right agent and capability with load balancing.",
                path="C:/Users/NINEDEER/.codex/skills/omo-agent-router/SKILL.md",
                root="r0",
            ),
        ]

        result = skill_router.route_skills("build a local Codex skills router", cards, top_k=1, min_score=0.01)

        self.assertEqual([item.card.name for item in result.selected], ["omo-agent-router"])

    def test_debug_intent_prefers_debug_family_over_benchmark_noise(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="benchmark",
                description="Benchmark models and compare performance regressions.",
                path="skills/benchmark/SKILL.md",
                root="r0",
            ),
            skill_router.SkillCard(
                name="debug",
                description="Debug failures with root cause analysis and verification.",
                path="skills/debug/SKILL.md",
                root="r0",
            ),
        ]

        result = skill_router.route_skills("debug a failing regression", cards, top_k=1, min_score=0.01)

        self.assertEqual([item.card.name for item in result.selected], ["debug"])

    def test_family_inference_ignores_generic_skill_root_directory(self) -> None:
        self.assertEqual(
            skill_router.infer_family(
                "local-build-reminder",
                "C:/Users/NINEDEER/.codex/skills/local-build-reminder/SKILL.md",
            ),
            "local-build-reminder",
        )
        self.assertEqual(
            skill_router.infer_family("skill-creator", "C:/Users/NINEDEER/.codex/skills/skill-creator/SKILL.md"),
            "skill-management",
        )
        self.assertEqual(
            skill_router.infer_family("skill-installer", "C:/Users/NINEDEER/.codex/skills/.system/skill-installer/SKILL.md"),
            "skill-management",
        )

    def test_exposure_bundle_is_bounded_and_machine_readable(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="test-driven-development",
                description="Write a failing test before production code.",
                path="skills/test-driven-development/SKILL.md",
                root="r0",
                family="tdd",
            )
        ]

        result = skill_router.route_skills("implement a feature with tests first", cards, top_k=1, min_score=0.01)
        bundle = skill_router.render_exposure_bundle(result, max_description_chars=32)
        payload = json.loads(bundle)

        self.assertEqual(payload["decision"], "expose")
        self.assertEqual(payload["top_k"], 1)
        self.assertEqual(payload["skills"][0]["name"], "test-driven-development")
        self.assertLessEqual(len(payload["skills"][0]["description"]), 32)

    def test_records_and_summarizes_route_telemetry(self) -> None:
        cards = [
            skill_router.SkillCard(
                name="test-driven-development",
                description="Write a failing test before production code.",
                path="skills/test-driven-development/SKILL.md",
                root="r0",
                family="tdd",
            )
        ]
        result = skill_router.route_skills("implement with tests first", cards, top_k=1, min_score=0.01)

        with tempfile.TemporaryDirectory() as tmp:
            log_path = Path(tmp) / "skill-route-events.jsonl"
            skill_router.record_route_event(log_path, result, outcome="success")
            summary = skill_router.summarize_telemetry(log_path)

        self.assertEqual(summary["event_count"], 1)
        self.assertEqual(summary["skills"]["test-driven-development"]["shown_count"], 1)
        self.assertEqual(summary["skills"]["test-driven-development"]["outcomes"]["success"], 1)


if __name__ == "__main__":
    unittest.main()
