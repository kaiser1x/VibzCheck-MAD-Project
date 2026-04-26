import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../config/app_colors.dart';
import '../../providers/auth_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _ctrl = TextEditingController();
  bool _sent = false;

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final email = _ctrl.text.trim();
    if (!email.contains('@')) return;
    final ok =
        await context.read<AuthProvider>().sendPasswordReset(email);
    if (!mounted) return;
    if (ok) setState(() => _sent = true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Reset Password')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: _sent
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.mark_email_read_outlined,
                      size: 64, color: AppColors.primary),
                  const SizedBox(height: 20),
                  const Text('Check your email',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 12),
                  const Text(
                    'We sent a password reset link. Check your inbox and follow the instructions.',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: () => context.go('/'),
                    child: const Text('Back to Sign In'),
                  ),
                ],
              )
            : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Forgot your password?',
                      style: TextStyle(
                          fontSize: 20, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  const Text(
                    'Enter your email and we\'ll send you a reset link.',
                    style: TextStyle(color: AppColors.onSurfaceMuted),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _ctrl,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      hintText: 'Email address',
                      prefixIcon: Icon(Icons.email_outlined),
                    ),
                  ),
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _submit,
                    child: const Text('Send Reset Link'),
                  ),
                ],
              ),
      ),
    );
  }
}
