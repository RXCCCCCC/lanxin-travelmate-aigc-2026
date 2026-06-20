from fastapi.testclient import TestClient

from app.main import app


client = TestClient(app)


def test_audio_status_reports_fallback_readiness():
    response = client.get("/api/audio/status")

    assert response.status_code == 200
    payload = response.json()
    assert payload["status"] == "ready"
    assert payload["asr"]["configured"] is False
    assert payload["tts"]["configured"] is False


def test_audio_asr_returns_text_and_trace_id():
    response = client.post(
        "/api/audio/asr",
        json={
            "userId": "audio-user-a",
            "audioRef": "file-audio-1",
            "mockText": "我想用语音规划重庆两天",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["text"] == "我想用语音规划重庆两天"
    assert payload["fallback"] is True
    assert payload["toolTraceId"].startswith("tool-")


def test_audio_tts_returns_voice_text_and_trace_id():
    response = client.post(
        "/api/audio/tts",
        json={
            "userId": "audio-user-a",
            "text": "蓝小心正在规划你的路线。",
            "voice": "lanxiaoxin",
        },
    )

    assert response.status_code == 200
    payload = response.json()
    assert payload["voiceText"] == "蓝小心正在规划你的路线。"
    assert payload["audioUrl"] is None
    assert payload["fallback"] is True
    assert payload["toolTraceId"].startswith("tool-")