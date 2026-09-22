// path: lib/screens/customer/customer_edit_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/app_dialogs.dart';
import '../../providers/auth_provider.dart';
import '../../services/avatar_upload_service.dart';
import '../../widgets/alien_avatar.dart';
import '../../widgets/image_source_sheet.dart';

class CustomerEditProfileScreen extends StatefulWidget {
  const CustomerEditProfileScreen({super.key});

  @override
  State<CustomerEditProfileScreen> createState() => _CustomerEditProfileScreenState();
}

class _CustomerEditProfileScreenState extends State<CustomerEditProfileScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  bool _saving = false;
  bool _uploadingPhoto = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _nameController = TextEditingController(text: user?.name ?? '');
    _phoneController = TextEditingController(text: user?.phone ?? '');
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    super.dispose();
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

    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(
      fullName: _nameController.text.trim().isEmpty ? (auth.currentUser?.name ?? '') : _nameController.text.trim(),
      phone: _phoneController.text.trim(),
      avatarUrl: url,
    );
    if (!mounted) return;
    setState(() => _uploadingPhoto = false);
    if (!ok) {
      await AppDialogs.showMessage(context, auth.error ?? 'Could not update photo.', isError: true);
    }
  }

  Future<void> _save() async {
    final name = _nameController.text.trim();
    if (name.length < 2) {
      setState(() => _error = 'Please enter your name.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final auth = context.read<AuthProvider>();
    final ok = await auth.updateProfile(fullName: name, phone: _phoneController.text.trim());
    if (!mounted) return;
    setState(() => _saving = false);
    if (ok) {
      await AppDialogs.showMessage(context, 'Profile updated.');
      if (!mounted) return;
      Navigator.of(context).pop();
    } else {
      setState(() => _error = auth.error ?? 'Could not save changes.');
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = context.watch<AuthProvider>().currentUser;
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profile')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Center(
            child: GestureDetector(
              onTap: _uploadingPhoto ? null : _changePhoto,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [
                  AlienAvatar(size: 96, glow: true, imageUrl: user?.avatarUrl),
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
          ),
          const SizedBox(height: 24),
          const Text('Email', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.surfaceRaised,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.border),
            ),
            child: Text(user?.email ?? '', style: const TextStyle(color: AppColors.textSecondary)),
          ),
          const SizedBox(height: 4),
          const Text("Email can't be changed here.",
              style: TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 18),
          const Text('Full name', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _nameController),
          const SizedBox(height: 18),
          const Text('Phone', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
          const SizedBox(height: 8),
          TextField(controller: _phoneController, keyboardType: TextInputType.phone),
          if (_error != null) ...[
            const SizedBox(height: 12),
            Text(_error!, style: const TextStyle(color: AppColors.danger, fontSize: 12.5)),
          ],
          const SizedBox(height: 22),
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
}