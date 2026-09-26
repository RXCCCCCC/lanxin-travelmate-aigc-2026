from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_privacy_summary_exposes_permissions_memory_rules_and_sensitivity_levels():
    response = client.get("/api/privacy/summary")

    assert response.status_code == 200
    payload = response.json()
    assert payload["version"]
    assert {item["permission"] for item in payload["permissions"]} >= {
        "location",
        "photos",
        "camera",
        "microphone",
        "notifications",
    }
    assert any(rule["scope"] == "longTerm" for rule in payload["memoryRules"])
    assert any(rule["scope"] == "currentTrip" for rule in payload["memoryRules"])
    sensitivity = {item["level"] for item in payload["sensitivityLevels"]}
    assert {"normal", "personal", "sensitive"}.issubset(sensitivity)
    assert payload["userControls"]["canExportData"] is True
    assert payload["userControls"]["canDeleteAllMemories"] is True