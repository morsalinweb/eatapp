// path: lib/screens/vendor/vendor_guidelines_screen.dart
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VendorGuidelinesScreen extends StatelessWidget {
  const VendorGuidelinesScreen({super.key});

  static const _guidelines = [
    {
      'title': 'Be accurate about your location',
      'body': "Only go live from where you're actually serving. Customers rely on your marker to "
          'plan their trip.',
    },
    {
      'title': 'Keep your profile current',
      'body': 'Update your hours, description, and photos whenever they change so customers know '
          'what to expect.',
    },
    {
      'title': 'Respond to messages promptly',
      'body': 'Customers message you through the app expecting a timely reply — aim to respond '
          'within a few hours.',
    },
    {
      'title': 'Follow local food safety laws',
      'body': "You're responsible for holding any permits or licenses your city or county requires "
          'for mobile food vendors.',
    },
    {
      'title': 'No prohibited content',
      'body': 'Keep your name, photos, and messages free of anything hateful, sexual, or otherwise '
          'inappropriate.',
    },
    {
      'title': 'One account per business',
      'body': 'Create a single vendor account per storefront — duplicate accounts for the same '
          'business may be suspended.',
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Guidelines')),
      body: ListView.separated(
        padding: const EdgeInsets.all(20),
        itemCount: _guidelines.length,
        separatorBuilder: (_, __) => const SizedBox(height: 16),
        itemBuilder: (context, i) {
          final item = _guidelines[i];
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 28,
                height: 28,
                alignment: Alignment.center,
                decoration: const BoxDecoration(color: AppColors.neon, shape: BoxShape.circle),
                child: Text('${i + 1}',
                    style: const TextStyle(color: Colors.black, fontWeight: FontWeight.w800, fontSize: 13)),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(item['title']!, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                    const SizedBox(height: 4),
                    Text(item['body']!,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4)),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}