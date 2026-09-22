// path: lib/screens/vendor/vendor_shell.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/chat_provider.dart';
import 'vendor_home_screen.dart';
import 'go_live_screen.dart';
import 'vendor_messages_screen.dart';
import 'vendor_profile_edit_screen.dart';
import 'vendor_settings_screen.dart';

class VendorShell extends StatefulWidget {
  const VendorShell({super.key});

  @override
  State<VendorShell> createState() => _VendorShellState();
}

class _VendorShellState extends State<VendorShell> {
  int _index = 0;

  final _screens = const [
    VendorHomeScreen(),
    GoLiveScreen(),
    VendorMessagesScreen(),
    VendorProfileEditScreen(),
    VendorSettingsScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final unread = context.watch<ChatProvider>().unreadTotal;
    return Scaffold(
      body: IndexedStack(index: _index, children: _screens),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _index,
        onTap: (i) => setState(() => _index = i),
        backgroundColor: AppColors.surface,
        items: [
          const BottomNavigationBarItem(
              icon: Icon(Icons.home_outlined),
              activeIcon: Icon(Icons.home),
              label: 'Home'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.podcasts_outlined),
              activeIcon: Icon(Icons.podcasts),
              label: 'Go Live'),
          BottomNavigationBarItem(
              icon: _BadgeIcon(icon: Icons.chat_bubble_outline, count: unread),
              activeIcon: _BadgeIcon(icon: Icons.chat_bubble, count: unread),
              label: 'Messages'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.storefront_outlined),
              activeIcon: Icon(Icons.storefront),
              label: 'Profile'),
          const BottomNavigationBarItem(
              icon: Icon(Icons.settings_outlined),
              activeIcon: Icon(Icons.settings),
              label: 'Settings'),
        ],
      ),
    );
  }
}

/// Small red count badge layered on a bottom-nav icon — same behavior as
/// the customer side, so vendors notice new messages while on another tab.
class _BadgeIcon extends StatelessWidget {
  final IconData icon;
  final int count;
  const _BadgeIcon({required this.icon, required this.count});

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Icon(icon),
        if (count > 0)
          Positioned(
            right: -6,
            top: -4,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
              constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
              decoration: BoxDecoration(
                color: AppColors.danger,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.surface, width: 1.5),
              ),
              child: Text(
                count > 9 ? '9+' : '$count',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w700),
              ),
            ),
          ),
      ],
    );
  }
}