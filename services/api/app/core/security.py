from dataclasses import dataclass
from hashlib import pbkdf2_hmac
import hmac
import secrets
from time import time

from fastapi import Header, HTTPException

TOKEN_SECRET = "lanxin-local-dev-secret"
TOKEN_TTL_SECONDS = 60 * 60 * 24 * 30


@dataclass(frozen=True)
class CurrentUser:
    user_id: str = "guest"
    is_guest: bool = True


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


def create_access_token(user_id: str, *, is_guest: bool = False) -> str:
    expires_at = int(time() + TOKEN_TTL_SECONDS)
    guest_flag = "1" if is_guest else "0"
    payload = f"{user_id}:{guest_flag}:{expires_at}"
    signature = hmac.new(TOKEN_SECRET.encode("utf-8"), payload.encode("utf-8"), "sha256").hexdigest()
    return f"{payload}:{signature}"


def parse_access_token(token: str) -> CurrentUser:
    try:
        user_id, guest_flag, expires_at_text, signature = token.split(":", 3)
        payload = f"{user_id}:{guest_flag}:{expires_at_text}"
        expected = hmac.new(TOKEN_SECRET.encode("utf-8"), payload.encode("utf-8"), "sha256").hexdigest()
        if not hmac.compare_digest(signature, expected):
            raise ValueError("bad signature")
        if int(expires_at_text) < int(time()):
            raise ValueError("expired")
    except ValueError as exc:
        raise HTTPException(status_code=401, detail="Invalid access token") from exc
    return CurrentUser(user_id=user_id, is_guest=guest_flag == "1")


def get_current_user(authorization: str | None = Header(default=None)) -> CurrentUser:
    if not authorization:
        return CurrentUser()
    scheme, _, token = authorization.partition(" ")
    if scheme.lower() != "bearer" or not token:
        raise HTTPException(status_code=401, detail="Invalid authorization header")
    return parse_access_token(token)