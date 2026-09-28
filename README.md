# OPA Admin (`opa_admin`)

An embeddable, enterprise-ready Flutter package for managing Open Policy Agent (OPA) permissions, policies, conditions, and custom rules.

This package is designed as a **Micro-Frontend / Feature Module**:
* It **does not** contain login or signup screens.
* The host (parent) application manages user authentication and passes its active JWT access token to the package via a provider callback.
* Dependency injection and styling are completely isolated, ensuring zero conflicts with the parent app's existing dependencies or theme.

---

## What You Need to Know Before Starting

1. **Authentication (JWT)**: Your application handles login. You only need to pass a callback `getAccessToken: () async => '...'` that returns the user's active token.
2. **Theme Isolation**: Package screens are self-contained and enforce their own theme. Your parent app's theme will not be affected, nor will it break the package's UI.
3. **Dependency Injection**: The package uses an internal, isolated `GetIt` container. It will not collide with your app's `GetIt.instance` registrations.
4. **Localization**: The package includes English (`en`), Spanish (`es`), and Arabic (`ar`) translations. You simply plug its localization delegate into your `MaterialApp`.

---

## Step-by-Step Integration Guide

### Step 1: Add Dependency to `pubspec.yaml`

In your parent application's `pubspec.yaml`, add `opa_admin`:

#### Option A: Via Git (Recommended for teams)
```yaml
dependencies:
  flutter:
    sdk: flutter
  opa_admin:
    git:
      url: https://github.com/binshad-dm/opa_admin.git
      ref: master # or specific tag/branch
```

#### Option B: Via Local Path (For local development)
```yaml
dependencies:
  flutter:
    sdk: flutter
  opa_admin:
    path: ../opa_admin # Path to the package folder
```

Then run in your terminal:
```bash
flutter pub get
```

---

### Step 2: Initialize `OpaAdmin`

Initialize the package once before loading any of its views—typically in `main.dart` or right after the user successfully logs into your app:

```dart
import 'package:flutter/material.dart';
import 'package:opa_admin/opa_admin.dart';

Future<void> setupOpaAdmin() async {
  await OpaAdmin.initialize(
    config: OpaConfig(
      // 1. The backend API base URL for OPA Admin services
      baseUrl: 'https://api.yourdomain.com',

      // 2. Callback to fetch current JWT token from your app's auth storage
      getAccessToken: () async {
        return await myAuthStorage.readAccessToken();
      },

      // 3. (Optional) Callback to refresh the token on 401 Unauthorized
      onRefreshToken: () async {
        return await myAuthService.refreshToken();
      },

      // 4. (Optional) Callback invoked when the session is expired/unauthorized
      onSessionExpired: () {
        // e.g., redirect user to your app's login screen
        myNavigatorKey.currentState?.pushReplacementNamed('/login');
      },
    ),
  );
}
```

---

### Step 3: Register Localization Delegates in `MaterialApp`

To enable translation strings for buttons, dialogs, and tables in `opa_admin`, add `AppLocalizations.delegate` to your `MaterialApp`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opa_admin/opa_admin.dart';

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Parent App',
      // Pass your app's active locale
      locale: const Locale('en'), 
      localizationsDelegates: const [
        // Standard Flutter delegates
        ...GlobalMaterialLocalizations.delegates,
        // OPA Admin localization delegate
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HomeScreen(),
    );
  }
}
```

---

### Step 4: Open OPA Admin Screens

Navigate to the policy dashboard just like any regular Flutter widget:

```dart
import 'package:flutter/material.dart';
import 'package:opa_admin/opa_admin.dart';

class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Admin Console')),
      body: Center(
        child: ElevatedButton.icon(
          icon: const Icon(Icons.security),
          label: const Text('Manage Policies & Permissions'),
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => const PolicyDashboardView(),
              ),
            );
          },
        ),
      ),
    );
  }
}
```

---

### Step 5: Clean Up on User Logout

When the user logs out of your application, call `OpaAdmin.reset()` to clear any cached policies, states, and HTTP clients:

```dart
import 'package:opa_admin/opa_admin.dart';

Future<void> performUserLogout() async {
  // Clear parent app session
  await myAuthStorage.clear();

  // Reset OPA Admin state and memory cache
  await OpaAdmin.reset();

  // Navigate to login
  myNavigatorKey.currentState?.pushReplacementNamed('/login');
}
```

---

## Configuration Reference (`OpaConfig`)

| Property | Type | Required | Description |
| :--- | :--- | :--- | :--- |
| `baseUrl` | `String` | **Yes** | The base URL of the OPA backend service (e.g. `https://api.example.com`). |
| `getAccessToken` | `Future<String?> Function()` | **Yes** | Async callback that returns the active user JWT bearer token. |
| `onRefreshToken` | `Future<String?> Function()?` | No | Async callback triggered on `401 Unauthorized` to refresh and return a new token. |
| `onSessionExpired` | `void Function()?` | No | Callback invoked if token refresh fails or session is completely expired. |

---

## Full Working Example (`main.dart` in Parent App)

```dart
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:opa_admin/opa_admin.dart';

final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // 1. Initialize OPA Admin with your app's auth
  await OpaAdmin.initialize(
    config: OpaConfig(
      baseUrl: 'https://api.yourdomain.com',
      getAccessToken: () async {
        // Return active JWT token
        return 'ey...';
      },
      onRefreshToken: () async {
        // Return fresh token if refresh succeeds
        return 'ey...new';
      },
      onSessionExpired: () {
        navigatorKey.currentState?.pushReplacementNamed('/login');
      },
    ),
  );

  runApp(const HostApplication());
}

class HostApplication extends StatelessWidget {
  const HostApplication({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      localizationsDelegates: const [
        ...GlobalMaterialLocalizations.delegates,
        AppLocalizations.delegate,
      ],
      supportedLocales: AppLocalizations.supportedLocales,
      home: const HostHomePage(),
    );
  }
}

class HostHomePage extends StatelessWidget {
  const HostHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Host App')),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => const PolicyDashboardView()),
            );
          },
          child: const Text('Open Policy Dashboard'),
        ),
      ),
    );
  }
}
```

---

## Frequently Asked Questions (FAQ)

#### Q: Do I need to wrap `PolicyDashboardView` with my app's theme?
**No.** `PolicyDashboardView` is wrapped in its own self-contained theme (`AppTheme.dentalTheme`) internally. It renders identically and reliably regardless of the parent app's theme.

#### Q: Will this clash if my app also uses `GetIt` or `Dio`?
**No.** `opa_admin` creates a completely private, isolated `GetIt` instance (`GetIt.asNewInstance()`). It will not conflict with your app's global `GetIt.instance` or any registered dependencies.

#### Q: How do I switch languages?
When your host app changes its active `locale` in `MaterialApp`, all strings inside `opa_admin` update automatically based on the registered `AppLocalizations.delegate`.
