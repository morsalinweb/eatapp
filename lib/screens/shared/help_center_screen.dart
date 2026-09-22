// path: lib/screens/shared/help_center_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpCenterScreen extends StatelessWidget {
  const HelpCenterScreen({super.key});

  static const _faqs = [
    {
      'q': 'How do I message a vendor?',
      'a': 'Open a vendor\'s profile (or tap "Message" on their card from the map or nearby list) to '
          'start a conversation. Vendors reply from their own Messages tab.',
    },
    {
      'q': "Why can't I see a vendor on the map?",
      'a': 'Only vendors who have tapped "Go Live" appear on the map, and only while they\'re actively '
          'broadcasting. Check the Nearby tab to browse all approved vendors regardless of live status.',
    },
    {
      'q': 'How do I become a vendor?',
      'a': 'Sign up (or log in) from the Vendor tab on the welcome screen and submit an application. '
          'An admin reviews every application before you can start selling.',
    },
    {
      'q': 'How do I report a vendor?',
      'a': 'Open the vendor\'s profile, tap the "⋮" menu in the top right, and choose a reason. Our '
          'admin team reviews every report.',
    },
    {
      'q': 'How do I stop sharing my location as a vendor?',
      'a': 'Go to the Go Live tab and tap "Stop Sharing Location" — you disappear from the customer '
          'map immediately.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Help Center')),
      body: ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: _faqs.length,
        separatorBuilder: (_, __) => const SizedBox(height: 10),
        itemBuilder: (context, i) {
          final faq = _faqs[i];
          return Container(
            decoration: BoxDecoration(
              color: AppColors.card,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: Text(faq['q']!, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5)),
                iconColor: AppColors.neon,
                collapsedIconColor: AppColors.textMuted,
                childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                expandedCrossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(faq['a']!,
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.5)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}