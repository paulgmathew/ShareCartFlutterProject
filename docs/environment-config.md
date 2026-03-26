# Environment Configuration

## Overview

All backend connection settings are controlled by a single file:

```
lib/config/api_config.dart
```

The app supports two environments:

| Environment | Backend |
|---|---|
| **Production** | `https://sharecartspringbootproject.onrender.com/api/v1` (Render) |
| **Local** | Auto-detected per platform (see table below) |

---

## Switching Environments

Open `lib/config/api_config.dart` and change the `useProductionServer` flag:

```dart
// Connect to the deployed Render backend
static const bool useProductionServer = true;

// Connect to your local Spring Boot instance
static const bool useProductionServer = false;
```

That is the **only change needed** — no other files need to be touched.

---

## Local URL Auto-Detection

When `useProductionServer = false`, the app automatically picks the correct localhost URL for the platform it is running on:

| Platform             | Base URL                         | Why                                              |
|----------------------|----------------------------------|--------------------------------------------------|
| Android emulator     | `http://10.0.2.2:8080/api/v1`   | `10.0.2.2` is the emulator's alias for host `localhost` |
| iOS simulator / macOS | `http://127.0.0.1:8080/api/v1` | Direct loopback                                   |
| Web (Chrome)         | `http://localhost:8080/api/v1`   | Standard loopback                                 |

---

## Production Server

The production backend is hosted on **Render** (free tier):

```
https://sharecartspringbootproject.onrender.com/api/v1
```

> **Note:** Render's free tier spins down after inactivity. The first request after a cold start may take 30–60 seconds. The app timeout is set to 30 seconds to accommodate this.

---

## Timeouts

| Setting            | Value |
|--------------------|-------|
| Connection timeout | 30 s  |
| Receive timeout    | 30 s  |

These are defined as constants in `ApiConfig` alongside the URL.

---

## Adding a New Environment

To add a staging environment, extend `ApiConfig` as follows:

```dart
enum AppEnvironment { production, staging, local }

static const AppEnvironment environment = AppEnvironment.production;

static String get baseUrl {
  switch (environment) {
    case AppEnvironment.production:
      return 'https://sharecartspringbootproject.onrender.com/api/v1';
    case AppEnvironment.staging:
      return 'https://staging.your-domain.com/api/v1';
    case AppEnvironment.local:
      return _localBaseUrl;
  }
}
```
