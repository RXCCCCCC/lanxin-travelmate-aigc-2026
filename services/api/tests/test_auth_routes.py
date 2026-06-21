import base64
import hmac
import json
from time import time
from uuid import uuid4

from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_guest_auth_creates_persistent_user_and_token():
    response = client.post("/api/auth/guest", json={"deviceId": "device-a", "displayName": "测试游客"})

    assert response.status_code == 200
    payload = response.json()
    assert payload["userId"] == "guest-device-a"
    assert payload["isGuest"] is True
    assert payload["accessToken"]

    me = client.get("/api/users/me", headers={"Authorization": f"Bearer {payload['accessToken']}"})
    assert me.status_code == 200
    assert me.json()["displayName"] == "测试游客"
    assert me.json()["isGuest"] is True


def test_register_login_and_me_flow():
    account = "tester-auth@example.com"
    register = client.post(
        "/api/auth/register",
        json={"account": account, "password": "secret123", "displayName": "认证用户"},
    )

    if register.status_code == 409:
        login = client.post("/api/auth/login", json={"account": account, "password": "secret123"})
        assert login.status_code == 200
        payload = login.json()
    else:
        assert register.status_code == 200
        payload = register.json()

    assert payload["isGuest"] is False
    assert payload["accessToken"]

    me = client.get("/api/users/me", headers={"Authorization": f"Bearer {payload['accessToken']}"})
    assert me.status_code == 200
    assert me.json()["displayName"] == "认证用户"
    assert me.json()["authMode"] == "password"


def test_login_rejects_wrong_password():
    account = "tester-auth-wrong@example.com"
    client.post(
        "/api/auth/register",
        json={"account": account, "password": "secret123", "displayName": "认证用户"},
    )

    response = client.post("/api/auth/login", json={"account": account, "password": "bad-password"})

    assert response.status_code == 401


def _decode_b64url_json(segment: str) -> dict[str, object]:
    padding = "=" * (-len(segment) % 4)
    return json.loads(base64.urlsafe_b64decode((segment + padding).encode("ascii")))


def test_auth_tokens_are_signed_jwt_payloads():
    response = client.post("/api/auth/guest", json={"deviceId": "jwt-device", "displayName": "JWT游客"})

    assert response.status_code == 200
    token = response.json()["accessToken"]
    header_text, payload_text, signature = token.split(".")

    header = _decode_b64url_json(header_text)
    payload = _decode_b64url_json(payload_text)

    assert signature
    assert header == {"alg": "HS256", "typ": "JWT"}
    assert payload["sub"] == "guest-jwt-device"
    assert payload["isGuest"] is True
    assert isinstance(payload["iat"], int)
    assert isinstance(payload["exp"], int)
    assert payload["exp"] > payload["iat"]


def test_tampered_jwt_is_rejected():
    response = client.post("/api/auth/guest", json={"deviceId": "tamper-device"})
    token = response.json()["accessToken"]
    header_text, payload_text, signature = token.split(".")
    tampered = f"{header_text}.{payload_text[:-1]}x.{signature}"

    me = client.get("/api/users/me", headers={"Authorization": f"Bearer {tampered}"})

    assert me.status_code == 401


def test_legacy_access_token_remains_accepted_for_existing_sessions():
    user_id = "guest-legacy-device"
    expires_at = int(time() + 600)
    payload = f"{user_id}:1:{expires_at}"
    signature = hmac.new(b"lanxin-local-dev-secret", payload.encode("utf-8"), "sha256").hexdigest()
    legacy_token = f"{payload}:{signature}"
    client.post("/api/auth/guest", json={"deviceId": "legacy-device", "displayName": "旧会话游客"})

    me = client.get("/api/users/me", headers={"Authorization": f"Bearer {legacy_token}"})

    assert me.status_code == 200
    assert me.json()["userId"] == user_id
    assert me.json()["isGuest"] is True


def test_guest_can_upgrade_to_password_account_without_losing_owned_data():
    suffix = uuid4().hex
    guest = client.post(
        "/api/auth/guest",
        json={"deviceId": f"upgrade-device-{suffix}", "displayName": "Guest Upgrade"},
    )
    assert guest.status_code == 200
    guest_payload = guest.json()
    guest_user_id = guest_payload["userId"]

    memory = client.post(
        "/api/memory/capsules",
        json={
            "id": f"mem-upgrade-device-{suffix}",
            "userId": guest_user_id,
            "title": "Night view",
            "content": "Keep night-view spots in plans.",
            "scope": "longTerm",
        },
    )
    assert memory.status_code == 200
    trip = client.post(
        "/api/trip/plan",
        json={
            "userId": guest_user_id,
            "tripId": f"trip-upgrade-device-{suffix}",
            "destination": "Chongqing",
            "message": "Plan two relaxed days.",
        },
    )
    assert trip.status_code == 200

    upgraded = client.post(
        "/api/auth/upgrade-guest",
        headers={"Authorization": f"Bearer {guest_payload['accessToken']}"},
        json={
            "account": f"upgrade-device-{suffix}@example.com",
            "password": "secret123",
            "displayName": "Upgraded User",
        },
    )

    assert upgraded.status_code == 200
    upgraded_payload = upgraded.json()
    assert upgraded_payload["userId"] == guest_user_id
    assert upgraded_payload["isGuest"] is False
    assert upgraded_payload["authMode"] == "password"
    assert upgraded_payload["migrationSummary"]["memories"] >= 1
    assert upgraded_payload["migrationSummary"]["trips"] >= 1

    me = client.get(
        "/api/users/me",
        headers={"Authorization": f"Bearer {upgraded_payload['accessToken']}"},
    )
    assert me.status_code == 200
    assert me.json()["isGuest"] is False
    assert me.json()["authMode"] == "password"

    login = client.post(
        "/api/auth/login",
        json={"account": f"upgrade-device-{suffix}@example.com", "password": "secret123"},
    )
    assert login.status_code == 200
    assert login.json()["userId"] == guest_user_id

    memories = client.get("/api/memory/capsules", params={"userId": guest_user_id})
    current_trip = client.get("/api/trip/current", params={"userId": guest_user_id})
    assert any(item["id"] == f"mem-upgrade-device-{suffix}" for item in memories.json()["items"])
    assert current_trip.json()["tripId"] == f"trip-upgrade-device-{suffix}"
