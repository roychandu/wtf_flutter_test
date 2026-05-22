# AI Ledger

| # | Tool | Intent | Output / Use | Commit Link |
| --- | --- | --- | --- | --- |
| 1 | Codex GPT-5 | Read assessment and extract deliverables | Identified two apps, local bridge, 100ms token server, chat, scheduler, sessions, docs, and tests | Pending local commit |
| 2 | Codex GPT-5 | Apply responsive layout skill | Added `AdaptiveScaffold`, `PageShell`, breakpoints, constrained content, and bottom-nav/side-rail behavior | Pending local commit |
| 3 | Codex GPT-5 | Apply UI/UX skill | Chose high-contrast light theme, role colors, visible labels, 44px+ targets, loading and empty states | Pending local commit |
| 4 | Codex GPT-5 | Apply interface polish skill | Added 8px radii, soft shadows, pressed scale, animated chat bubbles, typing dots, and tabular time text | Pending local commit |
| 5 | Codex GPT-5 + 100ms docs | Verify current Flutter SDK approach | Used `hmssdk_flutter` 1.11.1 docs for `HMSSDK.build`, update listeners, join, mute/video/camera controls, and `HMSVideoView` | Pending local commit |
| 6 | Codex GPT-5 | Generate shared data model | Created JSON-safe models and scheduler/session helpers in `shared/lib/models/wtf_models.dart` | Pending local commit |
| 7 | Codex GPT-5 | Build local sync service | Created `token_server/server.js` with state, chat, requests, sessions, and `/token` | Pending local commit |
| 8 | Codex GPT-5 | Implement Guru app flow | Added onboarding, DK profile, home cards, chat, scheduler, requests, calls, sessions | Pending local commit |
| 9 | Codex GPT-5 | Implement Trainer app flow | Added mock login, dashboard, chats, request approval/decline, calls, session notes | Pending local commit |
| 10 | Codex GPT-5 | Add tests | Added serialization, scheduler validation, conflict detection, and duration unit tests | Pending local commit |
| 11 | Codex GPT-5 | Debugging pass | Planned analyzer/test run and follow-up fixes after dependency resolution | Pending local commit |
| 12 | Codex GPT-5 | Documentation | Added README, architecture notes, ADRs, token server instructions, and env placeholders | Pending local commit |
| 13 | Antigravity | Refactor monolith code | Decoupled and modularized monolithic `wtf_app.dart` by extracting and reorganizing all bottom navigation screens into distinct clean modules under `shared/lib/screens/` (home, chat, schedule, requests, sessions, call). | Pending local commit |
| 14 | Antigravity | Optimize real-time reactivity | Upgraded periodic polling interval to `500ms` and implemented deep hash state matching on messages, requests, and sessions inside `app_controller.dart` to enable instantaneous screen rebuilds on state changes. | Pending local commit |
| 15 | Antigravity | Enhance ChoiceChip readability | Added premium high-contrast chip styles in `schedule_screen.dart` and `sessions_screen.dart` to prevent text invisibility in selected and disabled states. | Pending local commit |
| 16 | Antigravity | Fix layout & keyboard sheet overflows | Redesigned `_showDevPanel()` and `_showPostCallSheet()` sheets to clamp heights, safely offset keyboard insets, support text scaling with fitted labels, and wrap inputs inside single child scroll views. | Pending local commit |
| 17 | Antigravity | Contrast and styling fixes | Enhanced chat text layout by removing floating labels, increasing system pill contrast, and boosting peer bubble timestamp contrast in `conversation_screen.dart`. | Pending local commit |
| 18 | Antigravity | Fix real-time read receipts | Resolved chat count sync bug by implementing dynamic, loop-safe `hasUnread` checks in the `build` post-frame callback in `conversation_screen.dart` to immediately clear badge counters on incoming messages. | Pending local commit |
