// path: lib/services/avatar_upload_service.dart
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Handles picking a photo from the gallery/camera and uploading it to the
/// public "avatars" bucket in Supabase Storage, returning a public URL that
/// gets saved onto a profile (PATCH /auth/me) or a vendor storefront
/// (PATCH /vendors/me/profile) — both already accept `avatar_url`.
///
/// Requires the "avatars" bucket + RLS policies from
/// db/03_avatars_storage.sql to already exist in the Supabase project.
class AvatarUploadService {
  AvatarUploadService._();
  static final AvatarUploadService instance = AvatarUploadService._();

  final _picker = ImagePicker();

  /// Returns the new public URL, or null if the user cancelled picking or
  /// isn't logged in.
  Future<String?> pickAndUpload({required ImageSource source}) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (picked == null) return null;

    final userId = Supabase.instance.client.auth.currentUser?.id;
    if (userId == null) return null;

    final bytes = await File(picked.path).readAsBytes();
    final extension = picked.path.split('.').last.toLowerCase();
    // Storing under the user's own uid as the folder name is what the
    // storage RLS policies check against — see db/03_avatars_storage.sql.
    final path = '$userId/${DateTime.now().millisecondsSinceEpoch}.$extension';

    await Supabase.instance.client.storage.from('avatars').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(
            contentType: 'image/$extension',
            upsert: true,
          ),
        );

    return Supabase.instance.client.storage.from('avatars').getPublicUrl(path);
  }
}