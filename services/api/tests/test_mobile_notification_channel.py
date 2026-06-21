from pathlib import Path


REPO_ROOT = Path(__file__).resolve().parents[3]
MOBILE_LIB = REPO_ROOT / "apps" / "mobile" / "lib"
ANDROID_MAIN = (
    REPO_ROOT
    / "apps"
    / "mobile"
    / "android"
    / "app"
    / "src"
    / "main"
    / "kotlin"
    / "com"
    / "lanxin"
    / "lanxin_travelmate"
    / "MainActivity.kt"
)
REMINDER_PAGE = MOBILE_LIB / "features" / "reminder" / "reminder_page.dart"
NOTIFICATION_SERVICE = (
    MOBILE_LIB / "features" / "reminder" / "data" / "notification_delivery_service.dart"
)


def test_flutter_notification_delivery_service_uses_platform_channel():
    text = NOTIFICATION_SERVICE.read_text(encoding="utf-8")

    assert "MethodChannel('lanxin_travelmate/notifications')" in text
    assert "Future<bool> showReminder" in text
    assert "showReminderNotification" in text
    assert "title" in text
    assert "body" in text
    assert "lastFailureMessage" in text
    assert "notification_permission_denied" in text


def test_reminder_page_delivers_system_notification_for_reminders():
    text = REMINDER_PAGE.read_text(encoding="utf-8")

    assert "NotificationDeliveryService" in text
    assert "showReminder(" in text
    assert "_notificationStatus" in text
    assert "Icons.notifications_active_rounded" in text
    assert "_notificationDeliveryService.lastFailureMessage" in text


def test_android_main_activity_handles_notification_channel():
    text = ANDROID_MAIN.read_text(encoding="utf-8")

    assert "lanxin_travelmate/notifications" in text
    assert "showReminderNotification" in text
    assert "NotificationChannel" in text
    assert "NotificationCompat.Builder" in text
    assert "POST_NOTIFICATIONS" in text
    assert "notificationPermissionRequestCode" in text
    assert "notification_permission_denied" in text
