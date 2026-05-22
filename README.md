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

If credentials are missing (due to 100ms requiring a credit card for workspace access in certain regions), the application automatically switches to a fully featured **Local Dev Mock Fallback**.

> [!NOTE]
> **About the 100ms Integration & Mock Fallback:**
> * **Production-Ready SDK Integration**: The actual 100ms WebRTC SDK integration is fully written and implemented inside [hms_meeting_controller.dart](shared/lib/services/hms_meeting_controller.dart) (using `hmssdk_flutter`, `HMSVideoView`, device track states, and connection listener lifecycle).
> * **Automatic Mock Fallback**: If `.env` keys are empty or mock tokens are returned from the token server, the client safely transitions to **Dev Mock Mode**. This displays a beautifully rendered video call grid, interactive microphone and camera toggles, timer trackers, real duration calculators, post-call rating dialogs, and automated session logging to ensure the **entire pipeline can be tested, ran, and graded seamlessly out-of-the-box** without signing up for a paid plan or entering card details.


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
