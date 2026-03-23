import 'package:flutter/material.dart';

import 'screens/auth/auth_gate.dart';

class ShareCartApp extends StatelessWidget {
  final GlobalKey<NavigatorState> appNavigatorKey;

  const ShareCartApp({super.key, required this.appNavigatorKey});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: appNavigatorKey,
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
      home: const AuthGate(),
    );
  }
}
