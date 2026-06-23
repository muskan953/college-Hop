# College Hop — Flutter Frontend

The Flutter mobile and web client for **College Hop** — a verified-student platform for discovering events, forming travel groups, and messaging peers in real time.

**Supports:** Android · iOS · Web

---

## Table of Contents

1. [Tech Stack](#tech-stack)
2. [Project Structure](#project-structure)
3. [Getting Started](#getting-started)
4. [Configuration](#configuration)
5. [Architecture](#architecture)
6. [State Management](#state-management)
7. [Real-Time Messaging](#real-time-messaging)
8. [Screens](#screens)
9. [Testing](#testing)
10. [Known Issues](#known-issues)

---

## Tech Stack

| Package | Version | Purpose |
|---|---|---|
| `flutter` SDK | ^3.8.1 | UI framework |
| `provider` | ^6.1.2 | State management (ChangeNotifier) |
| `http` | ^1.2.1 | REST API calls |
| `web_socket_channel` | ^3.0.3 | WebSocket connection |
| `firebase_messaging` | ^15.2.5 | FCM push notifications |
| `firebase_core` | ^3.13.0 | Firebase initialisation |
| `flutter_secure_storage` | ^9.0.0 | JWT storage (Keychain / Keystore) |
| `file_picker` | ^8.0.0 | ID card PDF upload |
| `image_picker` | ^1.0.7 | Profile photo selection |
| `emoji_picker_flutter` | ^4.4.0 | In-chat emoji picker |
| `intl` | ^0.19.0 | Date/time formatting |
| `url_launcher` | ^6.2.6 | Open external links |
| `confetti` | ^0.7.0 | Celebration animations |

---

## Project Structure

```
lib/
├── main.dart                    # App entry — Firebase init, provider setup, routing
├── mainn_screen.dart            # Bottom navigation shell
├── bottom_nav_bar.dart          # Navigation bar widget
│
├── providers/
│   ├── auth_provider.dart       # Token storage, login/logout, JWT parsing (userId)
│   ├── profile_provider.dart    # Profile data, preferences, file uploads
│   ├── event_provider.dart      # Active event selection
│   ├── signup_provider.dart     # Multi-step signup form state
│   └── message_provider.dart   # ⭐ Thread/message state, WS init, FCM token
│
├── services/
│   ├── api_service.dart         # ⭐ All REST API calls (single source of truth)
│   └── websocket_service.dart  # ⭐ WS connect/reconnect + stream
│
├── screen/
│   ├── messages_screen.dart    # Thread list + ChatDetailScreen
│   ├── profile_screen.dart     # User profile view/edit
│   └── ...                     # Other screens (events, groups, matching, etc.)
│
├── models/                      # Dart data models
├── widgets/                     # Reusable UI components
├── theme/                       # App theme / colour tokens
└── utils/                       # Helpers (date formatting, validators, etc.)
```

---

## Getting Started

### Prerequisites

- Flutter SDK ^3.8.1 (`flutter --version` to confirm)
- Dart SDK ^3.8.1
- Android Studio / Xcode (for mobile) or Chrome (for web)
- A running College Hop backend (see [`../backend/README.md`](../backend/README.md))

### Install & Run

```bash
cd college_hop_frontend

# Install dependencies
flutter pub get

# Run on connected Android/iOS device or emulator
flutter run

# Run on Chrome (web — WebSocket works on localhost)
flutter run -d chrome

# List available devices
flutter devices
```

---

## Configuration

The API base URL is currently set as a constant in `lib/services/api_service.dart`.

| Environment | URL |
|---|---|
| Local (Web / iOS Simulator) | `http://localhost:8080` |
| Local (Android Emulator) | `http://10.0.2.2:8080` |
| Local (Physical Android via ADB) | `http://localhost:8080` with `adb reverse tcp:8080 tcp:8080` |
| Production | Set to your deployed backend URL |

### Firebase

The app uses Firebase for push notifications. Ensure:
- `google-services.json` is placed in `android/app/`
- `GoogleService-Info.plist` is placed in `ios/Runner/`
- Firebase project is configured with FCM enabled

---

## Architecture

### Pattern

```
Screen (Widget)
    → Provider (ChangeNotifier)
    → ApiService / WebSocketService
    → Backend REST API / WebSocket
```

- **Screens** listen to providers via `Consumer<T>` or `context.watch<T>()`.
- **Providers** call `ApiService` for HTTP and `WebSocketService` for real-time data, then call `notifyListeners()`.
- **No business logic lives in widgets.**

---

## State Management

There are **5 providers**, all registered at the root in `main.dart`:

| Provider | Responsibility |
|---|---|
| `AuthProvider` | Access/refresh token storage (`FlutterSecureStorage`), login/logout, JWT parsing for `userId` |
| `ProfileProvider` | Fetch and update profile, preferences, file uploads |
| `EventProvider` | Currently selected event state |
| `SignUpProvider` | Multi-step signup form — email → OTP → profile details |
| `MessageProvider` | ⭐ Thread list, message history, WebSocket lifecycle, FCM device token registration, `isConnected` flag |

---

## Real-Time Messaging

### WebSocket Service (`services/websocket_service.dart`)

- Connects to `ws://<host>/ws?token=<JWT>`
- **Generation-based reconnect guard** prevents ghost connection loops
- **Exponential backoff:** `max(10s, 2^n)` — minimum 10 s delay prevents rapid reconnect storms
- **Max 8 reconnect attempts** before giving up
- Exposes a `messageStream` (broadcast `Stream<Map>`) and `isConnected` bool

### Message Provider (`providers/message_provider.dart`)

- Calls `WebSocketService.connect()` on login
- Handles FCM token registration (`POST /me/device-token`)
- Drives the polling fallback: **only polls when `isConnected == false`**

### Incoming Event Handling

| WS Event | Effect in UI |
|---|---|
| `new_message` | Appends message bubble, scrolls to bottom |
| `message_sent` | Replaces temp (optimistic) bubble with confirmed ID |
| `message_deleted` | Removes bubble by `message_id` from both users |
| `user_typing` | Shows animated typing indicator, auto-hides after 3 s |
| `presence_update` | Updates green dot on thread tile + app bar subtitle |
| `error` | Removes last optimistic bubble, shows snackbar with server error |

### Features

- **Reply:** Long-press → reply → quoted text appears in both sender and receiver bubbles
- **Forward:** Long-press → forward → select connection → forwarded tag shown
- **Unsend:** Long-press → delete → hard delete via `DELETE /messages/{id}` + WS broadcast removes it from all participants
- **Bulk delete:** Multi-select mode — delete icon hidden if any selection is from the other person
- **Emoji picker:** Toggle button in chat input (`emoji_picker_flutter`)
- **Dynamic timestamps:** Compute relative time (e.g. "2m ago") live without reopening chat
- **Online presence:** Green dot on thread list; "Online" / "Offline" subtitle in chat app bar

---

## Screens

| Screen | Description |
|---|---|
| Signup / Login | Email → OTP → Profile setup (multi-step) |
| Home / Events | Browse approved events, select interest status |
| Groups | List, create, join, view members, suggested groups |
| Peer Matching | Interest-scored matches for a selected event |
| Messages | Thread list + 1:1 chat with full real-time features |
| Profile | View/edit own profile, upload photo and ID card |
| Connect Profile | Send/view connection request, pending state persists on reload |

---

## Testing

```bash
# Run all Flutter tests
flutter test

# Run with verbose output
flutter test --verbose
```

> Widget tests are currently stub-level. Full widget test coverage is a planned improvement.

When adding new mocked services, update `test/` mock classes accordingly.

---

## Building for Production

```bash
# Android APK
flutter build apk --release

# Android App Bundle (Play Store)
flutter build appbundle --release

# iOS (requires macOS + Xcode)
flutter build ios --release

# Web
flutter build web --release
```
