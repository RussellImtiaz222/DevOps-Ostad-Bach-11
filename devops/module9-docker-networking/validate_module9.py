from pathlib import Path
import re
import sys


MODULE_DIR = Path(__file__).resolve().parent
README = MODULE_DIR / "README.md"
SCREENSHOTS_DIR = MODULE_DIR / "screenshots"

REQUIRED_SCREENSHOTS = [
    "01-ec2-instance.png",
    "02-docker-version.png",
    "03-user-docker-group.png",
    "04-hello-world.png",
    "05-bridge-network.png",
    "06-host-network.png",
    "07-none-network.png",
    "08-custom-bridge-network.png",
]

PLACEHOLDER_PATTERNS = [
    re.compile(r"<[A-Z0-9_]+(?:\.[a-z0-9]+)?>"),
    re.compile(r"\b(?:TODO|TBD|REPLACE_ME)\b", re.IGNORECASE),
]


def find_placeholder_tokens(readme_text):
    tokens = set()
    for pattern in PLACEHOLDER_PATTERNS:
        tokens.update(match.group(0) for match in pattern.finditer(readme_text))
    return sorted(tokens)


def main():
    failures = []

    missing_screenshots = [
        filename
        for filename in REQUIRED_SCREENSHOTS
        if not (SCREENSHOTS_DIR / filename).is_file()
    ]
    if missing_screenshots:
        failures.append(
            "Missing required screenshots:\n"
            + "\n".join(f"  - screenshots/{filename}" for filename in missing_screenshots)
        )

    readme_text = README.read_text(encoding="utf-8")
    placeholder_tokens = find_placeholder_tokens(readme_text)
    if placeholder_tokens:
        failures.append(
            "README.md still contains placeholder tokens:\n"
            + "\n".join(f"  - {token}" for token in placeholder_tokens)
        )

    if failures:
        print("Module 9 validation failed:\n")
        print("\n\n".join(failures))
        return 1

    print("Module 9 validation passed.")
    return 0


if __name__ == "__main__":
    sys.exit(main())
