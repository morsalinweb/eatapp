import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../models/models.dart';
import '../../providers/auth_provider.dart';
import '../admin/admin_shell.dart';
import '../customer/customer_shell.dart';
import '../vendor/vendor_shell.dart';
import '../vendor/application/vendor_application_screen.dart';
import '../vendor/application/application_pending_screen.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  final UserRole role;

  const LoginScreen({
    super.key,
    required this.role,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  String get _roleLabel {
    switch (widget.role) {
      case UserRole.customer:
        return 'Customer';
      case UserRole.vendor:
        return 'Vendor';
      case UserRole.admin:
        return 'Admin';
    }
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();

    final ok = await auth.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );

    if (!mounted) return;

    if (!ok) {
      await AppDialogs.showMessage(
        context,
        auth.error ?? 'Login failed. Please try again.',
        isError: true,
      );
      return;
    }

    final user = auth.currentUser!;

    if (user.role != widget.role) {
      // The account exists but is registered under a different role than
      // the tab they logged in from — route by the real role rather
      // than silently forcing the wrong shell.
      await AppDialogs.showMessage(
        context,
        'This account is registered as ${user.role.name}. Signing you in there.',
      );
    }

    if (!mounted) return;

    switch (user.role) {
      case UserRole.customer:
        _replaceWith(const CustomerShell());
        break;

      case UserRole.admin:
        _replaceWith(const AdminShell());
        break;

      case UserRole.vendor:
        final status = auth.vendorApplicationStatus;

        if (status == VendorStatus.approved) {
          _replaceWith(const VendorShell());
        } else if (status == VendorStatus.pending) {
          _replaceWith(const ApplicationPendingScreen());
        } else {
          _replaceWith(const VendorApplicationScreen());
        }
        break;
    }
  }

  void _replaceWith(Widget screen) {
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(
        builder: (_) => screen,
      ),
      (route) => false,
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      appBar: AppBar(
        title: Text('$_roleLabel Login'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 8),

            Text(
              'Welcome back',
              style: Theme.of(context)
                  .textTheme
                  .headlineSmall
                  ?.copyWith(
                    fontWeight: FontWeight.w800,
                  ),
            ),

            const SizedBox(height: 6),

            const Text(
              'Sign in to continue exploring the local food scene.',
              style: TextStyle(
                color: AppColors.textSecondary,
              ),
            ),

            const SizedBox(height: 28),

            const Text(
              'Email',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              decoration: const InputDecoration(
                hintText: 'you@example.com',
              ),
            ),

            const SizedBox(height: 18),

            const Text(
              'Password',
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 8),

            TextField(
              controller: _passwordController,
              obscureText: true,
              onSubmitted: (_) => _submit(),
              decoration: const InputDecoration(
                hintText: 'Password',
              ),
            ),

            const SizedBox(height: 10),

            // Forgot password can be enabled later.
            //
            // Align(
            //   alignment: Alignment.centerRight,
            //   child: TextButton(
            //     onPressed: () {},
            //     child: const Text('Forgot password?'),
            //   ),
            // ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: auth.loading ? null : _submit,
                child: auth.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.black,
                        ),
                      )
                    : const Text('LOG IN'),
              ),
            ),

            // Only Customer and Vendor can create accounts.
            // Admin does not get a public signup option.
            if (widget.role != UserRole.admin) ...[
              const SizedBox(height: 18),

              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => SignupScreen(
                          role: widget.role,
                        ),
                      ),
                    );
                  },
                  child: Text(
                    "Don't have an account? Sign up as $_roleLabel",
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
