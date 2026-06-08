from __future__ import annotations

import json
from dataclasses import asdict, dataclass
from pathlib import Path

from .text import keyword_frequency


@dataclass(frozen=True)
class CandidateProfile:
    keywords: list[str]

    def save(self, path: Path) -> None:
        path.write_text(json.dumps(asdict(self), indent=2), encoding="utf-8")

    @classmethod
    def load(cls, path: Path) -> "CandidateProfile":
        data = json.loads(path.read_text(encoding="utf-8"))
        return cls(keywords=list(data.get("keywords", [])))


def build_profile(resume_text: str, limit: int = 80) -> CandidateProfile:
    keywords = [word for word, _ in keyword_frequency(resume_text).most_common(limit)]
    return CandidateProfile(keywords=keywords)
