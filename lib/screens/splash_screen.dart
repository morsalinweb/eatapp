// path: lib/screens/splash_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../core/theme/app_theme.dart';
import '../models/models.dart';
import '../providers/auth_provider.dart';
import 'admin/admin_shell.dart';
import 'auth/role_select_screen.dart';
import 'customer/customer_shell.dart';
import 'vendor/application/application_pending_screen.dart';
import 'vendor/application/vendor_application_screen.dart';
import 'vendor/vendor_shell.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> with SingleTickerProviderStateMixin {
  late final AnimationController _glowController = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 2),
  )..repeat(reverse: true);

  @override
  void initState() {
    super.initState();
    _resume();
  }

  Future<void> _resume() async {
    // Give the glow animation a beat to render before we possibly navigate
    // away, and let AuthProvider try to silently restore a saved session.
    final auth = context.read<AuthProvider>();
    final restored = await Future.wait([
      auth.tryRestoreSession(),
      Future.delayed(const Duration(milliseconds: 900)),
    ]).then((results) => results[0] as bool);

    if (!mounted) return;
    if (restored && auth.currentUser != null) {
      _routeSignedInUser(auth);
    }
    // If not restored, the user just sees the normal GET STARTED button.
  }

  void _routeSignedInUser(AuthProvider auth) {
    final user = auth.currentUser!;
    Widget destination;
    switch (user.role) {
      case UserRole.admin:
        destination = const AdminShell();
        break;
      case UserRole.vendor:
        final status = auth.vendorApplicationStatus;
        if (status == VendorStatus.approved) {
          destination = const VendorShell();
        } else if (status == VendorStatus.pending) {
          destination = const ApplicationPendingScreen();
        } else {
          destination = const VendorApplicationScreen();
        }
        break;
      case UserRole.customer:
        destination = const CustomerShell();
        break;
    }
    Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => destination));
  }

  @override
  void dispose() {
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgBlack,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(),
              AnimatedBuilder(
                animation: _glowController,
                builder: (context, child) {
                  final glow = 0.25 + (_glowController.value * 0.35);
                  return Container(
                    width: 150,
                    height: 150,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: AppShadows.neonGlow(blur: 40, opacity: glow),
                    ),
                    child: Icon(
                      Icons.face_retouching_natural,
                      size: 110,
                      color: AppColors.neon.withOpacity(0.9),
                    ),
                  );
                },
              ),
              const SizedBox(height: 28),
              Text(
                'E.A.T.',
                style: TextStyle(
                  fontSize: 52,
                  fontWeight: FontWeight.w900,
                  fontStyle: FontStyle.italic,
                  color: AppColors.neon,
                  shadows: AppShadows.neonGlow(blur: 20, opacity: 0.6),
                  letterSpacing: 2,
                ),
              ),
              const SizedBox(height: 4),
              const Text(
                'EVERYTHING AROUND TOWN',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 4,
                  color: AppColors.textPrimary,
                ),
              ),
              const SizedBox(height: 18),
              const Text(
                'Find Local. Eat Local.',
                style: TextStyle(color: AppColors.neon, fontWeight: FontWeight.w600, fontSize: 15),
              ),
              const SizedBox(height: 6),
              const Text(
                'See who\'s serving near you — LIVE.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
              ),
              const Spacer(),
              Consumer<AuthProvider>(
                builder: (context, auth, _) => SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: auth.loading
                        ? null
                        : () {
                            Navigator.of(context).pushReplacement(
                              MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                            );
                          },
                    child: auth.loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                          )
                        : const Text('GET STARTED'),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
