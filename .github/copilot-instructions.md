# Copilot Instructions — Share Cart Flutter App

## Project Overview

Share Cart is a Flutter mobile application for managing shared grocery/shopping lists.
It connects to a Spring Boot REST backend over HTTP using JWT authentication.
The backend API contract is documented in `docs/flutter-backend-integration.md`.

## Tech Stack

- Flutter (Dart SDK ^3.7.2)
- Provider for state management
- `http` package for REST calls
- `shared_preferences` for local persistence
- Material 3 (Material Design 3) with `Colors.green` seed

## Architecture

The codebase follows a strict **layered architecture**:

```
Screens (UI)  →  Providers (State)  →  Repository  →  API Services  →  ApiClient
```

- **Screens** (`lib/screens/`): Flutter widgets. Each screen has its own folder with a main screen file and a `widgets/` subfolder for extracted widgets.
- **Providers** (`lib/providers/`): `ChangeNotifier` classes consumed via `Provider`. Each provider is scoped to one screen or feature.
- **Repositories** (`lib/repositories/`): Combine API service calls with local storage. The single source of truth for data operations.
- **Services** (`lib/services/`): Thin wrappers around `ApiClient` — one service per backend module (`ShoppingListApiService`, `ItemApiService`).
- **ApiClient** (`lib/services/api_client.dart`): Single HTTP client handling JSON serialization, headers, timeouts, and error mapping.
- **Models** (`lib/models/`): Immutable data classes with `fromJson`/`toJson`. Use `copyWith` when available for immutable updates.
- **Config** (`lib/config/`): App-level configuration such as platform-aware base URLs.

## Coding Conventions

### General

- Use Dart's null-safety fully — no `!` force-unwrap unless the value is provably non-null.
- Prefer `const` constructors wherever possible.
- Use named parameters for constructors with more than two parameters.
- Keep widgets small and focused. Extract into the `widgets/` subfolder when a widget exceeds ~80 lines or is reusable.
- Use barrel files (e.g., `models.dart`, `services.dart`) for clean exports. Import the barrel, not individual files, from outside the module.

### Naming

- Files: `snake_case.dart`
- Classes: `PascalCase`
- Variables, methods, parameters: `camelCase`
- Private members: prefix with `_`
- Models: suffix with `Model` (e.g., `ItemModel`)
- Providers: suffix with `Provider` (e.g., `ListDetailProvider`)
- API services: suffix with `ApiService` (e.g., `ItemApiService`)

### State Management

- Use `ChangeNotifier` + `Provider` for state.
- Providers expose data via getters and actions via `Future` methods.
- Providers handle `ApiException` and surface error messages via a `String? errorMessage` getter.
- After write operations, refresh state by re-fetching from the backend (`GET /lists/{id}`).
- Never call `notifyListeners()` after `dispose()`.

### API Layer

- All HTTP calls go through `ApiClient`. Do not use `http.get/post` directly anywhere else.
- API services accept primitive parameters (not request-body models) for simplicity.
- Build request body maps inside service methods; only include non-null fields.
- Backend errors are parsed into `ApiErrorModel` and thrown as `ApiException`.
- All IDs are UUID `String` values — do not use `int` IDs.
- Timestamps are ISO 8601 strings parsed with `DateTime.parse()`.

### Error Handling

- Catch `ApiException` at the provider or UI layer — never swallow errors silently.
- Map HTTP status codes to user-facing behavior:
  - `400` → validation / input error
  - `404` → resource not found
  - `409` → business conflict (e.g., duplicate member)
  - `500` → unexpected server error

### UI

- Use Material 3 widgets (`FilledButton`, `Card`, etc.).
- Use `Consumer` or `context.watch` for reactive rebuilds, `context.read` for one-shot actions.
- Bottom sheets (`showModalBottomSheet`) for add/edit/invite forms.
- Dialogs (`showDialog`) for confirmations and simple inputs.
- Use `RefreshIndicator` for pull-to-refresh on list views.
- Pad bottom of scrollable lists to avoid FAB overlap (`EdgeInsets.only(bottom: 80)`).

### Local Storage

- `SharedPreferences` is used to persist known shopping list IDs (key: `saved_list_ids`).
- There is no backend endpoint to discover all lists, so local storage is essential for the home screen.

## Backend API Reference (Quick)

| Action         | Method   | Endpoint                   |
|----------------|----------|----------------------------|
| Create list    | `POST`   | `/api/v1/lists`            |
| Get list       | `GET`    | `/api/v1/lists/{id}`       |
| Invite user    | `POST`   | `/api/v1/lists/{id}/invite`|
| Add item       | `POST`   | `/api/v1/lists/{listId}/items` |
| Update item    | `PUT`    | `/api/v1/items/{id}`       |
| Delete item    | `DELETE` | `/api/v1/items/{id}`       |

Base URL is auto-detected per platform in `ApiConfig`.

## What Does NOT Exist Yet

- `GET /lists` (fetch all lists)
- `GET /items/{id}` (fetch single item)
- `DELETE /lists/{id}` (delete a list)
- User search or discovery

Do not generate code that assumes these exist unless the user explicitly says they have been added.

## Adding New Features — Checklist

1. **Model**: Add a Dart model in `lib/models/` with `fromJson`/`toJson`. Export it from `models.dart`.
2. **Service**: Add API methods to the relevant service in `lib/services/`, or create a new service. Export it from `services.dart`.
3. **Repository**: Add pass-through or orchestration methods in the repository.
4. **Provider**: Add state + actions in an existing or new `ChangeNotifier` in `lib/providers/`.
5. **Screen**: Create a folder under `lib/screens/` with a screen widget and a `widgets/` subfolder.
6. **Wire up**: Provide the new `ChangeNotifier` via `ChangeNotifierProvider` at the appropriate scope.

## Testing

- Unit tests go in `test/` mirroring the `lib/` structure.
- Use `flutter test` to run.
- Mock `ApiClient` or repository when testing providers.
