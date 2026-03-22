# Share Cart

A Flutter mobile application for managing shared grocery and shopping lists. Multiple users can collaborate on the same list in real time — adding items, marking them complete, and inviting members to contribute.

Share Cart connects to a [Spring Boot REST backend](docs/flutter-backend-integration.md) and is designed with a clean layered architecture that makes it easy to extend with new features.

---

## Screenshots

> _Coming soon — run the app locally with the backend to explore the UI._

---

## Features

- **Create shopping lists** with an optional owner
- **Add, edit, and delete items** — name, quantity, and category
- **Toggle item completion** with a single tap
- **Invite members** to collaborate on a list
- **View members** and their roles
- **Items grouped by category** on the detail screen
- **Swipe-to-delete** with confirmation
- **Pull-to-refresh** to sync with the backend
- **Local persistence** of known list IDs so they survive app restarts
- **Material 3** theming with automatic light/dark mode

---

## Tech Stack

| Layer              | Technology                       |
|--------------------|----------------------------------|
| Framework          | Flutter (Dart SDK ^3.7.2)        |
| State Management   | Provider (`ChangeNotifier`)      |
| HTTP Client        | `http` package                   |
| Local Storage      | `shared_preferences`             |
| Design System      | Material 3 with green color seed |
| Backend            | Spring Boot REST API             |

---

## Architecture

The project follows a strict layered architecture:

```
Screens (UI)  →  Providers (State)  →  Repository  →  API Services  →  ApiClient
```

```
lib/
├── main.dart                          # Entry point
├── app.dart                           # MaterialApp with theming
├── config/
│   └── api_config.dart                # Platform-aware base URL
├── models/
│   ├── models.dart                    # Barrel export
│   ├── shopping_list_model.dart
│   ├── item_model.dart
│   ├── member_model.dart
│   └── api_error_model.dart
├── services/
│   ├── services.dart                  # Barrel export
│   ├── api_client.dart                # HTTP client + error mapping
│   ├── shopping_list_api_service.dart
│   └── item_api_service.dart
├── repositories/
│   └── shopping_list_repository.dart  # API + local persistence
├── providers/
│   ├── home_provider.dart
│   └── list_detail_provider.dart
└── screens/
    ├── home/
    │   ├── home_screen.dart
    │   └── widgets/
    │       ├── create_list_dialog.dart
    │       └── open_list_dialog.dart
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
- The Share Cart Spring Boot backend running on port **8080**
- An Android emulator, iOS simulator, or Chrome for web

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

### 3. Start the backend

Make sure the Spring Boot backend is running at `http://localhost:8080`. The app auto-detects the correct base URL per platform:

| Platform         | Base URL                        |
|------------------|---------------------------------|
| Android emulator | `http://10.0.2.2:8080/api/v1`  |
| iOS simulator    | `http://127.0.0.1:8080/api/v1` |
| Web (Chrome)     | `http://localhost:8080/api/v1`  |

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

The app integrates with six backend endpoints:

| Action         | Method   | Endpoint                         |
|----------------|----------|----------------------------------|
| Create list    | `POST`   | `/api/v1/lists`                  |
| Get list       | `GET`    | `/api/v1/lists/{id}`             |
| Invite user    | `POST`   | `/api/v1/lists/{id}/invite`      |
| Add item       | `POST`   | `/api/v1/lists/{listId}/items`   |
| Update item    | `PUT`    | `/api/v1/items/{id}`             |
| Delete item    | `DELETE` | `/api/v1/items/{id}`             |

Full API contract: [docs/flutter-backend-integration.md](docs/flutter-backend-integration.md).

---

## Roadmap

- [ ] Authentication and user login
- [ ] User search / discovery for invitations
- [ ] Delete shopping lists
- [ ] Offline mode with local caching
- [ ] Real-time sync via WebSockets
- [ ] Push notifications for list updates
- [ ] Unit and widget test coverage

---

## Documentation

| Document                                                                 | Description                          |
|--------------------------------------------------------------------------|--------------------------------------|
| [Backend Integration Guide](docs/flutter-backend-integration.md)         | Full backend API contract            |
| [App Architecture](docs/flutter-app-architecture.md)                     | Detailed architecture documentation  |
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
