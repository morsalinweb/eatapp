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
      'heading': 'What we collect',
      'body':
          "Your name, email, and phone number when you create an account; your live GPS location "
          "while a vendor is broadcasting (or while a customer's map is open); and the messages you "
          "send through E.A.T.'s chat.",
    },
    {
      'heading': 'Location data',
      'body':
          'Vendors choose when to share their location by tapping "Go Live" — nothing is broadcast '
          'before that, and it stops the moment they tap "Stop Sharing". A customer\'s device location '
          'is only used locally to center the map and sort nearby vendors by distance.',
    },
    {
      'heading': 'Chat messages',
      'body':
          'Messages between customers and vendors are stored so conversations persist across devices, '
          'and are only visible to the two participants (plus admins, strictly for moderating reported '
          'conversations).',
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
          'You can stop sharing your location at any time, edit your profile details, and contact us '
          'through the Help Center with any request about your data.',
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