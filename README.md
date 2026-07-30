# Share Cart

A Flutter mobile application for managing shared grocery and shopping lists. Multiple users can collaborate on the same list in real time — adding items, marking them complete, and inviting members to contribute.

Share Cart connects to a [Spring Boot REST backend](docs/flutter-backend-integration.md) and is designed with a clean layered architecture that makes it easy to extend with new features.

---

## Screenshots

> _Coming soon — run the app locally with the backend to explore the UI._

---

## Features

- **JWT authentication** — register and login with email and password
- **Create shopping lists** — backend assigns ownership from JWT token automatically
- **Home screen loads your lists** — fetches all lists owned by or shared with the logged-in user
- **Add, edit, and delete items** — name, quantity, and category
- **Toggle item completion** with a single tap
- **Invite members** to collaborate on a list
- **Invite by shareable link** for list owners
- **Invite preview + join flow** for invite links
- **QR-based invites** — generate QR from invite link and scan to join
- **Deep link handling** for `https://sharecart.app/invite/{token}` links
- **View members** and their roles
- **Items grouped by category** on the detail screen
- **Swipe-to-delete** with confirmation
- **Pull-to-refresh** to sync with the backend
- **Real-time collaborative sync** — lists update live across members via WebSockets (STOMP)
- **AI receipt/price-tag extraction** via ShareCart AI service (`/receipt/extract`)
- **Multi-item editable scan flow** — edit and confirm multiple extracted items in one pass
- **Price history** — view previously captured item prices, filterable by item name
- **Location tagging** — attaches your location (`geolocator`) to captured prices
- **Secure token storage** using `flutter_secure_storage` (not SharedPreferences)
- **Auto-logout** on 401/403 — app returns to login screen if token is invalid/expired
- **Material 3** theming with automatic light/dark mode

---

## Quick Invite Flow

Use this as a fast test checklist for invite sharing and joining.

1. **Owner opens a list** on the List Detail screen.
2. Tap **Share** in the app bar, or open **Invite Member** and choose:
    - **Share Invite Link**, or
    - **Show QR Code**.
3. **Member joins** by either:
    - opening the shared invite link, or
    - scanning the QR from **Home -> Scan QR to Join**.
4. App opens the **Invite Preview** screen.
5. Member taps **Join List**.
6. On success, app navigates to the joined list detail screen.

Notes:
- If the user is not logged in, the app stores the pending invite token and resumes after login.
- Expired/invalid/already-joined states are handled with clear messages.

---

## Tech Stack

| Layer              | Technology                       |
|--------------------|----------------------------------|
| Framework          | Flutter (Dart SDK ^3.7.2)        |
| State Management   | Provider (`ChangeNotifier`)      |
| HTTP Client        | `http` package                   |
| Local Storage      | `shared_preferences`             |
| Secure Storage     | `flutter_secure_storage`         |
| Deep Linking       | `app_links`                      |
| Sharing            | `share_plus`                     |
| QR Rendering       | `qr_flutter`                     |
| QR Scanning        | `mobile_scanner`                 |
| Real-time Sync     | `stomp_dart_client` (WebSocket/STOMP) |
| Image Capture      | `image_picker`                   |
| AI Extraction      | ShareCart AI Service (`/receipt/extract`) |
| Location           | `geolocator`                     |
| Design System      | Material 3 with green color seed |
| Backend            | Spring Boot REST API (JWT)       |

---

## Architecture

The project follows a strict layered architecture:

```
Screens (UI)  →  Providers (State)  →  Repository  →  API Services  →  ApiClient
```

```
lib/
├── main.dart                          # Entry point + DI wiring
├── app.dart                           # MaterialApp with theming
├── config/
│   └── api_config.dart                # Platform-aware base URL
├── models/
│   ├── models.dart                    # Barrel export
│   ├── auth_response_model.dart
│   ├── shopping_list_model.dart
│   ├── shopping_list_summary_model.dart
│   ├── item_model.dart
│   ├── member_model.dart
│   ├── invite_link_response_model.dart
│   ├── accept_invite_response_model.dart
│   ├── invite_preview_model.dart
│   ├── receipt_extraction_model.dart
│   ├── confirm_prices_request_model.dart
│   ├── item_price_model.dart
│   ├── list_realtime_event_model.dart
│   └── api_error_model.dart
├── services/
│   ├── services.dart                  # Barrel export
│   ├── api_client.dart                # HTTP client + Bearer token + error mapping
│   ├── auth_api_service.dart
│   ├── shopping_list_api_service.dart
│   ├── item_api_service.dart
│   ├── invite_api_service.dart
│   ├── price_api_service.dart
│   ├── receipt_extraction_api_service.dart
│   ├── pending_invite_service.dart
│   └── realtime_sync_service.dart
├── repositories/
│   ├── auth_session_repository.dart   # Secure JWT storage (ChangeNotifier)
│   ├── auth_repository.dart           # Auth orchestration
│   └── shopping_list_repository.dart
├── providers/
│   ├── auth_provider.dart
│   ├── home_provider.dart
│   ├── list_detail_provider.dart
│   ├── price_provider.dart
│   └── price_history_provider.dart
└── screens/
    ├── auth/
    │   ├── auth_gate.dart             # Routes to login or home based on auth state
    │   ├── login_screen.dart
    │   └── register_screen.dart
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── create_list_dialog.dart
    │       └── open_list_dialog.dart
    ├── invite/
    │   ├── invite_preview_screen.dart
    │   ├── invite_qr_widget.dart
    │   └── scan_qr_screen.dart
    ├── price_scan/
    │   └── price_scan_screen.dart
    ├── price_history/
    │   └── price_history_screen.dart
    └── list_detail/
        ├── list_detail_screen.dart
        └── widgets/
            ├── item_tile.dart
            ├── add_item_sheet.dart
            ├── invite_member_sheet.dart
            └── members_sheet.dart
```

For a detailed breakdown, see [docs/flutter-app-architecture.md](docs/flutter-app-architecture.md).

---

## Prerequisites

- [Flutter SDK](https://docs.flutter.dev/get-started/install) (^3.7.2)
- An Android emulator, iOS simulator, or Chrome for web
- The Share Cart Spring Boot backend — either running locally on port **8080**, or use the deployed Render instance (configured by default)

---

## Getting Started

### 1. Clone the repository

```bash
git clone <repository-url>
cd ShareCartFlutterProject
```

### 2. Install dependencies

```bash
flutter pub get
```

### 3. Configure the backend

Open `lib/config/api_config.dart` and set the `useProductionServer` flag:

```dart
// true  → uses the deployed Render backend (default)
// false → uses your local Spring Boot on port 8080
static const bool useProductionServer = true;
```

When using **production mode**, the app uses:

- Spring API: `https://sharecartspringbootproject.onrender.com/api/v1`
- AI API: `https://sharecart-ai-services.onrender.com/api/v1`
- WebSocket: `wss://sharecartspringbootproject.onrender.com/ws`

When using **local mode**, URLs are auto-detected per platform:

| Platform              | Spring API                        | AI API                           |
|-----------------------|-----------------------------------|----------------------------------|
| Android emulator      | `http://10.0.2.2:8080/api/v1`    | `http://10.0.2.2:8000/api/v1`    |
| iOS simulator / macOS | `http://127.0.0.1:8080/api/v1`   | `http://127.0.0.1:8000/api/v1`   |
| Web (Chrome)          | `http://localhost:8080/api/v1`   | `http://localhost:8000/api/v1`   |

See [docs/environment-config.md](docs/environment-config.md) for full details.

### 4. Run the app

```bash
flutter run
```

Or target a specific device:

```bash
flutter run -d chrome
flutter run -d emulator-5554
```

---

## Running Tests

```bash
flutter test
```

---

## Static Analysis

```bash
flutter analyze
```

The project uses `flutter_lints` for lint rules configured in `analysis_options.yaml`.

---

## API Endpoints

All protected endpoints require an `Authorization: Bearer <token>` header. The token is obtained from login/register and stored securely.

| Action              | Method   | Auth?    | Endpoint                         |
|---------------------|----------|----------|----------------------------------|
| Register            | `POST`   | Public   | `/api/v1/auth/register`          |
| Login               | `POST`   | Public   | `/api/v1/auth/login`             |
| Get my lists        | `GET`    | Required | `/api/v1/lists/me`               |
| Create list         | `POST`   | Required | `/api/v1/lists`                  |
| Get list            | `GET`    | Required | `/api/v1/lists/{id}`             |
| Invite user         | `POST`   | Required | `/api/v1/lists/{id}/invite`      |
| Generate invite link| `POST`   | Required | `/api/v1/lists/{id}/invite-link` |
| Invite preview      | `GET`    | Public   | `/api/v1/invites/{token}`        |
| Accept invite       | `POST`   | Required | `/api/v1/invites/{token}/accept` |
| Add item            | `POST`   | Required | `/api/v1/lists/{listId}/items`   |
| Update item         | `PUT`    | Required | `/api/v1/items/{id}`             |
| Delete item         | `DELETE` | Required | `/api/v1/items/{id}`             |
| Extract receipt/price-tag (AI) | `POST` | Required | `/api/v1/receipt/extract` |
| Capture extraction summary | `POST` | Required | `/api/v1/prices/capture` |
| Confirm extracted price | `POST` | Required | `/api/v1/prices/confirm` |
| Get price history | `GET` | Required | `/api/v1/prices/history?itemName={name}` |

Full API contract: [docs/flutter-backend-integration.md](docs/flutter-backend-integration.md).

---

## Roadmap

- [x] Authentication and user login/register
- [x] Home screen loads lists owned by or shared with the user
- [x] Invite by shareable link + deep link handling
- [x] QR code invite generation and scanning
- [x] Real-time sync via WebSockets
- [x] AI-based receipt/price-tag extraction
- [x] Multi-item editable price confirmation flow
- [x] Price history view with item-name filtering
- [ ] User search / discovery for invitations
- [ ] Delete shopping lists
- [ ] Offline mode with local caching
- [ ] Push notifications for list updates
- [ ] Unit and widget test coverage

---

## Documentation

| Document                                                                 | Description                          |
|--------------------------------------------------------------------------|--------------------------------------|
| [Backend Integration Guide](docs/flutter-backend-integration.md)         | Full backend API contract            |
| [App Architecture](docs/flutter-app-architecture.md)                     | Detailed architecture documentation  |
| [Environment Config](docs/environment-config.md)                         | Switch between production and local  |
| [Copilot Instructions](.github/copilot-instructions.md)                  | Coding conventions for AI assistants |

---

## Contributing

1. Create a feature branch from `main`.
2. Follow the coding conventions in [`.github/copilot-instructions.md`](.github/copilot-instructions.md).
3. Run `flutter analyze` and `flutter test` before pushing.
4. Open a pull request with a clear description.

---

## License

This project is private and not currently published under an open-source license.
