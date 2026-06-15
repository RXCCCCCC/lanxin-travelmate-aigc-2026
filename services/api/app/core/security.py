from dataclasses import dataclass


@dataclass(frozen=True)
class CurrentUser:
    user_id: str = "guest"
    is_guest: bool = True


def get_current_user() -> CurrentUser:
    return CurrentUser()
