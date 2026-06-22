from __future__ import annotations

import argparse
import hashlib
import json
import math
import re
from collections import Counter, defaultdict
from dataclasses import dataclass
from datetime import UTC, datetime
from pathlib import Path
from typing import Iterable, Sequence


TOKEN_RE = re.compile(r"[a-z0-9]+|[\u4e00-\u9fff]+", re.IGNORECASE)
STOPWORDS = {
    "a",
    "an",
    "and",
    "as",
    "for",
    "in",
    "of",
    "on",
    "or",
    "the",
    "to",
    "with",
}
FAMILY_ALIASES = {
    "debug": "debug",
    "debugger": "debug",
    "debugging": "debug",
    "systematic-debugging": "debug",
    "tdd": "tdd",
    "rtk-tdd": "tdd",
    "test-driven-development": "tdd",
    "browse": "browse",
    "agent-browser": "browse",
    "dev-browser": "browse",
    "playwright": "browser-qa",
    "qa-testing": "qa",
    "qa-tester": "qa",
    "qa-only": "qa",
    "code-review": "code-review",
    "code-reviewer": "code-review",
    "review": "code-review",
    "security-review": "security-review",
    "security-reviewer": "security-review",
    "skill": "skill-management",
    "skill-installer": "skill-management",
    "skillify": "skill-management",
    "skill-creator": "skill-management",
    "template-skill": "skill-management",
    "writing-skills": "skill-management",
    "find-skills": "skill-management",
}


@dataclass(frozen=True)
class SkillCard:
    name: str
    description: str
    path: str
    root: str
    family: str = ""

    def __post_init__(self) -> None:
        if not self.family:
            object.__setattr__(self, "family", infer_family(self.name, self.path))


@dataclass(frozen=True)
class RankedSkill:
    card: SkillCard
    score: float
    reasons: tuple[str, ...]


@dataclass(frozen=True)
class RouteResult:
    query: str
    decision: str
    selected: list[RankedSkill]
    suppressed_siblings: list[dict[str, object]]
    candidate_count: int


def default_codex_skill_roots() -> list[Path]:
    base = Path.home() / ".codex"
    return [base / "skills", base / "plugins" / "cache"]


def discover_skill_cards(roots: Iterable[Path | str]) -> list[SkillCard]:
    cards: list[SkillCard] = []
    for root_value in roots:
        root = Path(root_value).expanduser()
        if not root.exists():
            continue
        for skill_file in sorted(root.rglob("SKILL.md")):
            metadata = parse_skill_frontmatter(skill_file)
            name = metadata.get("name") or skill_file.parent.name
            description = metadata.get("description") or first_markdown_heading(skill_file)
            cards.append(
                SkillCard(
                    name=name.strip(),
                    description=single_line(description),
                    path=str(skill_file),
                    root=str(root),
                )
            )
    return cards


def parse_skill_frontmatter(path: Path) -> dict[str, str]:
    lines = path.read_text(encoding="utf-8", errors="replace").splitlines()
    if not lines or lines[0].strip() != "---":
        return {}
    metadata: dict[str, str] = {}
    for line in lines[1:]:
        if line.strip() == "---":
            break
        if ":" not in line:
            continue
        key, value = line.split(":", 1)
        key = key.strip()
        value = value.strip().strip("'\"")
        if key in {"name", "description"} and value:
            metadata[key] = value
    return metadata


def first_markdown_heading(path: Path) -> str:
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        stripped = line.strip()
        if stripped.startswith("#"):
            return stripped.lstrip("#").strip()
    return path.parent.name


def route_skills(
    query: str,
    cards: Sequence[SkillCard],
    *,
    top_k: int = 5,
    min_score: float = 0.08,
    relative_score_floor: float = 0.4,
) -> RouteResult:
    if top_k < 1:
        raise ValueError("top_k must be >= 1")

    scored = score_cards(query, cards)
    best_score = scored[0].score if scored else 0.0
    relative_floor = best_score * relative_score_floor
    candidates = [item for item in scored if item.score >= min_score and item.score >= relative_floor]
    selected: list[RankedSkill] = []
    family_kept: dict[str, RankedSkill] = {}

    for item in candidates:
        family = item.card.family
        if family in family_kept:
            continue
        if len(selected) >= top_k:
            continue
        selected.append(item)
        family_kept[family] = item

    selected_names = {item.card.name for item in selected}
    suppressed_by_family: dict[str, list[RankedSkill]] = defaultdict(list)
    for item in scored:
        family = item.card.family
        if item.score < min_score or family not in family_kept or item.card.name in selected_names:
            continue
        suppressed_by_family[family].append(item)

    suppressed = [
        {
            "family": family,
            "kept": family_kept[family].card.name,
            "suppressed": [item.card.name for item in items],
        }
        for family, items in sorted(suppressed_by_family.items())
        if family in family_kept and items
    ]
    decision = "expose" if selected else "no_skill"
    return RouteResult(
        query=query,
        decision=decision,
        selected=selected,
        suppressed_siblings=suppressed,
        candidate_count=len(candidates),
    )


def score_cards(query: str, cards: Sequence[SkillCard]) -> list[RankedSkill]:
    query_tokens = tokenize(query)
    if not query_tokens:
        return []
    documents = [card_document_tokens(card) for card in cards]
    doc_freq = Counter(term for doc in documents for term in set(doc))
    average_len = sum(len(doc) for doc in documents) / max(len(documents), 1)
    ranked: list[RankedSkill] = []

    for card, doc_tokens in zip(cards, documents, strict=True):
        bm25 = bm25_score(query_tokens, doc_tokens, doc_freq, len(cards), average_len)
        surface = trigram_similarity(normalize_text(query), normalize_text(card.name + " " + card.description))
        name_overlap = len(set(query_tokens) & set(tokenize(card.name))) * 0.08
        intent = intent_boost(query_tokens, card)
        route_penalty = has_route_intent(query_tokens) and not has_route_signal(card)
        score = bm25 + surface * 0.35 + name_overlap + intent
        if route_penalty:
            score *= 0.75
        reasons = build_reasons(query_tokens, card, bm25, surface, name_overlap, intent, route_penalty)
        ranked.append(RankedSkill(card=card, score=score, reasons=tuple(reasons)))

    return sorted(ranked, key=lambda item: (-item.score, item.card.family, item.card.name, item.card.path))


def bm25_score(
    query_tokens: Sequence[str],
    doc_tokens: Sequence[str],
    doc_freq: Counter[str],
    document_count: int,
    average_len: float,
) -> float:
    if not doc_tokens:
        return 0.0
    term_counts = Counter(doc_tokens)
    score = 0.0
    k1 = 1.4
    b = 0.75
    doc_len = len(doc_tokens)
    for term in set(query_tokens):
        if term not in term_counts:
            continue
        df = doc_freq[term]
        idf = math.log(1 + (document_count - df + 0.5) / (df + 0.5))
        tf = term_counts[term]
        denominator = tf + k1 * (1 - b + b * doc_len / max(average_len, 1))
        score += idf * ((tf * (k1 + 1)) / denominator)
    return score


def render_exposure_bundle(result: RouteResult, *, max_description_chars: int = 160) -> str:
    payload = {
        "decision": result.decision,
        "query": result.query,
        "top_k": len(result.selected),
        "candidate_count": result.candidate_count,
        "skills": [
            {
                "name": item.card.name,
                "family": item.card.family,
                "score": round(item.score, 4),
                "description": truncate(item.card.description, max_description_chars),
                "path": item.card.path,
                "reasons": list(item.reasons),
            }
            for item in result.selected
        ],
        "suppressed_siblings": result.suppressed_siblings,
    }
    return json.dumps(payload, ensure_ascii=False, indent=2)


def build_skill_index(cards: Sequence[SkillCard]) -> dict[str, object]:
    families: dict[str, list[str]] = defaultdict(list)
    for card in cards:
        families[card.family].append(card.name)
    return {
        "skill_count": len(cards),
        "family_count": len(families),
        "families": {family: sorted(set(names)) for family, names in sorted(families.items())},
        "skills": [
            {
                "name": card.name,
                "family": card.family,
                "description": card.description,
                "path": card.path,
                "root": card.root,
            }
            for card in cards
        ],
    }


def record_route_event(log_path: Path | str, result: RouteResult, *, outcome: str = "unknown") -> None:
    path = Path(log_path)
    path.parent.mkdir(parents=True, exist_ok=True)
    event = {
        "timestamp_utc": datetime.now(UTC).isoformat(timespec="seconds"),
        "decision": result.decision,
        "query_sha256": hashlib.sha256(result.query.encode("utf-8")).hexdigest(),
        "query_length": len(result.query),
        "candidate_count": result.candidate_count,
        "shown_skills": [
            {
                "name": item.card.name,
                "family": item.card.family,
                "score": round(item.score, 4),
            }
            for item in result.selected
        ],
        "suppressed_siblings": result.suppressed_siblings,
        "outcome": outcome,
    }
    with path.open("a", encoding="utf-8") as handle:
        handle.write(json.dumps(event, ensure_ascii=False, sort_keys=True) + "\n")


def summarize_telemetry(log_path: Path | str) -> dict[str, object]:
    path = Path(log_path)
    event_count = 0
    skill_counts: dict[str, dict[str, object]] = {}
    if not path.exists():
        return {"event_count": 0, "skills": {}}
    for line in path.read_text(encoding="utf-8", errors="replace").splitlines():
        if not line.strip():
            continue
        event = json.loads(line)
        event_count += 1
        outcome = str(event.get("outcome") or "unknown")
        for shown in event.get("shown_skills", []):
            name = str(shown["name"])
            stats = skill_counts.setdefault(
                name,
                {
                    "shown_count": 0,
                    "families": set(),
                    "outcomes": Counter(),
                },
            )
            stats["shown_count"] = int(stats["shown_count"]) + 1
            stats["families"].add(str(shown.get("family") or "unknown"))
            stats["outcomes"][outcome] += 1
    serializable = {
        name: {
            "shown_count": stats["shown_count"],
            "families": sorted(stats["families"]),
            "outcomes": dict(sorted(stats["outcomes"].items())),
        }
        for name, stats in sorted(skill_counts.items())
    }
    return {"event_count": event_count, "skills": serializable}


def infer_family(name: str, path: str = "") -> str:
    slug = normalize_slug(name.split(":")[-1])
    if slug in FAMILY_ALIASES:
        return FAMILY_ALIASES[slug]
    return slug


def card_document_tokens(card: SkillCard) -> list[str]:
    return tokenize(" ".join([card.name, card.name, card.description, card.family]))


def tokenize(text: str) -> list[str]:
    normalized = re.sub(r"([a-z])([A-Z])", r"\1 \2", text)
    tokens = [token.lower() for token in TOKEN_RE.findall(normalized.replace("-", " ").replace("_", " "))]
    return [stem(token) for token in tokens if token not in STOPWORDS]


def stem(token: str) -> str:
    for suffix in ("ing", "ers", "er", "ed", "s"):
        if len(token) > len(suffix) + 3 and token.endswith(suffix):
            return token[: -len(suffix)]
    return token


def normalize_slug(value: str) -> str:
    normalized = re.sub(r"([a-z])([A-Z])", r"\1 \2", value)
    tokens = [
        token.lower()
        for token in TOKEN_RE.findall(normalized.replace("-", " ").replace("_", " "))
        if token.lower() not in STOPWORDS
    ]
    return "-".join(tokens) if tokens else "unknown"


def normalize_text(value: str) -> str:
    return " ".join(tokenize(value))


def trigram_similarity(left: str, right: str) -> float:
    left_grams = trigrams(left)
    right_grams = trigrams(right)
    if not left_grams or not right_grams:
        return 0.0
    return len(left_grams & right_grams) / len(left_grams | right_grams)


def trigrams(value: str) -> set[str]:
    compact = re.sub(r"\s+", " ", value.strip())
    if len(compact) < 3:
        return {compact} if compact else set()
    return {compact[index : index + 3] for index in range(len(compact) - 2)}


def build_reasons(
    query_tokens: Sequence[str],
    card: SkillCard,
    bm25: float,
    surface: float,
    name_overlap: float,
    intent: float,
    route_penalty: bool,
) -> list[str]:
    card_tokens = set(card_document_tokens(card))
    overlap = sorted(set(query_tokens) & card_tokens)
    reasons = []
    if overlap:
        reasons.append("matched:" + ",".join(overlap[:6]))
    if bm25 > 0:
        reasons.append("bm25")
    if surface > 0:
        reasons.append("surface")
    if name_overlap > 0:
        reasons.append("name")
    if intent > 0:
        reasons.append("intent")
    if route_penalty:
        reasons.append("route-penalty")
    return reasons or ["fallback"]


def intent_boost(query_tokens: Sequence[str], card: SkillCard) -> float:
    boost = 0.0
    if has_route_intent(query_tokens) and {"route", "rout", "router"} & set(tokenize(card.name)):
        boost += 1.6
    if has_debug_intent(query_tokens) and has_debug_signal(card):
        boost += 1.4
    return boost


def has_route_intent(query_tokens: Sequence[str]) -> bool:
    return bool({"route", "rout", "router"} & set(query_tokens))


def has_route_signal(card: SkillCard) -> bool:
    return bool({"route", "rout", "router"} & set(card_document_tokens(card)))


def has_debug_intent(query_tokens: Sequence[str]) -> bool:
    return bool({"debug", "fail", "failure", "regression", "root", "cause"} & set(query_tokens))


def has_debug_signal(card: SkillCard) -> bool:
    return card.family == "debug" or bool({"debug", "root", "cause"} & set(card_document_tokens(card)))


def single_line(value: str) -> str:
    return re.sub(r"\s+", " ", value).strip()


def truncate(value: str, max_chars: int) -> str:
    if max_chars < 1:
        return ""
    if len(value) <= max_chars:
        return value
    if max_chars <= 3:
        return value[:max_chars]
    return value[: max_chars - 3].rstrip() + "..."


def main(argv: Sequence[str] | None = None) -> int:
    parser = argparse.ArgumentParser(description="Route Codex SKILL.md cards with top-K family gating.")
    parser.add_argument("--query", help="Task/query text to route.")
    parser.add_argument("--root", action="append", help="Skill root. Defaults to local Codex skill roots.")
    parser.add_argument("--top-k", type=int, default=5)
    parser.add_argument("--min-score", type=float, default=0.08)
    parser.add_argument("--index-only", action="store_true")
    parser.add_argument("--telemetry-log", help="Optional JSONL path for route telemetry. Raw query text is not stored.")
    parser.add_argument("--telemetry-summary", action="store_true", help="Summarize --telemetry-log instead of routing.")
    parser.add_argument("--outcome", default="unknown", help="Outcome label recorded with --telemetry-log.")
    parser.add_argument("--pretty", action="store_true")
    args = parser.parse_args(argv)

    if args.telemetry_summary:
        if not args.telemetry_log:
            parser.error("--telemetry-summary requires --telemetry-log")
        payload = summarize_telemetry(args.telemetry_log)
        print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
        return 0

    roots = [Path(item) for item in args.root] if args.root else default_codex_skill_roots()
    cards = discover_skill_cards(roots)
    if args.index_only:
        payload: object = build_skill_index(cards)
    else:
        if not args.query:
            parser.error("--query is required unless --index-only is set")
        result = route_skills(args.query, cards, top_k=args.top_k, min_score=args.min_score)
        if args.telemetry_log:
            record_route_event(args.telemetry_log, result, outcome=args.outcome)
        payload = json.loads(render_exposure_bundle(result))
    print(json.dumps(payload, ensure_ascii=False, indent=2 if args.pretty else None))
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
