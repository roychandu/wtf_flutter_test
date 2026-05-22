# WTF Flutter Engineer Assessment

Two local Flutter apps for the Guru ↔ Trainer chat, scheduling, 100ms call, and session-log workflow.

## Projects

- `guru_app/` — member app seeded as DK.
- `trainer_app/` — trainer console seeded as Aarav.
- `shared/` — local Flutter package with models, services, UI, theme, and 100ms call integration.
- `token_server/` — local token and sync server.

## Run the Local Bridge

```bash
cd token_server
npm start
```

The Android emulator apps default to `http://10.0.2.2:8787`. For iOS simulator, macOS, or Chrome:

```bash
flutter run --dart-define=WTF_BRIDGE_URL=http://127.0.0.1:8787
```

## Configure 100ms

Copy `.env.example` into your shell or local env manager:

```bash
export HMS_APP_ACCESS_KEY=your_100ms_app_access_key
export HMS_APP_SECRET=your_100ms_app_secret
export HMS_DEV_ROOM_ID=your_100ms_room_id
export HMS_ROLE_MEMBER=member
export HMS_ROLE_TRAINER=trainer
```

If credentials are missing, the app uses mock tiles for the in-call UI while still exercising pre-join, controls, session logs, and post-call sheets. Supplying valid 100ms env values activates `hmssdk_flutter` join.

## Run Apps

```bash
cd guru_app
flutter pub get
flutter run
```

```bash
cd trainer_app
flutter pub get
flutter run
```

## Tests

```bash
cd shared && flutter test
cd ../guru_app && flutter test
cd ../trainer_app && flutter test
```

Coverage includes message serialization, scheduler validation, and session duration calculation.

## Manual Demo Script

1. Start `token_server`.
2. Launch Trainer App and login as Aarav.
3. Launch Guru App and create DK profile.
4. DK sends a chat message; Trainer opens it and replies.
5. DK schedules a call with note `Macros review`.
6. Trainer approves; system message appears in chat.
7. Use `Simulate now`, then Join Call from either app.
8. Check mic/camera, join, toggle controls, end call.
9. Add rating/notes and open Sessions.
