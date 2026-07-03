from __future__ import annotations

from pathlib import Path

from PIL import Image


REPO_ROOT = Path(__file__).resolve().parents[3]
AVATAR_DIR = REPO_ROOT / "apps" / "mobile" / "assets" / "avatars"
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


def test_avatar_state_runtime_assets_are_transparent_pngs():
    offenders: list[str] = []
    for name in _avatar_asset_names():
        path = AVATAR_DIR / f"{name}.png"
        if not path.exists():
            offenders.append(f"{path.relative_to(REPO_ROOT)} missing")
            continue

        image = Image.open(path).convert("RGBA")
        alpha = image.getchannel("A")
        has_transparency = alpha.getextrema()[0] == 0
        if not has_transparency:
            offenders.append(f"{path.relative_to(REPO_ROOT)} has no transparent pixels")

    assert offenders == []
