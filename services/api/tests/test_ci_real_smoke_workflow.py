from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]


def test_ci_has_optional_real_provider_smoke_without_secret_echoes():
    workflow = (REPO_ROOT / ".github" / "workflows" / "ci.yml").read_text(encoding="utf-8")
    script = (REPO_ROOT / "services" / "api" / "scripts" / "real_provider_smoke.py").read_text(encoding="utf-8")

    assert "Real provider smoke" in workflow
    assert "LANXIN_AMAP_API_KEY" in workflow
    assert "LANXIN_LANXIN_API_KEY" in workflow or "LANXIN_OPENAI_API_KEY" in workflow
    assert "if:" in workflow and "secrets." in workflow
    assert "uv run python scripts/real_provider_smoke.py" in workflow

    forbidden_prints = [
        "lanxin_api_key)",
        "openai_api_key)",
        "amap_api_key)",
        "os.environ",
    ]
    for token in forbidden_prints:
        assert token not in script
    assert "[REDACTED]" in script