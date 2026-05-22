# Architecture

## Shape

The repo uses a local shared package:

- `shared/models` contains `UserProfile`, `Message`, `CallRequest`, `RoomMeta`, and `SessionLog`.
- `shared/services` contains `AppController`, `DevBridgeClient`, and `HmsMeetingController`.
- `shared/widgets` and `shared/screens` contain the reusable responsive app shell and workflows.
- `guru_app` and `trainer_app` only bootstrap `WtfApp` with different roles.

## Runtime Data Flow

`token_server` is the local-first sync layer. Both apps poll `/state`, post chat messages, call requests, approvals, and session updates. This gives both apps a real shared source when they run side by side without needing Firebase.

If the bridge is unavailable, `AppController` keeps a local in-memory fallback so screens remain operable and display human-readable error states.

## 100ms Flow

On trainer approval, the bridge writes `RoomMeta` with:

- `hmsRoomId`
- `hmsRoleMember`
- `hmsRoleTrainer`

The call screen opens a pre-join sheet, requests `GET /token?userId=&role=&roomId=`, and passes the returned auth token into:

```dart
HMSSDK().build();
hmsSDK.addUpdateListener(listener: this);
hmsSDK.join(config: HMSConfig(authToken: token, userName: name));
```

`HmsMeetingController` handles `onJoin`, peer updates, track updates, reconnection, mute, video toggle, camera flip, and leave. `HMSVideoView` renders real video tracks. If token env vars are not configured, the server returns a mock token and the call screen uses local mock tiles for demo continuity.

## Responsive UI

The UI uses `LayoutBuilder` and constraint-based breakpoints:

- Phones use a bottom `NavigationBar`.
- Wider windows use a left rail with constrained content width.
- Lists use builder APIs or constrained page shells to avoid stretched layouts.

Touch targets are at least 44px, with role-colored filled/outline CTAs and light backgrounds for assessment contrast requirements.

## Observability

The floating DevPanel shows bridge status, masked env names, and the latest structured logs with `[CHAT]`, `[RTC]`, `[SCHEDULE]`, and `[AUTH]` tags.
