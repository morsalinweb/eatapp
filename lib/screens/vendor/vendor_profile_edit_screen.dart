// path: lib/screens/vendor/vendor_profile_edit_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/vendor_provider.dart';
import '../../services/avatar_upload_service.dart';
import '../../widgets/alien_avatar.dart';
import '../../widgets/image_source_sheet.dart';
import '../../widgets/live_badge.dart';

class VendorProfileEditScreen extends StatefulWidget {
  const VendorProfileEditScreen({super.key});

  @override
  State<VendorProfileEditScreen> createState() => _VendorProfileEditScreenState();
}

class _VendorProfileEditScreenState extends State<VendorProfileEditScreen> {
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _hoursController = TextEditingController();
  final _instagramController = TextEditingController();
  final _websiteController = TextEditingController();
  bool _cashOnly = false;
  bool _loading = true;
  bool _saving = false;
  bool _uploadingPhoto = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final provider = context.read<VendorProvider>();
    if (provider.myVendor == null) await provider.loadMyVendor();
    final vendor = provider.myVendor;
    if (vendor != null) {
      _nameController.text = vendor.name;
      _descriptionController.text = vendor.description;
      _hoursController.text = vendor.operatingHours;
      _instagramController.text = vendor.instagramHandle ?? '';
      _websiteController.text = vendor.website ?? '';
      _cashOnly = vendor.cashOnly;
    }
    if (mounted) setState(() => _loading = false);
  }

  Future<void> _changePhoto() async {
    final source = await showImageSourceSheet(context);
    if (source == null) return;

    setState(() => _uploadingPhoto = true);
    String? url;
    try {
      url = await AvatarUploadService.instance.pickAndUpload(source: source);
    } catch (_) {
      url = null;
    }
    if (!mounted) return;

    if (url == null) {
      setState(() => _uploadingPhoto = false);
      return;
    }

    final ok = await context.read<VendorProvider>().updateMyVendor({'avatar_url': url});
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (!ok) {
      await AppDialogs.showMessage(context, 'Could not update photo.', isError: true);
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final ok = await context.read<VendorProvider>().updateMyVendor({
      'name': _nameController.text.trim(),
      'description': _descriptionController.text.trim(),
      'operating_hours': _hoursController.text.trim(),
      'instagram_handle': _instagramController.text.trim().isEmpty ? null : _instagramController.text.trim(),
      'website': _websiteController.text.trim().isEmpty ? null : _websiteController.text.trim(),
      'cash_only': _cashOnly,
    });
    if (!mounted) return;
    setState(() => _saving = false);
    await AppDialogs.showMessage(
      context,
      ok ? 'Profile changes saved.' : 'Could not save changes.',
      isError: !ok,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator(color: AppColors.neon)));
    }

    final myVendor = context.watch<VendorProvider>().myVendor;

    return Scaffold(
      appBar: AppBar(title: const Text('Business Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: Column(
              children: [
                GestureDetector(
                  onTap: _uploadingPhoto ? null : _changePhoto,
                  child: Stack(
                    alignment: Alignment.bottomRight,
                    children: [
                      AlienAvatar(size: 90, glow: true, imageUrl: myVendor?.avatarUrl),
                      if (_uploadingPhoto)
                        Positioned.fill(
                          child: Container(
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Center(
                              child: SizedBox(
                                width: 24,
                                height: 24,
                                child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.neon),
                              ),
                            ),
                          ),
                        ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: const BoxDecoration(color: AppColors.neon, shape: BoxShape.circle),
                        child: const Icon(Icons.camera_alt, size: 16, color: Colors.black),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 4),
                TextButton(
                  onPressed: _uploadingPhoto ? null : _changePhoto,
                  child: const Text('Change Photo'),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(myVendor?.name ?? '',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                    const SizedBox(width: 8),
                    if (myVendor?.isLive == true) const LiveBadge(),
                  ],
                ),
                Text(myVendor?.subCategory ?? '',
                    style: const TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          _field('Business Name', _nameController),
          _field('Description', _descriptionController, maxLines: 3),
          _field('Operating Hours', _hoursController),
          _field('Instagram', _instagramController),
          _field('Website', _websiteController),
          const SizedBox(height: 10),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            activeColor: AppColors.neon,
            title: const Text('Cash only'),
            value: _cashOnly,
            onChanged: (v) => setState(() => _cashOnly = v),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saving ? null : _save,
              child: _saving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black),
                    )
                  : const Text('SAVE CHANGES'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _field(String label, TextEditingController controller, {int maxLines = 1}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextFormField(controller: controller, maxLines: maxLines),
        ],
      ),
    );
  }
}