import asyncio
import json
import time
import uuid
from typing import Optional

import websockets
from websockets.asyncio.client import ClientConnection

from app.core.config import get_settings

_VIVO_ASR_URI = "ws://api-ai.vivo.com.cn/asr/v2"


class VivoAsrError(Exception):
    pass


class VivoAsrClient:
    def __init__(self, api_key: Optional[str] = None) -> None:
        settings = get_settings()
        self._api_key = api_key or settings.lanxin_api_key
        if not self._api_key:
            raise VivoAsrError("缺少 vivo API Key，无法连接语音识别服务")

    async def recognize(self, pcm_bytes: bytes, timeout_seconds: float = 15.0) -> str:
        url = self._build_url()
        headers = {"Authorization": f"Bearer {self._api_key}"}
        request_id = uuid.uuid4().hex

        try:
            async with websockets.connect(url, additional_headers=headers) as ws:
                await self._send_started(ws, request_id)
                await self._stream_audio(ws, pcm_bytes)
                text = await self._receive_result(ws, request_id, timeout_seconds)
                return text
        except TimeoutError:
            raise VivoAsrError("语音识别超时，请重试")
        except websockets.ConnectionClosed as exc:
            raise VivoAsrError(f"ASR 连接异常关闭: code={exc.code}") from exc
        except OSError as exc:
            raise VivoAsrError(f"ASR 网络错误: {exc}") from exc

    def _build_url(self) -> str:
        now_millis = str(int(time.time() * 1000))
        params = {
            "client_version": "1.0.0",
            "package": "com.lanxin.lanxin_travelmate",
            "sdk_version": "1.0.0",
            "user_id": uuid.uuid4().hex,
            "android_version": "14",
            "system_time": now_millis,
            "net_type": "1",
            "engineid": "shortasrinput",
            "requestId": uuid.uuid4().hex,
        }
        qs = "&".join(f"{k}={v}" for k, v in params.items())
        return f"{_VIVO_ASR_URI}?{qs}"

    async def _send_started(self, ws: ClientConnection, request_id: str) -> None:
        payload = {
            "type": "started",
            "request_id": request_id,
            "asr_info": {
                "end_vad_time": 800,
                "audio_type": "pcm",
                "chinese2digital": 0,
                "punctuation": 1,
            },
        }
        await ws.send(json.dumps(payload, ensure_ascii=False))

    async def _stream_audio(self, ws: ClientConnection, pcm_bytes: bytes) -> None:
        frame_size = 1280
        for offset in range(0, len(pcm_bytes), frame_size):
            frame = pcm_bytes[offset : offset + frame_size]
            await ws.send(frame)
            await asyncio.sleep(0.04)

        await ws.send(b"--end--")

    async def _receive_result(
        self, ws: ClientConnection, request_id: str, timeout_seconds: float
    ) -> str:
        final_text = ""

        async def _read_loop() -> None:
            nonlocal final_text
            while True:
                raw = await ws.recv()
                if isinstance(raw, bytes):
                    continue
                msg = json.loads(raw)
                if msg.get("action") == "error":
                    raise VivoAsrError(
                        f"ASR 识别错误: {msg.get('desc', '未知错误')}"
                    )
                data = msg.get("data")
                if isinstance(data, dict):
                    text = data.get("text", "")
                    if data.get("is_last"):
                        if data.get("reformation") == 1:
                            final_text = text
                        else:
                            final_text += text
                        return
                    if data.get("reformation") == 1:
                        final_text = text
                    else:
                        final_text += text

        await asyncio.wait_for(_read_loop(), timeout=timeout_seconds)
        return final_text.strip()
