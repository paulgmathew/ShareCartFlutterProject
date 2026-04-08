import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'providers/auth_provider.dart';
import 'repositories/auth_repository.dart';
import 'repositories/auth_session_repository.dart';
import 'repositories/shopping_list_repository.dart';
import 'services/api_client.dart';
import 'services/auth_api_service.dart';
import 'services/item_api_service.dart';
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
