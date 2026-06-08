from __future__ import annotations

import re
from collections import Counter

STOP_WORDS = {
    "a",
    "an",
    "and",
    "are",
    "as",
    "at",
    "be",
    "by",
    "for",
    "from",
    "in",
    "into",
    "is",
    "it",
    "of",
    "on",
    "or",
    "that",
    "the",
    "to",
    "with",
    "you",
    "your",
}


def normalize_tokens(text: str) -> list[str]:
    tokens = re.findall(r"[a-zA-Z][a-zA-Z0-9+#.-]{1,}", text.lower())
    cleaned = [token.strip(".-") for token in tokens]
    return [token for token in cleaned if token not in STOP_WORDS and len(token) > 2]


def keyword_frequency(text: str) -> Counter[str]:
    return Counter(normalize_tokens(text))
