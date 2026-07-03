"""Read-only final submission readiness report.

This script aggregates local checks that are useful before packaging the
competition submission. It does not start services, build APKs, read secret
values, or modify files.
"""

from __future__ import annotations

import argparse
import json
import subprocess
import sys
from pathlib import Path
from typing import Any
from PIL import Image

SCRIPT_DIR = Path(__file__).resolve().parent
if str(SCRIPT_DIR) not in sys.path:
    sys.path.insert(0, str(SCRIPT_DIR))

from android_release_preflight import collect_android_release_preflight
from android_device_readiness_report import collect_android_device_readiness
from demo_evidence_readiness import collect_demo_evidence_readiness
from docker_compose_preflight import collect_docker_compose_preflight
from public_submission_hygiene import collect_public_submission_hygiene
from submission_package_manifest import collect_submission_package_manifest


REQUIRED_HANDOFF_DOCS = (
    "docs/handoff/demo-script.md",
    "docs/handoff/demo-evidence-pack.md",
    "docs/handoff/presentation-outline.md",
    "docs/handoff/submission-checklist.md",
    "docs/handoff/e2e-acceptance.md",
    "docs/handoff/config-implementation-checklist.md",
)

ANDROID_ONLY_FORBIDDEN_DIRS = (
    "apps/mobile/ios",
    "apps/mobile/macos",
    "apps/mobile/windows",
    "apps/mobile/linux",
    "apps/mobile/web",
)

PRD_P0_DEMO_MARKERS = {
    "chat_need_to_memory_candidates": ("聊天需求", "memoryCandidates"),
    "confirmed_memory": ("记忆胶囊", "显式确认"),
    "personalized_plan": ("个性化规划", "toolTrace"),
    "active_reminder": ("主动", "提醒"),
    "photo_blind_box": ("旅拍", "盲盒任务"),
    "trip_review": ("route", "highlightPhotos", "completedTasks", "newMemories", "nextTripSuggestions"),
    "transparent_fallback": ("fallback/unconfigured", "不伪装"),
}

COMPETITION_SUBMISSION_MARKERS = {
    "planning_document": ("作品策划文档", "PPT"),
    "team_intro": ("团队介绍",),
    "prototype_or_app": ("完整APP应用", "可运行版本"),
    "large_model_api": ("大模型API调用", "fallback=false"),
    "demo_video": ("演示视频",),
    "poster_or_assets": ("宣传海报", "素材授权"),
    "platform_upload": ("平台上传", "最终提交"),
}

README_RUNNABLE_MARKERS = {
    "root_backend": ("uv run uvicorn", "/api/health", "/docs"),
    "root_mobile": ("flutter run", "API_BASE_URL", "flutter build apk --debug"),
    "root_validation": (
        "uv run pytest",
        "flutter analyze",
        "submission_readiness_report.py --json",
    ),
    "mobile_android": ("Android", "flutter run", "API_BASE_URL"),
    "mobile_validation": ("flutter analyze", "flutter test", "flutter build apk --debug"),
    "mobile_device_channels": (
        "photo_picker",
        "location",
        "voice",
        "notifications",
    ),
}

MANUAL_BLOCKERS = (
    "人工验收五类真实模型效果质量，并确认最终演示数据库 fallback=false",
    "确认高德/地图天气数据展示授权和计费额度",
    "完成 vivo/Android 真机相册、相机、定位、麦克风、TTS、通知权限验收",
    "确认最终 applicationId/versionCode/versionName 并配置 release 正式签名",
    "如需公网演示，配置服务器、HTTPS、环境变量和数据库备份策略",
    "确认蓝小心素材授权、真实 Demo 数据隐私边界、PPT、视频和比赛平台上传",
)


def _run_git_status(repo_root: Path) -> dict[str, Any]:
    try:
        result = subprocess.run(
            ["git", "status", "--short"],
            cwd=repo_root,
            capture_output=True,
            text=True,
            check=False,
        )
    except FileNotFoundError:
        return {
            "ok": False,
            "detail": "git executable not found",
        }

    output = result.stdout.strip()
    return {
        "ok": result.returncode == 0 and output == "",
        "detail": output.splitlines() if output else [],
    }


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _missing_marker_groups(text: str, marker_groups: dict[str, tuple[str, ...]]) -> dict[str, list[str]]:
    return {
        name: [marker for marker in markers if marker not in text]
        for name, markers in marker_groups.items()
        if any(marker not in text for marker in markers)
    }


def _collect_avatar_asset_readiness(repo_root: Path) -> dict[str, Any]:
    avatar_source = (
        repo_root / "apps" / "mobile" / "lib" / "core" / "constants" / "avatar_states.dart"
    )
    avatar_dir = repo_root / "apps" / "mobile" / "assets" / "avatars"
    source_text = _read_text(avatar_source)
    asset_names = sorted(
        {
            stripped.split("'", maxsplit=2)[1]
            for line in source_text.splitlines()
            if (stripped := line.strip()).startswith("'lanxiaoxin_")
        }
    )
    offenders: list[str] = []
    for name in asset_names:
        path = avatar_dir / f"{name}.png"
        if not path.exists():
            offenders.append(f"{path.relative_to(repo_root)} missing")
            continue
        try:
            alpha = Image.open(path).convert("RGBA").getchannel("A")
        except OSError as exc:
            offenders.append(f"{path.relative_to(repo_root)} unreadable: {exc}")
            continue
        if alpha.getextrema()[0] != 0:
            offenders.append(f"{path.relative_to(repo_root)} has no transparent pixels")

    return {
        "ok": bool(asset_names) and not offenders,
        "detail": {
            "checked": [f"assets/avatars/{name}.png" for name in asset_names],
            "offenders": offenders,
        },
    }


def collect_submission_readiness(
    repo_root: Path,
    *,
    run_git: bool = True,
    run_docker_config: bool = False,
) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    android_report = collect_android_release_preflight(repo_root)
    android_device_report = collect_android_device_readiness(repo_root)
    docker_report = collect_docker_compose_preflight(
        repo_root,
        run_docker_config=run_docker_config,
    )
    avatar_asset_report = _collect_avatar_asset_readiness(repo_root)
    demo_evidence_report = collect_demo_evidence_readiness(repo_root)
    submission_package_report = collect_submission_package_manifest(repo_root)
    public_hygiene_report = collect_public_submission_hygiene(repo_root)

    todo_text = _read_text(repo_root / "docs" / "todo.md")
    shared_state_text = _read_text(repo_root / "docs" / "handoff" / "ai-shared-state.md")
    checklist_text = _read_text(repo_root / "docs" / "handoff" / "submission-checklist.md")
    demo_text = _read_text(repo_root / "docs" / "handoff" / "demo-script.md")
    evidence_text = _read_text(repo_root / "docs" / "handoff" / "demo-evidence-pack.md")
    presentation_text = _read_text(repo_root / "docs" / "handoff" / "presentation-outline.md")
    competition_text = _read_text(repo_root / "docs" / "product" / "材料中有用的信息.md")
    root_readme_text = _read_text(repo_root / "README.md")
    mobile_readme_text = _read_text(repo_root / "apps" / "mobile" / "README.md")
    git_status = _run_git_status(repo_root) if run_git else {"ok": True, "detail": "skipped"}

    docs_missing = [
        relative_path
        for relative_path in REQUIRED_HANDOFF_DOCS
        if not (repo_root / relative_path).exists()
    ]
    forbidden_platforms = [
        relative_path
        for relative_path in ANDROID_ONLY_FORBIDDEN_DIRS
        if (repo_root / relative_path).exists()
    ]
    p0_demo_missing = _missing_marker_groups(
        "\n".join((demo_text, evidence_text, presentation_text)),
        PRD_P0_DEMO_MARKERS,
    )
    competition_missing = _missing_marker_groups(
        "\n".join((competition_text, checklist_text, todo_text, presentation_text)),
        COMPETITION_SUBMISSION_MARKERS,
    )
    readme_missing = _missing_marker_groups(
        "\n".join((root_readme_text, mobile_readme_text)),
        README_RUNNABLE_MARKERS,
    )

    checks = {
        "git_status_clean": git_status,
        "android_only_platform_shell": {
            "ok": not forbidden_platforms,
            "detail": forbidden_platforms,
        },
        "handoff_docs_present": {
            "ok": not docs_missing,
            "detail": docs_missing,
        },
        "todo_keeps_manual_scope": {
            "ok": "Mock/固定样例只允许作为异常降级，不计入完成验收" in todo_text
            and "涉及账号密钥、真机权限、正式签名、素材授权" in todo_text,
            "detail": "docs/todo.md",
        },
        "shared_state_has_current_next_step": {
            "ok": "当前阶段" in shared_state_text and "下一步" in shared_state_text,
            "detail": "docs/handoff/ai-shared-state.md",
        },
        "submission_checklist_covers_real_capabilities": {
            "ok": "真实能力配置" in checklist_text
            and "Android/vivo 验收" in checklist_text
            and "Demo 素材" in checklist_text,
            "detail": "docs/handoff/submission-checklist.md",
        },
        "readme_runnable_handoff": {
            "ok": not readme_missing,
            "detail": readme_missing,
        },
        "prd_p0_demo_loop_covered": {
            "ok": not p0_demo_missing,
            "detail": p0_demo_missing,
        },
        "competition_submission_materials_covered": {
            "ok": not competition_missing,
            "detail": competition_missing,
        },
        "demo_evidence_readiness": {
            "ok": demo_evidence_report["ok"],
            "detail": demo_evidence_report["checks"],
            "manual": True,
        },
        "submission_package_manifest": {
            "ok": submission_package_report["ok"],
            "detail": submission_package_report["checks"],
            "manual": True,
        },
        "public_submission_hygiene": {
            "ok": public_hygiene_report["ok"],
            "detail": public_hygiene_report["checks"],
            "manual": True,
        },
        "avatar_assets_transparent": avatar_asset_report,
        "android_release_preflight": {
            "ok": android_report["ok"],
            "detail": android_report["checks"],
        },
        "android_device_readiness": {
            "ok": android_device_report["ok"],
            "detail": android_device_report["checks"],
            "manual": True,
        },
        "docker_compose_preflight": {
            "ok": docker_report["ok"],
            "detail": docker_report["checks"],
        },
    }

    return {
        "repoRoot": str(repo_root),
        "checks": checks,
        "manualBlockers": list(MANUAL_BLOCKERS),
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    parser.add_argument(
        "--run-docker-config",
        action="store_true",
        help="Also run `docker compose config`; still does not start containers.",
    )
    parser.add_argument("--skip-git", action="store_true")
    args = parser.parse_args()

    report = collect_submission_readiness(
        Path(args.repo_root),
        run_git=not args.skip_git,
        run_docker_config=args.run_docker_config,
    )
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Submission readiness for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")
        print("Manual blockers:")
        for blocker in report["manualBlockers"]:
            print(f"- {blocker}")

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
