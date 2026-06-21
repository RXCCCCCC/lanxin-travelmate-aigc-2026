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
CHAT_PAGE = MOBILE_LIB / "features" / "chat" / "chat_page.dart"
VOICE_SERVICE = MOBILE_LIB / "features" / "chat" / "data" / "voice_interaction_service.dart"


def test_flutter_voice_interaction_service_uses_platform_channel():
    text = VOICE_SERVICE.read_text(encoding="utf-8")

    assert "MethodChannel('lanxin_travelmate/voice')" in text
    assert "Future<String?> listenOnce()" in text
    assert "Future<bool> speak(String text)" in text
    assert "startVoiceInput" in text
    assert "speakText" in text
    assert "lastFailureMessage" in text
    assert "microphone_permission_denied" in text
    assert "voice_unavailable" in text
    assert "tts_unavailable" in text


def test_chat_page_exposes_voice_input_and_reply_speech():
    text = CHAT_PAGE.read_text(encoding="utf-8")

    assert "VoiceInteractionService" in text
    assert "listenOnce()" in text
    assert "response.voiceText" in text
    assert "_voiceInteractionService.speak(voiceText)" in text
    assert "Icons.mic_rounded" in text
    assert "Icons.volume_up_rounded" in text
    assert "_voiceNotice" in text
    assert "_voiceInteractionService.lastFailureMessage" in text


def test_android_main_activity_handles_voice_channel():
    text = ANDROID_MAIN.read_text(encoding="utf-8")

    assert "lanxin_travelmate/voice" in text
    assert "startVoiceInput" in text
    assert "speakText" in text
    assert "RecognizerIntent.ACTION_RECOGNIZE_SPEECH" in text
    assert "TextToSpeech" in text
    assert "RECORD_AUDIO" in text
    assert "onInit" in text
    assert "microphone_permission_denied" in text
    assert "voice_unavailable" in text
    assert "tts_unavailable" in text
