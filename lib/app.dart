import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'providers/home_provider.dart';
import 'repositories/shopping_list_repository.dart';
import 'screens/home/home_screen.dart';

class ShareCartApp extends StatelessWidget {
  const ShareCartApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) => HomeProvider(ctx.read<ShoppingListRepository>()),
      child: MaterialApp(
        title: 'Share Cart',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          brightness: Brightness.light,
        ),
        darkTheme: ThemeData(
          colorSchemeSeed: Colors.green,
          useMaterial3: true,
          brightness: Brightness.dark,
        ),
        themeMode: ThemeMode.system,
        home: const HomeScreen(),
      ),
    );
  }
}
