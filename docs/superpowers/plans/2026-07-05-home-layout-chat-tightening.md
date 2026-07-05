# Home Layout And Chat Tightening Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Tighten the Android home screen layout, keep the weather strip fixed in pure mode, repair home chat feedback, and simplify the bottom tab collapse affordance.

**Architecture:** Keep the existing single-file home screen structure and the existing shell router. Changes are scoped to `home_page.dart` for home widgets and `app_router.dart` for bottom navigation behavior; no platform shell changes.

**Tech Stack:** Flutter, Dart, GoRouter, existing Android-only app shell.

## Global Constraints

- Android/vivo only; do not restore or edit iOS, macOS, Windows, Linux, or Web platform shells.
- Preserve the user's restored local home UI direction; do not reintroduce teammate remote home styling.
- Use Chinese app-facing copy.
- Prefer real device validation when connected; otherwise use Android emulator.
- Before commit, run `flutter analyze --no-pub`, `git diff --check`, and `node .gitnexus\run.cjs detect_changes --repo lanxin-travelmate-aigc-2026`.

---

### Task 1: Tighten Home Top Layout

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`

**Interfaces:**
- Consumes: existing `HomeWeatherSummary`, `_WeatherStrip`, `_TripPill`, `_ModeExitBubble`.
- Produces: fixed top weather strip visible in both companion and pure modes.

- [ ] Move `_WeatherStrip` to `topSafe + 2`, keep it outside `_ModeExitBubble`, and reduce its height to a thin full-width glass strip.
- [ ] Move `_TripPill` upward below the weather strip.
- [ ] Render weather as three aligned fields: location left, condition center, temperature right.
- [ ] Remove visible refresh icon from `_WeatherStrip`; keep whole-strip tap refresh.

### Task 2: Simplify Status Drawer Toggle

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`

**Interfaces:**
- Consumes: `_statusExpanded`, `_StatusDrawer`.
- Produces: status card with embedded left-edge chevron that moves with the drawer.

- [ ] Remove standalone status expand tab.
- [ ] Put a compact chevron button on the left edge of the status drawer.
- [ ] Keep folded state narrow and nonintrusive.

### Task 3: Tighten Chat Panel

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`

**Interfaces:**
- Consumes: `_panelHeightRatio`, `_ChatGlassPanel`, `_MessageBubble`.
- Produces: wider message bubbles, smaller input/function gaps, and expanded drag range.

- [ ] Extend drag max so the panel can reach just below the current-trip pill.
- [ ] Extend drag min so history can collapse close to the input.
- [ ] Reduce panel inner horizontal and vertical padding.
- [ ] Increase max bubble width for assistant and user messages while preserving left/right alignment.
- [ ] Move input and quick actions closer to the panel bottom with tiny non-overlapping gaps.

### Task 4: Repair Home Chat Feedback

**Files:**
- Modify: `apps/mobile/lib/features/home/home_page.dart`
- Inspect only if needed: `apps/mobile/lib/features/home/data/home_chat_controller.dart`

**Interfaces:**
- Consumes: existing `HomeChatController.isSending`, `queuedMessage`, `messages`.
- Produces: immediate user-message display, visible thinking row, and clear failure status.

- [ ] Verify local backend health and chat endpoint before changing logic.
- [ ] Confirm `_sendHomeMessage()` clears input and triggers immediate controller state update.
- [ ] If UI does not refresh, add a local `setState` after send starts and after controller updates.
- [ ] Keep "正在思考中......" visible while sending.

### Task 5: Simplify Bottom Tab Collapse

**Files:**
- Modify: `apps/mobile/lib/core/router/app_router.dart`

**Interfaces:**
- Consumes: existing `_collapsed` shell state and tab navigation.
- Produces: centered top-edge chevron in expanded state and full-width thin glass bar in collapsed state.

- [ ] Remove the standalone bottom-right circular collapse bubble.
- [ ] In expanded state, place a small chevron on the top center edge of the tab row.
- [ ] In collapsed state, render a full-width thin glass bar with a centered pure angle chevron.
- [ ] Preserve persisted user collapse preference and horizontal swipe tab switching.

### Task 6: Android Validation And Commit

**Files:**
- Modify as needed: no additional source files unless validation exposes a scoped bug.

**Interfaces:**
- Consumes: Android device or emulator, backend on `127.0.0.1:8000` with `adb reverse` when needed.
- Produces: committed verified layout and chat fix.

- [ ] Run `flutter analyze --no-pub`.
- [ ] Build and install Android debug APK on available Android target.
- [ ] Verify companion mode and pure mode screenshots.
- [ ] Send a Chinese travel prompt and verify thinking state plus response or clear failure message.
- [ ] Run `git diff --check`.
- [ ] Run GitNexus detect changes.
- [ ] Commit with a concise message.
