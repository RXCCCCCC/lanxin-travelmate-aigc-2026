"""Read-only manifest for final competition submission package slots.

The manifest distinguishes agent-verifiable files from manual competition
artifacts. Manual slots remain acceptable for readiness aggregation, but their
status keeps the required human handoff explicit.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any


AUTHORITATIVE_DOCS = (
    "docs/handoff/submission-checklist.md",
    "docs/handoff/demo-evidence-pack.md",
    "docs/handoff/presentation-outline.md",
    "docs/todo.md",
)

SCORING_NARRATIVE_DOCS = (
    "docs/handoff/presentation-outline.md",
    "docs/handoff/submission-checklist.md",
    "docs/handoff/demo-evidence-pack.md",
    "docs/product/PRD.md",
)

SCORING_NARRATIVE_DIMENSIONS = {
    "innovation": ("创新", "核心创新"),
    "application_value": ("应用价值", "价值"),
    "completion": ("完成度", "当前完成度", "完成"),
    "large_model_usage": ("大模型", "模型 Provider", "Agent"),
    "technical_feasibility": ("技术可行性", "技术架构", "架构"),
    "demo_storyline": ("Demo", "演示路径", "demo-script", "Demo故事线"),
}

ANDROID_APK_CANDIDATES = (
    "apps/mobile/build/app/outputs/flutter-apk/app-release.apk",
    "apps/mobile/build/app/outputs/flutter-apk/app-debug.apk",
)

PRESENTATION_CANDIDATES = (
    "docs/handoff/presentation-outline.md",
    "presentation.pptx",
    "submission/presentation.pptx",
)

DEMO_VIDEO_CANDIDATES = (
    "submission/demo.mp4",
    "docs/handoff/demo-evidence-pack.md",
)

SCREENSHOT_CANDIDATES = (
    "docs/handoff/demo-evidence-pack.md",
    "submission/screenshots",
)

API_EVIDENCE_CANDIDATES = (
    "docs/handoff/demo-evidence-pack.md",
    "docs/handoff/e2e-acceptance.md",
)

PRIVACY_REVIEW_CANDIDATES = (
    "docs/handoff/submission-checklist.md",
    "docs/todo.md",
)

PLATFORM_UPLOAD_CANDIDATES = (
    "docs/handoff/submission-checklist.md",
)


def _relative(path: Path, repo_root: Path) -> str:
    return path.relative_to(repo_root).as_posix()


def _git_available(repo_root: Path) -> bool:
    try:
        result = subprocess.run(
            ["git", "rev-parse", "--is-inside-work-tree"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        return False
    return result.returncode == 0 and result.stdout.strip() == "true"


def _existing_paths(repo_root: Path, candidates: tuple[str, ...]) -> list[str]:
    existing: list[str] = []
    for candidate in candidates:
        path = repo_root / candidate
        if path.exists():
            existing.append(_relative(path, repo_root))
    return existing


def _slot(
    repo_root: Path,
    *,
    candidates: tuple[str, ...],
    manual: bool,
    note: str,
    ok: bool | None = None,
) -> dict[str, Any]:
    existing = _existing_paths(repo_root, candidates)
    return {
        "ok": bool(existing) if ok is None else ok,
        "manual": manual,
        "detail": {
            "existing": existing,
            "expected": list(candidates),
            "note": note,
        },
    }


def _collect_competition_scoring_narrative(repo_root: Path) -> dict[str, Any]:
    docs: dict[str, str] = {}
    for relative_path in SCORING_NARRATIVE_DOCS:
        path = repo_root / relative_path
        if path.exists():
            docs[relative_path] = path.read_text(encoding="utf-8")

    covered: dict[str, dict[str, Any]] = {}
    missing: dict[str, list[str]] = {}
    for dimension, markers in SCORING_NARRATIVE_DIMENSIONS.items():
        matches: dict[str, list[str]] = {}
        for relative_path, text in docs.items():
            found = [marker for marker in markers if marker in text]
            if found:
                matches[relative_path] = found
        if matches:
            covered[dimension] = {"markers": matches}
        else:
            missing[dimension] = list(markers)

    return {
        "covered": sorted(covered),
        "missing": missing,
        "sources": sorted(docs),
        "expectedSources": list(SCORING_NARRATIVE_DOCS),
        "note": (
            "Checks whether submission/PPT materials cover competition judging "
            "narrative dimensions; final slide export and review remain manual."
        ),
    }


def collect_submission_package_manifest(repo_root: Path) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    authoritative_docs = [
        relative_path
        for relative_path in AUTHORITATIVE_DOCS
        if (repo_root / relative_path).exists()
    ]
    docs_complete = len(authoritative_docs) == len(AUTHORITATIVE_DOCS)
    scoring_narrative = _collect_competition_scoring_narrative(repo_root)

    checks: dict[str, dict[str, Any]] = {
        "code_repository": {
            "ok": _git_available(repo_root) and docs_complete,
            "manual": False,
            "detail": {
                "gitWorkTree": _git_available(repo_root),
                "authoritativeDocs": authoritative_docs,
                "missingDocs": [
                    relative_path
                    for relative_path in AUTHORITATIVE_DOCS
                    if relative_path not in authoritative_docs
                ],
            },
        },
        "android_apk": _slot(
            repo_root,
            candidates=ANDROID_APK_CANDIDATES,
            manual=True,
            note="Build artifact must be regenerated and device-checked before final upload.",
        ),
        "presentation_deck": _slot(
            repo_root,
            candidates=PRESENTATION_CANDIDATES,
            manual=True,
            note="Outline is tracked locally; final PPT export remains a manual deliverable.",
        ),
        "demo_video": _slot(
            repo_root,
            candidates=DEMO_VIDEO_CANDIDATES,
            manual=True,
            note="Evidence plan is tracked locally; final video capture/export is manual.",
        ),
        "app_screenshots": _slot(
            repo_root,
            candidates=SCREENSHOT_CANDIDATES,
            manual=True,
            note="Screenshot list is tracked locally; final screenshots require device capture.",
        ),
        "api_evidence": _slot(
            repo_root,
            candidates=API_EVIDENCE_CANDIDATES,
            manual=True,
            note="API evidence is documented locally and should be refreshed with real keys.",
        ),
        "privacy_and_material_review": _slot(
            repo_root,
            candidates=PRIVACY_REVIEW_CANDIDATES,
            manual=True,
            note="Authorization, privacy boundary, and material review require human sign-off.",
        ),
        "platform_upload": _slot(
            repo_root,
            candidates=PLATFORM_UPLOAD_CANDIDATES,
            manual=True,
            note="Competition platform upload is intentionally manual and not automated by Codex.",
        ),
        "competition_scoring_narrative": {
            "ok": not scoring_narrative["missing"],
            "manual": True,
            "detail": scoring_narrative,
        },
    }

    return {
        "repoRoot": str(repo_root),
        "authoritativeDocs": authoritative_docs,
        "checks": checks,
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = collect_submission_package_manifest(Path(args.repo_root))
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Submission package manifest for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")

    if args.strict:
        failed = [
            name
            for name, item in report["checks"].items()
            if not item["ok"] and not item.get("manual")
        ]
        if failed:
            print("Failed checks: " + ", ".join(failed), file=sys.stderr)
            return 1
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
