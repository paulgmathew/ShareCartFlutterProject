import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../providers/home_provider.dart';
import '../../repositories/shopping_list_repository.dart';
import '../../services/pending_invite_service.dart';
import '../home/home_screen.dart';
import '../invite/invite_preview_screen.dart';
import 'login_screen.dart';

class AuthGate extends StatelessWidget {
  const AuthGate({super.key});

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        if (auth.isBootstrapping) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (!auth.isAuthenticated) {
          return const LoginScreen();
        }

        // After login, consume any pending invite token and navigate to preview.
        WidgetsBinding.instance.addPostFrameCallback((_) {
          final token = context.read<PendingInviteService>().consumeToken();
          if (token != null) {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => InvitePreviewScreen(token: token),
              ),
            );
          }
        });

        return ChangeNotifierProvider(
          create: (ctx) => HomeProvider(ctx.read<ShoppingListRepository>()),
          child: const HomeScreen(),
        );
      },
    );
  }
}
