from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
CHAT_MODELS = REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "chat" / "data" / "agent_chat_models.dart"
CHAT_PAGE = REPO_ROOT / "apps" / "mobile" / "lib" / "features" / "chat" / "chat_page.dart"


def test_memory_candidate_dto_preserves_privacy_fields():
    source = CHAT_MODELS.read_text(encoding="utf-8")

    assert "final String sensitivity;" in source
    assert "final bool requiresExplicitConsent;" in source
    assert "json['sensitivity']" in source
    assert "json['requiresExplicitConsent']" in source


def test_chat_memory_candidate_panel_surfaces_privacy_levels():
    source = CHAT_PAGE.read_text(encoding="utf-8")

    assert "sensitiveCount" in source
    assert "personalCount" in source
    assert ".sensitivity == 'sensitive'" in source
    assert ".requiresExplicitConsent" in source