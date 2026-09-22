import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import '../../auth/role_select_screen.dart';
import '../vendor_shell.dart';

class ApplicationPendingScreen extends StatefulWidget {
  const ApplicationPendingScreen({super.key});

  @override
  State<ApplicationPendingScreen> createState() => _ApplicationPendingScreenState();
}

class _ApplicationPendingScreenState extends State<ApplicationPendingScreen> {
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    // Check every 15s so an approval while the screen is open routes the
    // vendor straight into their dashboard without needing to log out/in.
    _pollTimer = Timer.periodic(const Duration(seconds: 15), (_) => _checkStatus());
  }

  Future<void> _checkStatus() async {
    final auth = context.read<AuthProvider>();
    await auth.refreshVendorApplicationStatus();
    if (!mounted) return;
    if (auth.vendorApplicationStatus == VendorStatus.approved) {
      _pollTimer?.cancel();
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const VendorShell()),
        (route) => false,
      );
    }
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(28),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 110,
                height: 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppColors.surfaceRaised,
                  border: Border.all(color: AppColors.neonDim, width: 1.5),
                  boxShadow: AppShadows.neonGlow(opacity: 0.2, blur: 24),
                ),
                child: const Icon(Icons.hourglass_top_rounded, color: AppColors.neon, size: 46),
              ),
              const SizedBox(height: 26),
              const Text(
                'Application Under Review',
                textAlign: TextAlign.center,
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
              ),
              const SizedBox(height: 10),
              const Text(
                'Our team is reviewing your vendor application. This screen '
                'will update automatically the moment you\'re approved to go LIVE — '
                'this usually takes 1-2 business days.',
                textAlign: TextAlign.center,
                style: TextStyle(color: AppColors.textSecondary, height: 1.4),
              ),
              const SizedBox(height: 20),
              TextButton.icon(
                onPressed: _checkStatus,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Check now'),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () async {
                    await context.read<AuthProvider>().logout();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const RoleSelectScreen()),
                      (route) => false,
                    );
                  },
                  child: const Text('BACK TO SIGN IN'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
