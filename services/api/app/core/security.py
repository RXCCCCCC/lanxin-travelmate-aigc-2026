from __future__ import annotations

import base64
from dataclasses import dataclass
from hashlib import pbkdf2_hmac
import hmac
import json
import secrets
from time import time
from typing import Any

from fastapi import Header, HTTPException

from app.core.config import get_settings

LEGACY_TOKEN_SECRET = "lanxin-local-dev-secret"


@dataclass(frozen=True)
class CurrentUser:
    user_id: str = "guest"
    is_guest: bool = True


def resolve_effective_user_id(explicit_user_id: str | None, current_user: CurrentUser) -> str:
    requested_user_id = (explicit_user_id or "").strip()
    if current_user.user_id != "guest" and (not requested_user_id or requested_user_id == "guest"):
        return current_user.user_id
    return requested_user_id or "guest"


def hash_password(password: str, salt: str | None = None) -> str:
    salt = salt or secrets.token_hex(16)
    digest = pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000).hex()
    return f"pbkdf2_sha256${salt}${digest}"


def verify_password(password: str, password_hash: str) -> bool:
    try:
        algorithm, salt, expected = password_hash.split("$", 2)
    except ValueError:
        return False
    if algorithm != "pbkdf2_sha256":
        return False
    actual = pbkdf2_hmac("sha256", password.encode("utf-8"), salt.encode("utf-8"), 120_000).hex()
    return hmac.compare_digest(actual, expected)


def _b64url_encode(data: bytes) -> str:
    return base64.urlsafe_b64encode(data).decode("ascii").rstrip("=")


def _b64url_decode(data: str) -> bytes:
    padding = "=" * (-len(data) % 4)
    return base64.urlsafe_b64decode((data + padding).encode("ascii"))


def _json_b64url(data: dict[str, Any]) -> str:
    return _b64url_encode(json.dumps(data, separators=(",", ":"), ensure_ascii=False).encode("utf-8"))


def _sign(message: str, secret: str) -> str:
    digest = hmac.new(secret.encode("utf-8"), message.encode("ascii"), "sha256").digest()
    return _b64url_encode(digest)


def create_access_token(user_id: str, *, is_guest: bool = False) -> str:
    settings = get_settings()
    now = int(time())
    header = {"alg": "HS256", "typ": "JWT"}
    payload = {
        "sub": user_id,
        "isGuest": is_guest,
        "iat": now,
        "exp": now + int(settings.auth_token_ttl_seconds),
    }
    signing_input = f"{_json_b64url(header)}.{_json_b64url(payload)}"
    signature = _sign(signing_input, settings.auth_token_secret)
    return f"{signing_input}.{signature}"


def _parse_jwt_access_token(token: str) -> CurrentUser:
    try:
        header_text, payload_text, signature = token.split(".", 2)
        signing_input = f"{header_text}.{payload_text}"
        expected = _sign(signing_input, get_settings().auth_token_secret)
        if not hmac.compare_digest(signature, expected):
            raise ValueError("bad signature")
        header = json.loads(_b64url_decode(header_text))
        payload = json.loads(_b64url_decode(payload_text))
        if header.get("alg") != "HS256" or header.get("typ") != "JWT":
            raise ValueError("unsupported token header")
        user_id = str(payload.get("sub") or "").strip()
        if not user_id:
            raise ValueError("missing subject")
        if int(payload.get("exp") or 0) < int(time()):
            raise ValueError("expired")
    except (ValueError, TypeError, json.JSONDecodeError) as exc:
        raise HTTPException(status_code=401, detail="Invalid access token") from exc
    return CurrentUser(user_id=user_id, is_guest=bool(payload.get("isGuest")))


def _parse_legacy_access_token(token: str) -> CurrentUser:
    try:
        user_id, guest_flag, expires_at_text, signature = token.split(":", 3)
        payload = f"{user_id}:{guest_flag}:{expires_at_text}"
        expected = hmac.new(LEGACY_TOKEN_SECRET.encode("utf-8"), payload.encode("utf-8"), "sha256").hexdigest()
        if not hmac.compare_digest(signature, expected):
            raise ValueError("bad signature")
        if int(expires_at_text) < int(time()):
            raise ValueError("expired")
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Invalid access token") from exc
    return CurrentUser(user_id=user_id, is_guest=guest_flag == "1")


def parse_access_token(token: str) -> CurrentUser:
    if token.count(".") == 2:
        return _parse_jwt_access_token(token)
    return _parse_legacy_access_token(token)


def get_current_user(authorization: str | None = Header(default=None)) -> CurrentUser:
    if not authorization:
        return CurrentUser()
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    return parse_access_token(token)
