# Real User Deployment Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Make "蓝心同行" usable by real Android users through a public HTTPS backend and a signed Android install package.

**Architecture:** Keep the Android app as the user-facing client and deploy FastAPI + LangGraph + Postgres as a persistent cloud service. The APK must be built with a public HTTPS `API_BASE_URL`; the server must own model keys, map keys, auth secret, database, backups, logs, and health checks.

**Tech Stack:** Flutter Android, FastAPI, LangGraph, Docker, Docker Compose, Postgres 16, Caddy or Nginx reverse proxy, HTTPS, Android release signing.

## Global Constraints

- Keep Android/vivo as the only maintained mobile target.
- Do not commit real `.env`, model keys, map keys, tokens, signing passwords, private locations, or private photos.
- Mock and fixed samples are allowed only as explicit fallback/test fixtures; real acceptance must use real provider paths with `fallback=false`.
- Production or public environments must set `LANXIN_AUTH_TOKEN_SECRET`; do not use example defaults.
- Current cloud server discovered over SSH: Ubuntu 24.04.4 LTS, Docker 29.6.1, Docker Compose v5.3.0, 1.6 GiB RAM, 40 GiB root disk with about 7.6 GiB free.
- The server is small and already has port 80 in use, so deployment must avoid blind port binding and must include disk/log cleanup.

---

## Delivery Target

The real user experience should be:

1. User opens a download page or receives an APK file.
2. User installs one signed Android APK.
3. APK starts without USB, adb reverse, local LAN, or developer machine.
4. APK talks to `https://<your-domain>/api`.
5. User can create a guest session, chat, save memory, plan a trip, use weather/POI/route tools, select photos, generate copy, and review trips.
6. Server persists data by authenticated user and survives restart.
7. Operators can update backend without asking users to reinstall unless the API contract or app code changes.

## Recommended Deployment Shape

Use one small cloud server for MVP:

- `caddy` or existing 1Panel/Nginx on ports `80/443`
- `api` container bound only to `127.0.0.1:8000`
- `postgres` container bound only to Docker internal network or localhost
- named volumes for Postgres data
- external `.env` stored on the server only
- daily `pg_dump` backup to `/opt/lanxin/backups`
- weekly Docker image/log cleanup because disk is already tight

Prefer domain-based routing:

- `https://api.example.com/api/health`
- `https://api.example.com/docs` can stay enabled for contest/demo, but protect or disable it for public release.
- APK built with `--dart-define=API_BASE_URL=https://api.example.com`.

If no domain is ready, do not ship a real-user APK with raw HTTP IP. Android currently allows cleartext in the Manifest, but this should be treated as a debug-only convenience. Public user traffic should be HTTPS.

## Files To Create Or Modify

- Modify: `infra/docker-compose.yml`
  - Split local demo defaults from production-safe settings.
  - Keep Postgres non-public.
  - Add restart policies, health checks, log rotation, and production env file path.
- Create: `infra/production/docker-compose.yml`
  - Production compose for `api`, `postgres`, and optional `caddy`.
- Create: `infra/production/Caddyfile` or `infra/production/nginx.conf`
  - Reverse proxy HTTPS traffic to API.
- Create: `infra/production/.env.example`
  - Document required production environment variables with placeholders only.
- Create: `scripts/deploy_server.ps1` or `scripts/deploy_server.sh`
  - Package and deploy code to the cloud server without copying secrets from git.
- Modify: `apps/mobile/android/app/build.gradle.kts`
  - Replace debug signing for release with a real keystore-based signing config.
- Create: `apps/mobile/android/key.properties.example`
  - Placeholder-only signing config template.
- Modify: `apps/mobile/README.md`
  - Add real-user APK build and install instructions.
- Create: `docs/handoff/real-user-deployment.md`
  - Operator runbook for server deploy, APK build, smoke checks, rollback, and user support.

## Task 1: Production Server Baseline

**Files:**
- Create: `infra/production/docker-compose.yml`
- Create: `infra/production/.env.example`
- Create: `infra/production/Caddyfile`

**Interfaces:**
- Consumes: existing API image build context at `services/api`.
- Produces: public HTTPS endpoint `https://<domain>/api/health`.

- [ ] **Step 1: Confirm server constraints**

Run locally:

```powershell
ssh 101.132.21.134 'hostname; cat /etc/os-release | head; docker --version; docker compose version; df -h /; free -h; ss -tulpn | grep -E ":80|:443|:8000" || true'
```

Expected:

- Docker and Docker Compose are available.
- At least 4 GiB free disk remains after cleanup.
- Port ownership for `80/443` is known before adding Caddy/Nginx.

- [ ] **Step 2: Prepare server directories**

Run on server:

```bash
sudo mkdir -p /opt/lanxin/{app,env,postgres,backups,logs}
sudo chown -R "$USER":"$USER" /opt/lanxin
chmod 700 /opt/lanxin/env
```

Expected:

- App files live under `/opt/lanxin`.
- Production secrets live outside the git checkout.

- [ ] **Step 3: Create production `.env` from placeholder template**

Required keys:

```dotenv
LANXIN_APP_NAME=蓝心同行 API
LANXIN_APP_VERSION=1.0.0
LANXIN_API_PREFIX=/api
LANXIN_DATABASE_URL=postgresql+psycopg://lanxin:<strong-password>@postgres:5432/lanxin_travelmate
LANXIN_LOG_LEVEL=INFO
LANXIN_MODEL_PROVIDER=openai
LANXIN_MODEL_TIMEOUT_SECONDS=30
LANXIN_OPENAI_BASE_URL=<provider-base-url>
LANXIN_OPENAI_API_KEY=<provider-api-key>
LANXIN_OPENAI_MODEL=<provider-model>
LANXIN_LANXIN_BASE_URL=<optional-vivo-base-url>
LANXIN_LANXIN_API_KEY=<optional-vivo-api-key>
LANXIN_LANXIN_MODEL=<optional-vivo-model>
LANXIN_AMAP_BASE_URL=https://restapi.amap.com
LANXIN_AMAP_API_KEY=<amap-web-service-key>
LANXIN_TOOL_TIMEOUT_SECONDS=8
LANXIN_AUTH_TOKEN_SECRET=<64-plus-random-chars>
LANXIN_AUTH_TOKEN_TTL_SECONDS=2592000
LANXIN_CORS_ORIGINS=["https://<domain>"]
POSTGRES_DB=lanxin_travelmate
POSTGRES_USER=lanxin
POSTGRES_PASSWORD=<strong-password>
```

Expected:

- `.env` is present only on the server.
- No secret value is committed or copied into logs/screenshots.

- [ ] **Step 4: Deploy API + Postgres behind reverse proxy**

Production compose should expose only the reverse proxy publicly. API and Postgres should be internal:

```yaml
services:
  api:
    build:
      context: ../../services/api
    env_file:
      - /opt/lanxin/env/api.env
    restart: unless-stopped
    depends_on:
      postgres:
        condition: service_healthy
    expose:
      - "8000"
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  postgres:
    image: postgres:16-alpine
    restart: unless-stopped
    env_file:
      - /opt/lanxin/env/api.env
    volumes:
      - /opt/lanxin/postgres:/var/lib/postgresql/data
    healthcheck:
      test: ["CMD-SHELL", "pg_isready -U lanxin -d lanxin_travelmate"]
      interval: 10s
      timeout: 5s
      retries: 12
    logging:
      driver: json-file
      options:
        max-size: "10m"
        max-file: "3"

  caddy:
    image: caddy:2-alpine
    restart: unless-stopped
    ports:
      - "80:80"
      - "443:443"
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile:ro
      - caddy_data:/data
      - caddy_config:/config
    depends_on:
      - api

volumes:
  caddy_data:
  caddy_config:
```

If 1Panel already owns `80/443`, do not start this Caddy service. Instead create a 1Panel/Nginx reverse proxy rule to `http://127.0.0.1:8000` or to the Docker service network.

- [ ] **Step 5: Smoke check**

Run:

```bash
curl -fsS https://<domain>/api/health
curl -fsS https://<domain>/docs >/dev/null
docker compose -f infra/production/docker-compose.yml logs --tail=80 api
```

Expected:

- `/api/health` returns `status=ok`.
- Logs do not expose keys or full sensitive user text.
- API uses Postgres, not local SQLite.

## Task 2: Production Data And Operations

**Files:**
- Create: `infra/production/backup-postgres.sh`
- Create: `infra/production/restore-postgres.sh`
- Create: `docs/handoff/real-user-deployment.md`

**Interfaces:**
- Consumes: production Postgres service.
- Produces: daily restorable database backup.

- [ ] **Step 1: Add backup script**

```bash
#!/usr/bin/env bash
set -euo pipefail
stamp="$(date +%Y%m%d-%H%M%S)"
mkdir -p /opt/lanxin/backups
docker compose -f /opt/lanxin/app/infra/production/docker-compose.yml exec -T postgres \
  pg_dump -U lanxin -d lanxin_travelmate \
  | gzip > "/opt/lanxin/backups/lanxin-${stamp}.sql.gz"
find /opt/lanxin/backups -name 'lanxin-*.sql.gz' -mtime +14 -delete
```

- [ ] **Step 2: Add cron**

```bash
crontab -e
```

Add:

```cron
15 3 * * * /opt/lanxin/app/infra/production/backup-postgres.sh >> /opt/lanxin/logs/backup.log 2>&1
30 4 * * 0 docker system prune -af --filter "until=168h" >> /opt/lanxin/logs/docker-prune.log 2>&1
```

Expected:

- At least one manual backup can be produced and restored on a non-production database.
- Disk usage remains under 85%.

- [ ] **Step 3: Add health monitor**

Minimum manual monitor:

```bash
curl -fsS https://<domain>/api/health || echo "health failed"
```

Recommended later:

- UptimeRobot, 1Panel monitor, or a lightweight cron alert.
- Alert on `/api/health`, disk > 85%, container restart loop, and provider fallback spike.

## Task 3: Android Release Signing And Build

**Files:**
- Modify: `apps/mobile/android/app/build.gradle.kts`
- Create: `apps/mobile/android/key.properties.example`
- Modify: `.gitignore`
- Modify: `apps/mobile/README.md`

**Interfaces:**
- Consumes: production HTTPS API URL.
- Produces: signed APK at `apps/mobile/build/app/outputs/flutter-apk/app-release.apk`.

- [ ] **Step 1: Generate keystore**

Run locally and store the keystore outside git:

```powershell
keytool -genkeypair -v `
  -keystore E:\secrets\lanxin-release.jks `
  -keyalg RSA `
  -keysize 2048 `
  -validity 10000 `
  -alias lanxin
```

Expected:

- `lanxin-release.jks` is never committed.
- Passwords are kept in password manager or team secret storage.

- [ ] **Step 2: Add signing config**

`apps/mobile/android/key.properties` should be local-only:

```properties
storeFile=E:\\secrets\\lanxin-release.jks
storePassword=<store-password>
keyAlias=lanxin
keyPassword=<key-password>
```

`build.gradle.kts` should load `key.properties` and use release signing, not debug signing.

- [ ] **Step 3: Build release APK with production API URL**

Run:

```powershell
cd apps/mobile
flutter clean
flutter pub get
flutter build apk --release --dart-define=API_BASE_URL=https://<domain>
```

Expected:

- Release APK builds successfully.
- APK does not point to `127.0.0.1`, `10.0.2.2`, or LAN IP.

- [ ] **Step 4: Verify APK endpoint**

Run:

```powershell
Select-String -Path .\build\app\outputs\flutter-apk\app-release.apk -Pattern "127.0.0.1","10.0.2.2","http://"
```

Expected:

- No local debug endpoint is found.
- `https://<domain>` is the only backend endpoint intended for production.

## Task 4: Real User Distribution

**Files:**
- Create: `docs/handoff/apk-release-notes.md`
- Optional Create: `infra/production/download-page/index.html`

**Interfaces:**
- Consumes: signed APK.
- Produces: user-facing install package and release notes.

- [ ] **Step 1: Choose distribution mode**

For contest or small beta:

- Host APK at `https://<domain>/downloads/lanxin-travelmate-1.0.0.apk`.
- Provide a short install guide for Android "install unknown apps".
- Keep a checksum next to the APK.

For broader public users:

- Use app store distribution after privacy policy, app signing, screenshots, compatibility tests, and review materials are ready.
- Direct APK should remain the fallback/beta path, not the only long-term channel.

- [ ] **Step 2: Publish release metadata**

Release note must include:

- App name and version.
- Backend API domain.
- Required permissions: network, location, camera, microphone, notification, photos.
- What user data is stored locally/cloud.
- Known limitations: only Android/vivo maintained; model/provider may degrade with visible fallback reason.
- Contact/support channel.

- [ ] **Step 3: Install on clean device**

Run on a clean Android/vivo phone:

```powershell
adb install -r .\apps\mobile\build\app\outputs\flutter-apk\app-release.apk
```

Manual user path:

- Open app.
- Allow normal permissions when the feature asks.
- Create guest session.
- Send a Chinese travel request.
- Confirm memory.
- Generate a real trip plan.
- Check weather/POI/route provider trace.
- Generate photo copy.
- Generate trip review.
- Kill and restart app.
- Confirm session and data still load.

Expected:

- No developer machine, adb reverse, local backend, or USB dependency.
- Server logs show real provider paths with `fallback=false` for acceptance scenarios.

## Task 5: Acceptance Gates Before Shipping

**Files:**
- Modify: `docs/handoff/final-acceptance.md`
- Modify: `docs/todo.md`

**Interfaces:**
- Consumes: deployed backend and release APK.
- Produces: signed-off real-user release.

- [ ] **Gate 1: Backend**

Pass conditions:

- `https://<domain>/api/health` returns ok.
- API container restarts cleanly.
- Alembic migrations run on empty Postgres.
- Postgres data persists after `docker compose restart`.
- Backup script creates a readable `.sql.gz`.
- Logs do not contain keys, tokens, passwords, or full sensitive user text.

- [ ] **Gate 2: Model And Tool Providers**

Pass conditions:

- `real_provider_smoke.py` passes against production environment.
- Weather, POI, walking, driving, transit, and mixed route calls use Amap with `fallback=false`.
- Memory extraction, trip planning, companion chat, photo copywriting, and trip review use real model provider with `fallback=false` in final demo scenarios.
- If provider is unconfigured or fails, UI shows explicit fallback/unconfigured reason.

- [ ] **Gate 3: Android**

Pass conditions:

- Release APK is signed with release keystore.
- `versionName` and `versionCode` are final for the release.
- APK uses HTTPS production API URL.
- Install and first-run work on at least two Android/vivo devices.
- Location, camera, album, microphone, speech recognition, TTS, and notification paths are manually checked.
- App restart keeps auth/session state.

- [ ] **Gate 4: Privacy And Compliance**

Pass conditions:

- Permission prompts and settings copy match actual usage.
- Privacy text explains memory, profile, trip, photo metadata, and cloud sync.
- User confirms before publishing generated social content.
- Local photo `localPath/localUri` is not saved to cloud.
- Demo screenshots/videos contain no private location, key, token, or unauthorized photo.

## Timeline

### Day 1: Public Backend

- Pick domain and DNS.
- Clean server disk if needed.
- Deploy API + Postgres with production `.env`.
- Configure HTTPS reverse proxy.
- Verify `/api/health`, `/docs`, migration, and provider smoke.

### Day 2: Release APK

- Configure release signing.
- Build `app-release.apk` with production `API_BASE_URL`.
- Install on two phones.
- Fix only blocking issues in login/session/network/permissions.

### Day 3: Distribution And Evidence

- Publish APK download page or release asset.
- Run final real-user acceptance checklist.
- Capture demo evidence: app screens, Swagger/health, audit logs, toolTrace, provider smoke.
- Freeze version and create release notes.

### After Contest MVP

- Add object storage for uploaded photo assets if photos need true cloud availability.
- Add rate limits and abuse controls.
- Add admin/ops dashboard for fallback rate and provider cost.
- Move to managed Postgres or larger server if active users exceed single-server capacity.
- Submit to app store if the target shifts from contest/demo users to broader public users.

## Current Risks

- Release signing is not configured; current release build still uses debug signing.
- Public HTTPS domain is not configured in the repo.
- Server disk is already 80% used; production deployment needs cleanup and log rotation.
- Server memory is only 1.6 GiB; keep the stack small and avoid heavy observability components.
- Port 80 is already occupied; integrate with existing 1Panel/Nginx or identify the owner before starting Caddy.
- `android:usesCleartextTraffic="true"` is acceptable for local debug but should not be relied on for public user traffic.
- Existing GitHub release workflow builds `app-debug.apk`; it should not be treated as the real public install package.
