from pathlib import Path

import yaml


def test_mobile_sqlite3_uses_system_native_asset_source() -> None:
    repo_root = Path(__file__).resolve().parents[3]
    pubspec = yaml.safe_load((repo_root / "apps" / "mobile" / "pubspec.yaml").read_text(encoding="utf-8"))

    sqlite3_defines = pubspec.get("hooks", {}).get("user_defines", {}).get("sqlite3", {})

    assert sqlite3_defines.get("source") == "system"
