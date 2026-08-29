import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../services/api_client.dart';

class VerifyEmailScreen extends StatefulWidget {
  final String? email;
  final String? token;

  const VerifyEmailScreen({super.key, this.email, this.token});

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _tokenController = TextEditingController();

  @override
  void initState() {
    super.initState();
    if (widget.email != null && widget.email!.isNotEmpty) {
      _emailController.text = widget.email!;
    }
    if (widget.token != null && widget.token!.isNotEmpty) {
      _tokenController.text = widget.token!;
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _verifyEmail() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      _showBanner('Verification token is required.');
      return;
    }

    try {
      await context.read<AuthProvider>().verifyEmail(token);
      if (!mounted) return;
      _showBanner(
        context.read<AuthProvider>().successMessage ??
            'Email verified successfully.',
        isSuccess: true,
      );
    } on ApiException catch (_) {
      if (!mounted) return;
      _showBanner(
        context.read<AuthProvider>().errorMessage ?? 'Could not verify email.',
      );
    }
  }

  Future<void> _resendVerification() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showBanner('Enter a valid email address to resend verification.');
      return;
    }

    try {
      await context.read<AuthProvider>().resendVerification(email);
      if (!mounted) return;
      _showBanner(
        context.read<AuthProvider>().successMessage ??
            'Verification email sent. Please check your inbox.',
        isSuccess: true,
      );
    } on ApiException catch (_) {
      if (!mounted) return;
      _showBanner(
        context.read<AuthProvider>().errorMessage ??
            'Could not resend verification email.',
      );
    }
  }

  void _showBanner(String message, {bool isSuccess = false}) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isSuccess ? Colors.green : null,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Verify Email')),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Consumer<AuthProvider>(
                builder: (context, auth, _) {
                  return Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Check your inbox for the verification link.',
                          style: Theme.of(context).textTheme.bodyLarge,
                        ),
                        const SizedBox(height: 24),
                        TextFormField(
                          controller: _emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Email is required';
                            }
                            if (!value.contains('@')) {
                              return 'Enter a valid email';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _tokenController,
                          decoration: const InputDecoration(
                            labelText: 'Verification Token',
                            border: OutlineInputBorder(),
                          ),
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) {
                              return 'Verification token is required';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 24),
                        FilledButton(
                          onPressed: auth.isSubmitting ? null : _verifyEmail,
                          child:
                              auth.isSubmitting
                                  ? const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                  : const Text('Verify Email'),
                        ),
                        const SizedBox(height: 12),
                        OutlinedButton(
                          onPressed:
                              auth.isSubmitting ? null : _resendVerification,
                          child: const Text('Resend Verification Email'),
                        ),
                        const SizedBox(height: 12),
                        TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: const Text('Back to Login'),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
  }
}
