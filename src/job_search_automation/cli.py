from __future__ import annotations

import argparse
from pathlib import Path

from .matcher import score_job
from .profile import CandidateProfile, build_profile
from .resume import read_resume_text
from .tracker import add_application, ensure_tracker, list_applications

ROOT = Path.cwd()
DATA_DIR = ROOT / "data"
PROFILE_PATH = DATA_DIR / "profile.json"
TRACKER_PATH = DATA_DIR / "applications.csv"


def profile_command(args: argparse.Namespace) -> None:
    resume_path = Path(args.resume)
    text = read_resume_text(resume_path)
    profile = build_profile(text)
    PROFILE_PATH.parent.mkdir(parents=True, exist_ok=True)
    profile.save(PROFILE_PATH)

    print(f"Saved profile to {PROFILE_PATH}")
    print(f"Found {len(profile.keywords)} keywords.")
    print("Top keywords:", ", ".join(profile.keywords[:20]))


def score_command(args: argparse.Namespace) -> None:
    if not PROFILE_PATH.exists():
        raise SystemExit("No profile found. Run the profile command first.")

    profile = CandidateProfile.load(PROFILE_PATH)
    job_text = Path(args.job).read_text(encoding="utf-8")
    result = score_job(profile, job_text)

    print(f"Score: {result.score}/100")
    print(f"Matched keywords: {', '.join(result.matched_keywords) or 'None'}")
    print(f"Missing keywords: {', '.join(result.missing_keywords[:20]) or 'None'}")


def add_command(args: argparse.Namespace) -> None:
    ensure_tracker(TRACKER_PATH)
    add_application(
        TRACKER_PATH,
        company=args.company,
        title=args.title,
        url=args.url,
        status=args.status,
        notes=args.notes,
    )
    print(f"Added {args.title} at {args.company} to {TRACKER_PATH}")


def list_command(_: argparse.Namespace) -> None:
    ensure_tracker(TRACKER_PATH)
    rows = list_applications(TRACKER_PATH)
    if not rows:
        print("No applications tracked yet.")
        return

    for row in rows:
        print(
            f"{row['date_added']} | {row['status']} | {row['company']} | "
            f"{row['title']} | {row['url']}"
        )


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(
        prog="job-search",
        description="Resume-driven job search automation tools.",
    )
    subparsers = parser.add_subparsers(required=True)

    profile_parser = subparsers.add_parser("profile", help="Build profile from resume.")
    profile_parser.add_argument("resume", help="Path to resume file.")
    profile_parser.set_defaults(func=profile_command)

    score_parser = subparsers.add_parser("score", help="Score a job description.")
    score_parser.add_argument("job", help="Path to a plain-text job description.")
    score_parser.set_defaults(func=score_command)

    add_parser = subparsers.add_parser("add", help="Add an application to the tracker.")
    add_parser.add_argument("company")
    add_parser.add_argument("title")
    add_parser.add_argument("url")
    add_parser.add_argument("--status", default="Interested")
    add_parser.add_argument("--notes", default="")
    add_parser.set_defaults(func=add_command)

    list_parser = subparsers.add_parser("list", help="List tracked applications.")
    list_parser.set_defaults(func=list_command)

    return parser


def main() -> None:
    parser = build_parser()
    args = parser.parse_args()
    args.func(args)
