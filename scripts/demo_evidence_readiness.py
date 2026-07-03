"""Read-only demo evidence readiness report.

This script checks whether the repository contains the handoff material needed
to record and package the competition demo. It does not inspect media content,
start services, read secrets, or modify files.
"""

from __future__ import annotations

import argparse
import json
import sys
from pathlib import Path
from typing import Any


REQUIRED_DOCS = (
    "docs/handoff/demo-script.md",
    "docs/handoff/demo-evidence-pack.md",
    "docs/handoff/presentation-outline.md",
    "docs/handoff/submission-checklist.md",
)

P0_STORYBOARD_MARKERS = {
    "chat_need": ("镜头 1", "聊天提出需求", "memoryCandidates"),
    "memory_confirm": ("镜头 2", "记忆胶囊", "长期记忆"),
    "personalized_plan": ("镜头 3", "个性化规划", "toolTrace"),
    "active_reminder": ("镜头 4", "主动情境提醒", "冷却"),
    "photo_task": ("镜头 5", "旅拍", "盲盒任务"),
    "trip_review": ("镜头 6", "旅行复盘", "route", "highlightPhotos"),
    "audit_fallback": ("镜头 7", "审计", "fallback"),
}

CAPTURE_MARKERS = {
    "app_screens": ("首页", "聊天页", "记忆页", "规划页", "提醒页", "旅拍页", "复盘页"),
    "api_screens": ("/docs", "/api/agent/chat", "/api/audit/model-calls", "/api/audit/tool-calls"),
    "tool_trace": ("fallback=false", "fallback/unconfigured", "provider", "cacheHit"),
    "ppt_flow": ("PPT 页建议", "技术架构", "Demo 画面", "风险与下一步"),
}

PRIVACY_MARKERS = {
    "secret_safety": ("不展示真实密钥", "Token", "密码"),
    "media_privacy": ("未经授权照片", "队友隐私", "私人位置"),
    "manual_confirmation": ("发布前必须由用户确认", "不自动发布"),
    "audit_redaction": ("脱敏", "请求摘要"),
}

REAL_CAPABILITY_MARKERS = {
    "real_provider": ("真实模型", "fallback=false"),
    "amap": ("高德 Key", "真实天气/POI/路线"),
    "android_device": ("Android/vivo", "相册", "相机", "定位", "麦克风", "通知"),
    "submission": ("PPT", "视频", "平台上传"),
}

MANUAL_STATUS_MARKERS = {
    "screenshots": ("需真机或模拟器截图", "需真实用户数据截图"),
    "real_media": ("需真实照片素材截图",),
    "permissions": ("需 Android/vivo 权限截图",),
    "upload": ("团队信息", "PPT", "视频", "平台上传"),
}

MANUAL_ITEMS = (
    "录制真机截图：App 首页、聊天、记忆、规划、提醒、旅拍、复盘。",
    "录制 Demo 视频：按 docs/handoff/demo-script.md 走完整 P0 闭环。",
    "制作 PPT：按 docs/handoff/presentation-outline.md 补队伍信息、截图和视频链接。",
    "负责人确认比赛平台上传、预览结果和最终提交。",
)


def _read_text(path: Path) -> str:
    return path.read_text(encoding="utf-8") if path.exists() else ""


def _missing_marker_groups(text: str, marker_groups: dict[str, tuple[str, ...]]) -> dict[str, list[str]]:
    return {
        name: [marker for marker in markers if marker not in text]
        for name, markers in marker_groups.items()
        if any(marker not in text for marker in markers)
    }


def collect_demo_evidence_readiness(repo_root: Path) -> dict[str, Any]:
    repo_root = repo_root.resolve()
    demo_script = _read_text(repo_root / "docs" / "handoff" / "demo-script.md")
    evidence_pack = _read_text(repo_root / "docs" / "handoff" / "demo-evidence-pack.md")
    presentation = _read_text(repo_root / "docs" / "handoff" / "presentation-outline.md")
    submission = _read_text(repo_root / "docs" / "handoff" / "submission-checklist.md")
    todo = _read_text(repo_root / "docs" / "todo.md")

    required_missing = [
        relative_path
        for relative_path in REQUIRED_DOCS
        if not (repo_root / relative_path).exists()
    ]
    full_text = "\n".join((demo_script, evidence_pack, presentation, submission, todo))

    checks = {
        "required_docs_present": {
            "ok": not required_missing,
            "detail": required_missing,
        },
        "demo_storyboard_covers_p0_loop": {
            "ok": not (missing := _missing_marker_groups(demo_script, P0_STORYBOARD_MARKERS)),
            "detail": missing,
        },
        "capture_manifest_covers_app_and_api": {
            "ok": not (missing := _missing_marker_groups(evidence_pack, CAPTURE_MARKERS)),
            "detail": missing,
        },
        "privacy_review_markers_present": {
            "ok": not (missing := _missing_marker_groups(full_text, PRIVACY_MARKERS)),
            "detail": missing,
        },
        "real_capability_markers_present": {
            "ok": not (missing := _missing_marker_groups(full_text, REAL_CAPABILITY_MARKERS)),
            "detail": missing,
        },
        "manual_capture_status_explicit": {
            "ok": not (missing := _missing_marker_groups(full_text, MANUAL_STATUS_MARKERS)),
            "detail": missing,
        },
        "artifact_placeholders_present": {
            "ok": True,
            "manual": True,
            "detail": list(MANUAL_ITEMS),
        },
    }

    return {
        "repoRoot": str(repo_root),
        "checks": checks,
        "manualItems": list(MANUAL_ITEMS),
        "ok": all(item["ok"] or item.get("manual") for item in checks.values()),
    }


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--repo-root", default=Path(__file__).resolve().parents[1])
    parser.add_argument("--strict", action="store_true")
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    report = collect_demo_evidence_readiness(Path(args.repo_root))
    if args.json:
        print(json.dumps(report, ensure_ascii=False, indent=2))
    else:
        print(f"Demo evidence readiness for {report['repoRoot']}")
        for name, item in report["checks"].items():
            status = "OK" if item["ok"] else ("MANUAL" if item.get("manual") else "FAIL")
            print(f"[{status}] {name}: {item['detail']}")
        print("Manual items:")
        for item in report["manualItems"]:
            print(f"- {item}")

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
