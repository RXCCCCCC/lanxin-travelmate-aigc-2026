from __future__ import annotations

from pathlib import Path

REPO_ROOT = Path(__file__).resolve().parents[3]
AVATAR_DIR = REPO_ROOT / "apps" / "mobile" / "assets" / "avatars"
SOURCE_AVATAR_DIR = REPO_ROOT / "project" / "img" / "lanxiaoxin"
AVATAR_STATE_SOURCE = (
    REPO_ROOT / "apps" / "mobile" / "lib" / "core" / "constants" / "avatar_states.dart"
)


def _avatar_asset_names() -> list[str]:
    text = AVATAR_STATE_SOURCE.read_text(encoding="utf-8")
    names: list[str] = []
    for line in text.splitlines():
        stripped = line.strip()
        if stripped.startswith("'lanxiaoxin_"):
            names.append(stripped.split("'", maxsplit=2)[1])
    return sorted(set(names))


def test_avatar_state_runtime_assets_match_original_materials():
    offenders: list[str] = []
    for name in _avatar_asset_names():
        runtime_path = AVATAR_DIR / f"{name}.png"
        source_path = SOURCE_AVATAR_DIR / f"{name}.png"
        if not runtime_path.exists():
            offenders.append(f"{runtime_path.relative_to(REPO_ROOT)} missing")
            continue
        if not source_path.exists():
            offenders.append(f"{source_path.relative_to(REPO_ROOT)} missing")
            continue
        if runtime_path.read_bytes() != source_path.read_bytes():
            offenders.append(
                f"{runtime_path.relative_to(REPO_ROOT)} differs from "
                f"{source_path.relative_to(REPO_ROOT)}"
            )

    assert offenders == []
