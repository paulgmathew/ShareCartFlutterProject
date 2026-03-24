# JWT Auth Frontend Implementation — Share Cart Flutter

## Summary

This document describes the Flutter changes implemented to support the new JWT-based authentication backend (`/api/v1/auth/register` and `/api/v1/auth/login`) and to enforce authenticated access to list features.

Implemented outcomes:

- Register and login flows are fully integrated.
- JWT token is stored in secure storage (`flutter_secure_storage`).
- Token is attached automatically to protected API requests.
- On `403 Forbidden`, the app clears the session and redirects to login.
- Users only see the list landing page after successful authentication.

---

## New Dependencies

Added to `pubspec.yaml`:

- `flutter_secure_storage: ^9.2.2`

Reason:

- JWT must be stored in encrypted storage, not `SharedPreferences`.

---

## New Models

### `lib/models/auth_response_model.dart`

Added `AuthResponseModel` for backend auth responses:

- `token`
- `tokenType`
- `userId`
- `email`
- `name`

Also exported from `lib/models/models.dart`.

---

## New Service

### `lib/services/auth_api_service.dart`

Added `AuthApiService` with:

- `register({email, password, name})`
- `login({email, password})`

Both methods parse backend response into `AuthResponseModel`.

Also exported from `lib/services/services.dart`.

---

## New Auth Repositories

### `lib/repositories/auth_session_repository.dart`

Handles secure session persistence and in-memory session state:

- Load persisted session on app start
- Save token/user data after login/register
- Clear session on logout/unauthorized
- Expose token for authenticated requests

Storage keys:

- `auth_token`
- `auth_token_type`
- `auth_user_id`
- `auth_email`
- `auth_name`

### `lib/repositories/auth_repository.dart`

Orchestrates auth API + session repository:

- `bootstrapSession()`
- `register(...)`
- `login(...)`
- `logout()`
- `getAccessToken()`
- `handleUnauthorized()`

---

## New Provider

### `lib/providers/auth_provider.dart`

`AuthProvider` (`ChangeNotifier`) added for auth state lifecycle:

- App bootstrap state: `isBootstrapping`
- Submit/loading state: `isSubmitting`
- Auth state: `isAuthenticated`
- User context: `userId`, `email`, `name`
- Auth actions: `login`, `register`, `logout`
- Error state: `errorMessage`

---

## API Client Updates

### `lib/services/api_client.dart`

Enhanced `ApiClient` to support authenticated and unauthenticated endpoints through callbacks:

- `accessTokenProvider`: fetches JWT before each request
- `onUnauthorized`: called on `403`

Behavior implemented:

1. Request headers are built dynamically.
2. If token exists, add `Authorization: Bearer <token>`.
3. If response status is `403`, app clears session and navigates back to login.

This keeps auth handling centralized and avoids repeating header logic in every service.

---

## App Bootstrap & Dependency Injection Updates

### `lib/main.dart`

Updated startup flow:

- Initialize secure storage and auth repositories.
- Build `ApiClient` with auth token + unauthorized callbacks.
- Register providers via `MultiProvider`:
  - `AuthSessionRepository`
  - `AuthRepository`
  - `ShoppingListRepository`
  - `AuthProvider`

Also added app-level navigator key so unauthorized responses can pop routes to root before showing login.

### `lib/app.dart`

`ShareCartApp` now receives an app navigator key and uses `AuthGate` as the home screen.

---

## New Auth Screens

### `lib/screens/auth/auth_gate.dart`

Controls app entry based on auth state:

- While bootstrapping session: show loading spinner
- Not authenticated: show `LoginScreen`
- Authenticated: provide `HomeProvider` and show `HomeScreen`

### `lib/screens/auth/login_screen.dart`

Added login form with:

- Email + password validation
- Auth submission state handling
- Error display via snackbars
- Navigation to register screen

### `lib/screens/auth/register_screen.dart`

Added registration form with:

- Optional name
- Email + password validation
- Auto-login behavior after successful registration (session saved)

---

## Home Screen Updates

### `lib/screens/home/home_screen.dart`

Added authenticated user UX:

- App bar shows user name/email
- Added logout button in app bar

After logout, the app returns to login through `AuthGate`.

---

## Copilot Project Instructions Update

### `.github/copilot-instructions.md`

Updated project instructions to reflect current backend reality:

- App now uses JWT auth
- Removed outdated note saying auth/login does not exist

---

## Validation Performed

- `flutter pub get` completed successfully
- `flutter analyze` completed with **no issues found**

---

## Current Auth Flow in App

1. App starts and tries to restore session from secure storage.
2. If no token/session exists -> Login screen.
3. User can register or login.
4. On success, token is saved securely and auth state becomes authenticated.
5. App shows landing page (lists/home).
6. All protected API requests include bearer token automatically.
7. If backend returns `403`, session is cleared and user is returned to login.
