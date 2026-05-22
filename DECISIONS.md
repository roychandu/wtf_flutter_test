# Decisions

## ADR 1: State Management

**Decision:** Use Flutter `ChangeNotifier` with an inherited `ControllerScope`, following the Provider pattern without adding a separate provider package.

**Why:** The assessment is small but has shared state across many screens. `AppController` keeps the app easy to inspect, test, and wire into both role apps. It also avoids forcing an extra state dependency beyond the mandatory 100ms SDK.

## ADR 2: Storage and Sync

**Decision:** Use a local Node bridge as the shared local source for both apps, backed by `token_server/state.json`.

**Why:** Two independently installed mobile apps cannot reliably share the same sandboxed local database. A tiny local server keeps the assessment runnable on emulators, supports real cross-app chat, and still avoids a cloud backend.

**Fallback:** If the bridge is offline, each app keeps an in-memory fallback and surfaces the bridge error in DevPanel.

## ADR 3: RTC Strategy

**Decision:** Integrate `hmssdk_flutter` directly in `HmsMeetingController`; use the local token server for 100ms auth tokens.

**Why:** 100ms requires auth tokens generated outside the client so secrets stay out of Flutter. The controller follows the documented SDK lifecycle: build, attach listener, join with `HMSConfig`, render `HMSVideoView`, handle reconnection, and clean up with leave/destroy.

**Dev shortcut:** If 100ms env vars are missing, `/token` returns a mock token. This preserves the demo workflow while making the real integration active as soon as valid `HMS_APP_ACCESS_KEY`, `HMS_APP_SECRET`, and `HMS_DEV_ROOM_ID` are provided.
