from __future__ import annotations

import csv
from datetime import date
from pathlib import Path

FIELDS = ["date_added", "company", "title", "url", "status", "notes"]


def ensure_tracker(path: Path) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    if path.exists():
        return
    with path.open("w", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=FIELDS)
        writer.writeheader()


def add_application(
    path: Path,
    *,
    company: str,
    title: str,
    url: str,
    status: str,
    notes: str,
) -> None:
    ensure_tracker(path)
    with path.open("a", newline="", encoding="utf-8") as file:
        writer = csv.DictWriter(file, fieldnames=FIELDS)
        writer.writerow(
            {
                "date_added": date.today().isoformat(),
                "company": company,
                "title": title,
                "url": url,
                "status": status,
                "notes": notes,
            }
        )


def list_applications(path: Path) -> list[dict[str, str]]:
    ensure_tracker(path)
    with path.open("r", newline="", encoding="utf-8") as file:
        return list(csv.DictReader(file))
