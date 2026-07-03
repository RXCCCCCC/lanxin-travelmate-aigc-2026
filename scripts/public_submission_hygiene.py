"""Read-only hygiene checks for public competition submission materials.

The checks are intentionally conservative: they do not read local `.env`
secret files, do not inspect binary screenshots/videos, and only flag obvious
secret/token shapes in tracked public text materials.
"""

from __future__ import annotations

import argparse
import json
import re
import subprocess
import sys
from pathlib import Path
from typing import Any


PUBLIC_MATERIALS = (
    "README.md",
    "docs/handoff/submission-checklist.md",
    "docs/handoff/demo-evidence-pack.md",
    "docs/handoff/presentation-outline.md",
    "docs/handoff/config-implementation-checklist.md",
    "docs/handoff/e2e-acceptance.md",
    "docs/engineering/privacy-and-compliance.md",
)

REQUIRED_GITIGNORE_PATTERNS = (
    ".env",
    ".env.local",
    ".env.*.local",
    "*.log",
)

SECRET_NAME_MARKERS = (
    "API_KEY",
    "TOKEN",
    "SECRET",
    "PASSWORD",
)

PLACEHOLDER_VALUES = {
    "",
    "mock",
    "lanxin",
    "openai",
    "gpt-4o-mini",
    "change-me-in-production",
    "sqlite:///./lanxin_travelmate.db",
    "https://restapi.amap.com",
    "20",
    "8",
    "0",
    "2592000",
}

SECRET_PATTERNS = (
    re.compile(r"\bsk-[A-Za-z0-9_-]{20,}\b"),
    re.compile(r"\bgh[pousr]_[A-Za-z0-9_]{20,}\b"),
    re.compile(r"\bAKIA[0-9A-Z]{16}\b"),
    re.compile(r"\bxox[baprs]-[A-Za-z0-9-]{20,}\b"),
    re.compile(r"(?i)\bBearer\s+[A-Za-z0-9._~+/=-]{20,}"),
)


def _run_git_ls_files(repo_root: Path) -> list[str]:
    try:
        result = subprocess.run(
            ["git", "ls-files"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        return []
    if result.returncode != 0:
        return []
    return [line.strip().replace("\\", "/") for line in result.stdout.splitlines() if line.strip()]


def _read_text(path: Path) -> str:
    try:
        return path.read_text(encoding="utf-8")
    except UnicodeDecodeError:
        return path.read_text(encoding="utf-8", errors="ignore")


def _check_env_example_placeholders(repo_root: Path) -> dict[str, Any]:
    env_example = repo_root / "services" / "api" / ".env.example"
    offenders: list[str] = []
    if not env_example.exists():
        return {"ok": False, "detail": ["services/api/.env.example missing"]}

    for raw_line in _read_text(env_example).splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue
        key, value = line.split("=", maxsplit=1)
        if any(marker in key.upper() for marker in SECRET_NAME_MARKERS):
            normalized = value.strip().strip('"').strip("'")
            if normalized not in PLACEHOLDER_VALUES:
                offenders.append(key)

    return {
        "ok": not offenders,
        "detail": offenders,
    }


def _scan_secret_markers(repo_root: Path, relative_paths: list[str]) -> dict[str, Any]:
    offenders: list[dict[str, Any]] = []
    for relative_path in relative_paths:
        path = repo_root / relative_path
        if not path.exists() or not path.is_file():
            continue
        text = _read_text(path)
        for line_number, line in enumerate(text.splitlines(), start=1):
            for pattern in SECRET_PATTERNS:
                if pattern.search(line):
                    offenders.append(
                        {
                            "path": relative_path,
                            "line": line_number,
                            "pattern": pattern.pattern,
                        }
                    )

    return {
        "ok": not offenders,
        "detail": offenders,
    }


def collect_public_submission_hygiene(repo_root: Path) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    tracked_files = _run_git_ls_files(repo_root)
    tracked_set = set(tracked_files)
    public_materials = [
        relative_path for relative_path in PUBLIC_MATERIALS if (repo_root / relative_path).exists()
    ]

    tracked_env_files = [
        path
        for path in tracked_files
        if path.endswith(".env")
        or "/.env" in path
        or path.endswith(".env.local")
        or path.endswith(".env.production")
    ]
    tracked_env_files = [
        path for path in tracked_env_files if not path.endswith(".env.example")
    ]

    gitignore_text = _read_text(repo_root / ".gitignore") if (repo_root / ".gitignore").exists() else ""
    missing_gitignore_patterns = [
        pattern for pattern in REQUIRED_GITIGNORE_PATTERNS if pattern not in gitignore_text
    ]

    privacy_sources = "\n".join(
        _read_text(repo_root / relative_path)
        for relative_path in public_materials
    )
    privacy_markers = ("Key", "Token", "隐私", "privacy", "授权", "Demo")
    missing_privacy_markers = [
        marker for marker in privacy_markers if marker not in privacy_sources
    ]

    checks: dict[str, dict[str, Any]] = {
        "env_files_not_tracked": {
            "ok": not tracked_env_files,
            "detail": tracked_env_files,
        },
        "gitignore_blocks_local_secrets": {
            "ok": not missing_gitignore_patterns,
            "detail": missing_gitignore_patterns,
        },
        "env_example_uses_placeholders": _check_env_example_placeholders(repo_root),
        "tracked_text_has_no_secret_markers": _scan_secret_markers(
            repo_root,
            public_materials,
        ),
        "public_material_privacy_reviewed": {
            "ok": not missing_privacy_markers and set(PUBLIC_MATERIALS[:4]).issubset(tracked_set),
            "detail": {
                "scanned": public_materials,
                "missingMarkers": missing_privacy_markers,
            },
        },
    }

    return {
        "repoRoot": str(repo_root),
        "scannedPublicMaterials": public_materials,
        "checks": checks,
        "ok": all(item["ok"] for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = collect_public_submission_hygiene(Path(args.repo_root))
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Public submission hygiene for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else "FAIL"
            print(f"[{status}] {name}: {item['detail']}")

    if args.strict and not report["ok"]:
        failed = [name for name, item in report["checks"].items() if not item["ok"]]
        print("Failed checks: " + ", ".join(failed), file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
