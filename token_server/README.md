# WTF Token + Local Sync Server

This tiny Node server does two jobs for the assessment:

- `GET /token?userId=&role=&roomId=` returns a 100ms auth token.
- Local sync endpoints keep chat, call requests, and session logs shared between the Guru and Trainer apps.

## Run

```bash
cd token_server
npm start
```

Android emulator apps default to `http://10.0.2.2:8787`. For iOS simulator or desktop, run Flutter with:

```bash
flutter run --dart-define=WTF_BRIDGE_URL=http://127.0.0.1:8787
```

## 100ms configuration

Create `.env` values in your shell before starting the server:

```bash
export HMS_APP_ACCESS_KEY=your_100ms_app_access_key
export HMS_APP_SECRET=your_100ms_app_secret
export HMS_DEV_ROOM_ID=your_100ms_room_id
export HMS_ROLE_MEMBER=member
export HMS_ROLE_TRAINER=trainer
npm start
```

If the credentials are missing, `/token` returns a `mock.*` token so the app can still demonstrate pre-join, controls, logs, and the local session workflow. Real 100ms join activates as soon as valid credentials and a room id are supplied.
