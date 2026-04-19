import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';
import '../../services/invite_api_service.dart';
import '../auth/login_screen.dart';
import '../list_detail/list_detail_screen.dart';

class InvitePreviewScreen extends StatefulWidget {
  final String token;

  const InvitePreviewScreen({super.key, required this.token});

  @override
  State<InvitePreviewScreen> createState() => _InvitePreviewScreenState();
}

class _InvitePreviewScreenState extends State<InvitePreviewScreen> {
  InvitePreviewModel? _preview;
  bool _isLoading = true;
  String? _errorMessage;
  bool _isJoining = false;

  @override
  void initState() {
    super.initState();
    _loadPreview();
  }

  Future<void> _loadPreview() async {
    try {
      final preview = await context.read<InviteApiService>().getInvitePreview(
        widget.token,
      );
      if (!mounted) return;
      setState(() {
        _preview = preview;
        _isLoading = false;
      });
    } on ApiException {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Invalid invite link';
        _isLoading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Could not load invite details';
        _isLoading = false;
      });
    }
  }

  Future<void> _joinList() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isAuthenticated) {
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
      return;
    }

    setState(() => _isJoining = true);

    try {
      final result = await context.read<InviteApiService>().acceptInvite(
        widget.token,
      );
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('You joined the list!')));
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => ListDetailScreen(listId: result.listId),
        ),
      );
    } on ApiException catch (e) {
      if (!mounted) return;
      setState(() => _isJoining = false);
      final status = e.error.status;
      if (status == 400) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('This invite link has expired')),
        );
      } else if (status == 409) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('You are already a member of this list'),
          ),
        );
        Navigator.of(context).pop();
      } else if (status == 404) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Invalid invite link')));
      } else if (status == 403) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const LoginScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Could not join the list. Please try again.'),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Join List')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: _buildBody(context),
        ),
      ),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(_errorMessage!),
          ],
        ),
      );
    }

    final preview = _preview!;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        const Spacer(),
        Icon(
          Icons.shopping_cart_outlined,
          size: 80,
          color: Theme.of(context).colorScheme.primary,
        ),
        const SizedBox(height: 24),
        Text(
          preview.listName,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        if (preview.ownerName != null) ...[
          const SizedBox(height: 8),
          Text(
            'Shared by ${preview.ownerName}',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Theme.of(context).colorScheme.outline,
            ),
          ),
        ],
        const Spacer(),
        FilledButton(
          onPressed: _isJoining ? null : _joinList,
          child:
              _isJoining
                  ? const SizedBox(
                    height: 20,
                    width: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                  : const Text('Join List'),
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}
