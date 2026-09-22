import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../models/models.dart';
import '../../../providers/auth_provider.dart';
import 'application_pending_screen.dart';

class VendorApplicationScreen extends StatefulWidget {
  const VendorApplicationScreen({super.key});

  @override
  State<VendorApplicationScreen> createState() =>
      _VendorApplicationScreenState();
}

class _VendorApplicationScreenState extends State<VendorApplicationScreen> {
  final _businessNameController = TextEditingController();
  final _descriptionController = TextEditingController();
  VendorCategory _category = VendorCategory.tacos;
  bool _agreed = false;
  bool _submitting = false;

  Future<void> _submit() async {
    if (_businessNameController.text.trim().isEmpty || !_agreed) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
            content: Text('Please complete the form and accept the terms.')),
      );
      return;
    }
    setState(() => _submitting = true);
    final auth = context.read<AuthProvider>();
    final ok = await auth.submitVendorApplication(
      businessName: _businessNameController.text.trim(),
      category: _category,
      description: _descriptionController.text.trim(),
    );
    if (!mounted) return;
    setState(() => _submitting = false);

    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(auth.error ?? 'Could not submit application.')),
      );
      return;
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const ApplicationPendingScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Vendor Application')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tell us about your business',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 20),
            ),
            const SizedBox(height: 6),
            const Text(
              'E.A.T. is built for independent local vendors — every '
              'application is reviewed by our team before you can go live.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
            ),
            const SizedBox(height: 24),
            const Text('Business name',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _businessNameController,
              decoration: const InputDecoration(hintText: 'e.g. Taco Alien'),
            ),
            const SizedBox(height: 18),
            const Text('Category',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: VendorCategory.values.map((c) {
                final selected = c == _category;
                return ChoiceChip(
                  label: Text(c.label),
                  selected: selected,
                  onSelected: (_) => setState(() => _category = c),
                  backgroundColor: AppColors.surfaceRaised,
                  selectedColor: AppColors.neon,
                  labelStyle: TextStyle(
                    color: selected ? Colors.black : AppColors.textSecondary,
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                  ),
                  side: BorderSide(
                      color: selected ? AppColors.neon : AppColors.border),
                );
              }).toList(),
            ),
            const SizedBox(height: 18),
            const Text('Description',
                style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            const SizedBox(height: 8),
            TextField(
              controller: _descriptionController,
              maxLines: 4,
              decoration: const InputDecoration(
                  hintText: 'What do you serve? How long have you operated?'),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Checkbox(
                  value: _agreed,
                  activeColor: AppColors.neon,
                  checkColor: Colors.black,
                  onChanged: (v) => setState(() => _agreed = v ?? false),
                ),
                Expanded(
                  child: Text(
                    'I confirm I operate an independent local food business '
                    'and agree to E.A.T.\'s vendor guidelines.',
                    style: TextStyle(
                        fontSize: 12.5, color: AppColors.textSecondary),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _submitting ? null : _submit,
                child: _submitting
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.black),
                      )
                    : const Text('SUBMIT APPLICATION'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
