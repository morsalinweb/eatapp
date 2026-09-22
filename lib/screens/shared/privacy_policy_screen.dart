// path: lib/screens/shared/privacy_policy_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

/// Static in-app privacy summary, shared by the customer, vendor, and
/// admin settings screens (they each just pass their own title).
class PrivacyPolicyScreen extends StatelessWidget {
  final String title;
  const PrivacyPolicyScreen({super.key, this.title = 'Privacy & Policy'});

  static const _sections = [
    {
      'heading': 'Who operates this app',
      'body':
          'E.A.T. (Eats Around Town) is operated by Camargos World Inc. References to "we," "us," '
          'or "E.A.T." in this policy mean Camargos World Inc.',
    },
    {
      'heading': 'What we collect',
      'body':
          "Your name, email, and phone number when you create an account; your location while "
          "using the map or nearby-vendors search (or while a vendor is broadcasting); and the "
          "messages you send through E.A.T.'s chat.",
    },
    {
      'heading': 'Vendor location',
      'body':
          'Vendors choose when to share their live location by tapping "Go Live" — nothing is '
          'broadcast before that, and it stops the moment they tap "Stop Sharing".',
    },
    {
      'heading': 'Customer location',
      'body':
          "When you use the map or nearby-vendors search, we keep only your most recent location "
          "on file — each search replaces the last one. We don't track your location in the "
          "background or keep a history of past locations.",
    },
    {
      'heading': 'Visibility to our team',
      'body':
          "To support safety and moderation, our administrators can see the current location of "
          "vendors who are broadcasting and the most recent location on file for customers. This "
          "is limited to each person's latest known position — not a history.",
    },
    {
      'heading': 'Chat messages',
      'body':
          'Messages between customers and vendors are stored so conversations persist across '
          'devices, and are only visible to the two participants (plus admins, strictly for '
          'moderating reported conversations).',
    },
    {
      'heading': 'Reports & moderation',
      'body':
          "If you report a vendor, the report (and the vendor's contact details) is visible to our "
          'admin team so they can follow up, including suspending accounts that violate our '
          'guidelines.',
    },
    {
      'heading': 'Your choices',
      'body':
          'Vendors can stop sharing location at any time. Customers can avoid location being '
          "recorded by not using the map or nearby search — other features don't require it. You "
          'can also edit your profile details and contact us through the Help Center with any '
          'request about your data.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          ..._sections.map((s) => Padding(
                padding: const EdgeInsets.only(bottom: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s['heading']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                    const SizedBox(height: 6),
                    Text(s['body']!,
                        style: const TextStyle(color: AppColors.textSecondary, height: 1.5, fontSize: 13)),
                  ],
                ),
              )),
          const Text(
            'This screen is a plain-language summary for the app, not a substitute for a full legal '
            'privacy policy.',
            style: TextStyle(color: AppColors.textMuted, fontSize: 11.5, fontStyle: FontStyle.italic),
          ),
        ],
      ),
    );
  }
}