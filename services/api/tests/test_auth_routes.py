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