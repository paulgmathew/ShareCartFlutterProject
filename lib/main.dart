import 'package:app_links/app_links.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/auth_session_repository.dart';
import 'repositories/shopping_list_repository.dart';
import 'screens/invite/invite_preview_screen.dart';
import 'services/api_client.dart';
import 'services/auth_api_service.dart';
import 'services/item_api_service.dart';
import 'services/invite_api_service.dart';
import 'services/pending_invite_service.dart';
import 'services/price_api_service.dart';
import 'services/realtime_sync_service.dart';
import 'services/shopping_list_api_service.dart';
import 'config/api_config.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final appNavigatorKey = GlobalKey<NavigatorState>();

  final prefs = await SharedPreferences.getInstance();
  const secureStorage = FlutterSecureStorage();
  final authSessionRepository = AuthSessionRepository(secureStorage);

  late final AuthRepository authRepository;
  final apiClient = ApiClient(
    accessTokenProvider: () async => authRepository.getAccessToken(),
    onUnauthorized: () async {
      await authRepository.handleUnauthorized();
      appNavigatorKey.currentState?.popUntil((route) => route.isFirst);
    },
  );

  final authApiService = AuthApiService(apiClient);
  final listService = ShoppingListApiService(apiClient);
  final itemService = ItemApiService(apiClient);
  final inviteService = InviteApiService(apiClient);
  final priceService = PriceApiService(apiClient);
  final pendingInviteService = PendingInviteService();

  void handleIncomingLink(Uri uri) {
    final segments = uri.pathSegments;
    if (uri.host == 'sharecart.app' &&
        segments.length >= 2 &&
        segments[0] == 'invite') {
      final token = segments.last;
      if (authRepository.isAuthenticated) {
        appNavigatorKey.currentState?.push(
          MaterialPageRoute(builder: (_) => InvitePreviewScreen(token: token)),
        );
      } else {
        pendingInviteService.setToken(token);
      }
    }
  }

  // Handle deep link on cold start
  final appLinks = AppLinks();
  final initialLink = await appLinks.getInitialLink();
  if (initialLink != null) handleIncomingLink(initialLink);

  // Handle deep links while the app is running
  appLinks.uriLinkStream.listen(handleIncomingLink);

  authRepository = AuthRepository(
    authApiService: authApiService,
    sessionRepository: authSessionRepository,
  );

  final repository = ShoppingListRepository(
    listService: listService,
    itemService: itemService,
    prefs: prefs,
  );

  final realtimeSyncService = RealtimeSyncService(
    wsUrl: ApiConfig.webSocketUrl,
    accessTokenProvider: () async => authRepository.getAccessToken(),
  );

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider<AuthSessionRepository>.value(
          value: authSessionRepository,
        ),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ShoppingListRepository>.value(value: repository),
        Provider<InviteApiService>.value(value: inviteService),
        Provider<PriceApiService>.value(value: priceService),
        Provider<PendingInviteService>.value(value: pendingInviteService),
        Provider<RealtimeSyncService>.value(value: realtimeSyncService),
        ChangeNotifierProvider(
          create:
              (ctx) => AuthProvider(
                authRepository: ctx.read<AuthRepository>(),
                sessionRepository: ctx.read<AuthSessionRepository>(),
              ),
        ),
      ],
      child: ShareCartApp(appNavigatorKey: appNavigatorKey),
    ),
  );
}
