import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'repositories/shopping_list_repository.dart';
import 'services/api_client.dart';
import 'services/item_api_service.dart';
import 'services/shopping_list_api_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final prefs = await SharedPreferences.getInstance();
  final apiClient = ApiClient();
  final listService = ShoppingListApiService(apiClient);
  final itemService = ItemApiService(apiClient);

  final repository = ShoppingListRepository(
    listService: listService,
    itemService: itemService,
    prefs: prefs,
  );

  runApp(
    Provider<ShoppingListRepository>.value(
      value: repository,
      child: const ShareCartApp(),
    ),
  );
}
