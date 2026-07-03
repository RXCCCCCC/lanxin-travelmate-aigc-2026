# Lanxin TravelMate Mobile

Flutter Android client for "Lanxin TravelMate" ("Lanxin Tongxing"). This repo only maintains the Android/vivo platform shell; do not restore iOS, macOS, Windows, Linux, or Web Flutter platform directories.

## Run

```powershell
flutter pub get
$env:NO_PROXY='localhost,127.0.0.1,::1'
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

Android emulator:

```powershell
flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
```

Physical vivo/Android device:

```powershell
adb reverse tcp:8000 tcp:8000
flutter run --dart-define=API_BASE_URL=http://127.0.0.1:8000
```

## Validate

```powershell
flutter analyze
flutter test --concurrency=1
python ..\..\scripts\android_release_preflight.py --json
python ..\..\scripts\android_device_readiness_report.py --json
flutter build apk --debug
```

## Android Device Channels

`MainActivity.kt` exposes these MethodChannel paths:

- `lanxin_travelmate/photo_picker`: gallery/camera, backed by the `photo_picker` service guard.
- `lanxin_travelmate/location`: current location, backed by the `location` service guard.
- `lanxin_travelmate/voice`: speech recognition and TTS, backed by the `voice` service guard.
- `lanxin_travelmate/notifications`: reminder notifications, backed by the `notifications` service guard.

Permission denial must surface a clear Chinese in-app message and must not create fake photo, location, voice, or notification data.

## Notes

Backend URL is passed with `API_BASE_URL`. Real provider quality, vivo permission prompts, release signing, and competition upload remain manual validation items tracked in `docs/todo.md`.
