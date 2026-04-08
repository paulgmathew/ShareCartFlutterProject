# Share Cart Flutter Application Architecture

## Overview

Share Cart is a Flutter mobile application for managing shared grocery/shopping lists. It connects to a Spring Boot REST backend (documented in `flutter-backend-integration.md`) and supports creating lists, managing items, and inviting members to collaborate.

---

## Tech Stack

- **Flutter** with Dart
- **Provider** for state management
- **http** package for REST API calls
- **shared_preferences** for local persistence
- **flutter_secure_storage** for secure JWT token storage
- **web_socket_channel** for real-time WebSocket sync
- **Material 3** design system

---

## Project Structure

```
lib/
├── main.dart                          # Entry point — bootstraps dependencies
├── app.dart                           # MaterialApp with Material 3 theming
├── config/
│   └── api_config.dart                # Platform-aware base URL selection
├── models/
│   ├── models.dart                        # Barrel export
│   ├── shopping_list_model.dart           # Shopping list with items and members
│   ├── shopping_list_summary_model.dart   # Lightweight list summary
│   ├── item_model.dart                    # Shopping list item
│   ├── member_model.dart                  # List member
│   ├── auth_response_model.dart           # JWT login/register response
│   ├── list_realtime_event_model.dart     # WebSocket real-time event payload
│   └── api_error_model.dart               # Backend error response
├── services/
│   ├── services.dart                      # Barrel export
│   ├── api_client.dart                    # HTTP client with JWT headers & error mapping
│   ├── auth_api_service.dart              # Login and register API calls
│   ├── shopping_list_api_service.dart     # List and invite API calls
│   ├── item_api_service.dart              # Item CRUD API calls
│   └── realtime_sync_service.dart         # WebSocket connection for live list updates
├── repositories/
│   ├── shopping_list_repository.dart      # Combines API + local persistence
│   ├── auth_repository.dart               # Auth logic + token lifecycle
│   └── auth_session_repository.dart       # Secure token read/write (flutter_secure_storage)
├── providers/
│   ├── auth_provider.dart                 # Auth state (logged in/out, current user)
│   ├── home_provider.dart                 # State for home screen (saved lists)
│   └── list_detail_provider.dart          # State for list detail screen
└── screens/
    ├── auth/
    │   ├── auth_gate.dart                 # Redirects to login or home based on auth state
    │   ├── login_screen.dart              # Login form
    │   └── register_screen.dart           # Registration form
    ├── home/
    │   ├── home_screen.dart               # Main screen with list of saved lists
    │   └── widgets/
    │       ├── create_list_dialog.dart    # Dialog to create a new shopping list
    │       └── open_list_dialog.dart      # Dialog to open a list by ID
    └── list_detail/
        ├── list_detail_screen.dart        # Shows items and actions for a list
        └── widgets/
            ├── item_tile.dart             # Single item row with checkbox and swipe
            ├── add_item_sheet.dart        # Bottom sheet for add and edit item
            ├── invite_member_sheet.dart   # Bottom sheet to invite a user
            └── members_sheet.dart         # Bottom sheet showing current members
```

---

## Layered Architecture

```
┌─────────────────────────────┐
│          Screens (UI)       │   Flutter widgets, user interaction
├─────────────────────────────┤
│        Providers (State)    │   ChangeNotifier classes via Provider
├─────────────────────────────┤
│       Repository            │   Combines API calls + local storage
├─────────────────────────────┤
│      API Services           │   One service per backend module
├─────────────────────────────┤
│       API Client            │   Single HTTP client, error handling
└─────────────────────────────┘
```

Each layer only depends on the layer directly below it. This separation makes it straightforward to:

- Swap the HTTP client or add interceptors without touching UI code
- Add caching or offline support at the repository layer
- Test providers with mock repositories

---

## Dependency Injection

Dependencies are wired up in `main.dart` and provided down the widget tree using Provider:

1. `SharedPreferences`, `FlutterSecureStorage`, `ApiClient`, API services, repositories, and providers are created in `main()`.
2. At the root, `MultiProvider` provides: `AuthSessionRepository` (as `ChangeNotifierProvider`), `AuthRepository`, `ShoppingListRepository`, `RealtimeSyncService`, and `AuthProvider`.
3. `AuthGate` at the root listens to `AuthProvider` — shows a splash while bootstrapping, redirects to `LoginScreen` if unauthenticated, or creates `HomeProvider` and renders `HomeScreen` if authenticated.
4. `ListDetailProvider` is scoped to each `ListDetailScreen` instance.

---

## Data Models

| Model                        | Purpose                                               |
|------------------------------|-------------------------------------------------------|
| `ShoppingListModel`          | Full list with nested items and members                |
| `ShoppingListSummaryModel`   | Lightweight list summary (id, name, counts)            |
| `ItemModel`                  | A single item in a shopping list                       |
| `MemberModel`                | A user who is a member of a list                       |
| `AuthResponseModel`          | JWT access/refresh tokens from login or register       |
| `ListRealtimeEventModel`     | WebSocket event payload for live list updates          |
| `ApiErrorModel`              | Structured error response from the backend             |

All models include `fromJson` factory constructors and `toJson` methods. `ItemModel` also has a `copyWith` method for immutable updates.

---

## API Client

`ApiClient` wraps the `http` package and provides:

- `get`, `post`, `put`, `delete` methods returning parsed JSON
- Automatic `Content-Type`, `Accept`, and `Authorization: Bearer <token>` headers
- Token injection via an `accessTokenProvider` callback
- Automatic redirect to login on `401` via an `onUnauthorized` callback
- Centralized error handling — backend error JSON is parsed into `ApiErrorModel` and thrown as `ApiException`
- Connection timeout via `ApiConfig.connectionTimeout`

---

## Platform-Aware Base URL

`ApiConfig.baseUrl` automatically selects the correct backend address:

| Platform           | Base URL                          |
|--------------------|-----------------------------------|
| Android emulator   | `http://10.0.2.2:8080/api/v1`    |
| iOS simulator      | `http://127.0.0.1:8080/api/v1`   |
| Flutter web        | `http://localhost:8080/api/v1`    |
| Physical device    | Requires manual IP configuration  |

---

## API Coverage

All backend endpoints are implemented:

| Action              | Method   | Endpoint                        | Service                      |
|---------------------|----------|----------------------------------|------------------------------|
| Register            | `POST`   | `/auth/register`                | `AuthApiService`             |
| Login               | `POST`   | `/auth/login`                   | `AuthApiService`             |
| Get my lists        | `GET`    | `/lists/me`                     | `ShoppingListApiService`     |
| Create list         | `POST`   | `/lists`                        | `ShoppingListApiService`     |
| Get list by ID      | `GET`    | `/lists/{id}`                   | `ShoppingListApiService`     |
| Invite user         | `POST`   | `/lists/{id}/invite`            | `ShoppingListApiService`     |
| Add item            | `POST`   | `/lists/{listId}/items`         | `ItemApiService`             |
| Update item         | `PUT`    | `/items/{id}`                   | `ItemApiService`             |
| Delete item         | `DELETE` | `/items/{id}`                   | `ItemApiService`             |

---

## Local Persistence

`SharedPreferences` is initialised in `main()` and injected into `ShoppingListRepository`, but the home screen no longer depends on locally stored list IDs. The home screen is populated by calling `GET /lists/me`, which returns all lists the authenticated user belongs to. `SharedPreferences` is available in the repository for future use (e.g. caching).

---

## State Management

### AuthProvider

- Manages the authenticated user state (logged in / logged out)
- Exposes `login`, `register`, and `logout` actions
- On app start, restores session from `flutter_secure_storage`
- On `401`, clears tokens and navigates to login via the global navigator key

### HomeProvider

- On construction, fetches the user's lists from the backend via `GET /lists/me`
- Handles create-list and open-by-ID flows
- Exposes `refresh()` to reload lists from the backend

### ListDetailProvider

- Scoped to a single list detail screen
- Provides methods for add, update, toggle-complete, and delete item
- Provides invite-member functionality
- Refreshes the full list from the backend after each write operation
- Connects to `RealtimeSyncService` to receive live WebSocket updates

---

## UI Screens

### Auth Gate

- Entry point after `MaterialApp` — checks if the user has a valid JWT session
- Redirects to `LoginScreen` if unauthenticated, or `HomeScreen` if authenticated

### Login Screen

- Email and password form
- Links to `RegisterScreen`
- On success, stores JWT and navigates to home

### Register Screen

- Username, email, and password form
- On success, stores JWT and navigates to home

### Home Screen

- Displays saved shopping lists as cards with item and member counts
- Pull-to-refresh reloads all lists from the backend
- FABs for creating a new list or opening an existing list by ID
- Swipe or tap the remove icon to remove a list from local view

### List Detail Screen

- Shows items grouped by category
- Checkbox to toggle item completion
- Swipe-to-delete with confirmation dialog
- Edit button on each item opens the add/edit bottom sheet
- App bar actions: view members, invite member, refresh
- FAB to add a new item

---

## Theming

- Material 3 with `Colors.green` as the seed color
- Light and dark themes generated from the seed
- System theme mode — follows device setting

---

## Error Handling

Backend errors follow a consistent JSON format. The app maps HTTP status codes to user-facing behavior:

| Status | Meaning                          | App Behavior                        |
|--------|----------------------------------|--------------------------------------|
| 400    | Validation error                 | Show field-level error message       |
| 404    | Resource not found               | Show "not found" message             |
| 409    | Conflict (e.g. duplicate member) | Show business-rule conflict message  |
| 500    | Server error                     | Show generic error message           |

---

## Running The App

1. Start the Spring Boot backend on port 8080.
2. Run the Flutter app:

```bash
flutter run
```

The app auto-detects the platform and uses the appropriate base URL to reach the backend.

---

## Future Extensibility

The architecture is designed to accommodate future features:

- **New API endpoints**: Add methods to existing services or create new service classes.
- **Offline support**: Add caching logic in the repository layer.
- **Additional screens**: Create new screen folders under `lib/screens/` with scoped providers.
- **Navigation**: Replace simple `Navigator.push` with named routes or a router package when the app grows.
- **Push notifications**: Hook into the existing real-time event model for background list updates.
