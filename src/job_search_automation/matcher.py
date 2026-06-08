from __future__ import annotations

from dataclasses import dataclass

from .profile import CandidateProfile
from .text import normalize_tokens


@dataclass(frozen=True)
class MatchResult:
    score: int
    matched_keywords: list[str]
    missing_keywords: list[str]


def score_job(profile: CandidateProfile, job_text: str) -> MatchResult:
    job_tokens = set(normalize_tokens(job_text))
    profile_keywords = profile.keywords
    matched = [keyword for keyword in profile_keywords if keyword in job_tokens]
    missing = [keyword for keyword in profile_keywords if keyword not in job_tokens]

    if not profile_keywords:
        return MatchResult(score=0, matched_keywords=[], missing_keywords=[])

    score = round((len(matched) / len(profile_keywords)) * 100)
    return MatchResult(score=score, matched_keywords=matched, missing_keywords=missing)
