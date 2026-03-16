import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../data/services/auth_service.dart';
import '../../theme/app_theme.dart';

class VerifyEmailSentScreen extends StatelessWidget {
  final String? email;
  const VerifyEmailSentScreen({super.key, this.email});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 96,
                height: 96,
                decoration: BoxDecoration(
                  color: AppTheme.successColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: const Icon(Icons.mark_email_read_outlined,
                    color: AppTheme.successColor, size: 48),
              ).animate().fadeIn().scale(begin: const Offset(0.8, 0.8)),
              const SizedBox(height: 32),
              Text('Check Your Email',
                  style: Theme.of(context)
                      .textTheme
                      .headlineMedium
                      ?.copyWith(fontWeight: FontWeight.bold))
                  .animate().fadeIn(delay: 100.ms),
              const SizedBox(height: 12),
              Text(
                email != null
                    ? 'We sent a verification link to\n$email'
                    : 'We sent a verification link to your email',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ).animate().fadeIn(delay: 150.ms),
              const SizedBox(height: 40),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => context.go('/signin'),
                  child: const Text('Go to Sign In'),
                ),
              ).animate().fadeIn(delay: 200.ms),
              const SizedBox(height: 12),
              TextButton(
                onPressed: () async {
                  if (email != null) {
                    try {
                      await context.read<AuthService>().resendVerification(email!);
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Verification email resent')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Failed: $e')),
                        );
                      }
                    }
                  }
                },
                child: const Text('Resend Email',
                    style: TextStyle(color: AppTheme.primaryColor)),
              ).animate().fadeIn(delay: 250.ms),
            ],
          ),
        ),
      ),
    );
  }
}
