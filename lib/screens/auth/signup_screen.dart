// path: lib/screens/auth/signup_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_shell.dart';
import '../customer/customer_shell.dart';
import '../vendor/application/vendor_application_screen.dart';
import 'role_select_screen.dart';

class SignupScreen extends StatefulWidget {
  final UserRole role;
  const SignupScreen({super.key, required this.role});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _submit() async {
    if (_nameController.text.trim().isEmpty ||
        _emailController.text.trim().isEmpty ||
        _passwordController.text.length < 8) {
      await AppDialogs.showMessage(
        context,
        'Please fill in every field (password needs 8+ characters).',
        isError: true,
      );
      return;
    }

    final auth = context.read<AuthProvider>();
    final ok = await auth.signup(
      email: _emailController.text.trim(),
      password: _passwordController.text,
      fullName: _nameController.text.trim(),
      role: widget.role,
    );
    if (!mounted) return;

    if (!ok) {
      await AppDialogs.showMessage(context, auth.error ?? 'Could not create your account.', isError: true);
      return;
    }

    // If the Supabase project requires email confirmation, there's no
    // session yet — send them back to sign in after confirming.
    if (Supabase.instance.client.auth.currentSession == null) {
      await AppDialogs.showMessage(
        context,
        'Account created! Check your email to confirm, then log in.',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
        (route) => false,
      );
      return;
    }

    if (widget.role == UserRole.vendor) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VendorApplicationScreen()),
        (route) => false,
      );
    } else if (widget.role == UserRole.admin) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AdminShell()),
        (route) => false,
      );
    } else {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const CustomerShell()),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      appBar: AppBar(
  title: const Text('Create Account'),
),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (widget.role == UserRole.vendor)
              Container(
                padding: const EdgeInsets.all(14),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: AppColors.surfaceRaised,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.neonDim),
                ),
                child: Row(
                  children: const [
                    Icon(Icons.info_outline, color: AppColors.neon, size: 18),
                    SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Vendor accounts require admin approval before you can go LIVE.',
                        style: TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ),
                  ],
                ),
              ),
            const Text('Full name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(controller: _nameController),
            const SizedBox(height: 18),
            const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(controller: _emailController, keyboardType: TextInputType.emailAddress),
            const SizedBox(height: 18),
            const Text('Password', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(controller: _passwordController, obscureText: true),
            const SizedBox(height: 4),
            const Text('At least 8 characters.',
                style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
            const SizedBox(height: 22),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                      )
                    : Text(widget.role == UserRole.vendor
                        ? 'CONTINUE TO APPLICATION'
                        : 'CREATE ACCOUNT'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}