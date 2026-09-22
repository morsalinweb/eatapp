// path: lib/screens/customer/vendor_profile_screen.dart
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/utils/maps_launcher.dart';
import '../../models/models.dart';
import '../../providers/chat_provider.dart';
import '../../providers/vendor_provider.dart';
import '../../services/api_client.dart';
import '../../widgets/alien_avatar.dart';
import '../../widgets/live_badge.dart';
import '../chat/chat_thread_screen.dart';

class VendorProfileScreen extends StatefulWidget {
  final Vendor vendor;
  const VendorProfileScreen({super.key, required this.vendor});

  @override
  State<VendorProfileScreen> createState() => _VendorProfileScreenState();
}

class _VendorProfileScreenState extends State<VendorProfileScreen> {
  late Vendor _vendor = widget.vendor;

  @override
  void initState() {
    super.initState();
    _refresh();
  }

  Future<void> _refresh() async {
    try {
      final json = await ApiClient.instance.get('/vendors/${widget.vendor.id}');
      if (!mounted) return;
      setState(() => _vendor = Vendor.fromJson(json['vendor']));
    } catch (_) {
      // non-fatal — just keep showing the cached copy we were passed
    }
  }

  Future<void> _openChat(BuildContext context) async {
    final thread = await context
        .read<ChatProvider>()
        .startThreadWithVendor(_vendor.id, _vendor.name, vendorAvatarUrl: _vendor.avatarUrl);
    if (!context.mounted || thread == null) return;
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => ChatThreadScreen(threadTitle: _vendor.name, thread: thread)),
    );
  }

  Future<void> _openDirections(BuildContext context) async {
    final lat = _vendor.lat;
    final lng = _vendor.lng;
    if (lat == null || lng == null) return;

    final opened = await MapsLauncher.openDirections(lat: lat, lng: lng, label: _vendor.name);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not open Maps.')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final vendor = _vendor;
    final vendorProvider = context.watch<VendorProvider>();
    final isFav = vendorProvider.isFavorite(vendor.id);
    final hasLiveLocation = vendor.isLive && vendor.lat != null && vendor.lng != null;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            backgroundColor: AppColors.bgBlack,
            leading: _circleIconButton(
              icon: Icons.arrow_back,
              onTap: () => Navigator.of(context).pop(),
            ),
            actions: [
              _circleIconButton(
                icon: isFav ? Icons.favorite : Icons.favorite_border,
                iconColor: isFav ? AppColors.neon : Colors.white,
                onTap: () => vendorProvider.toggleFavorite(vendor.id),
              ),
              _circleIconButton(icon: Icons.more_vert, onTap: () => _showReportSheet(context, vendor)),
              const SizedBox(width: 8),
            ],
            flexibleSpace: FlexibleSpaceBar(
              background: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [AppColors.surfaceRaised, AppColors.bgBlack],
                  ),
                ),
                child: Center(
                  child: (vendor.avatarUrl != null && vendor.avatarUrl!.isNotEmpty)
                      ? AlienAvatar(size: 96, glow: true, imageUrl: vendor.avatarUrl)
                      : Icon(Icons.local_shipping_outlined, size: 90, color: AppColors.neonDim),
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (vendor.isLive)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: Row(
                        children: const [
                          LiveBadge(),
                          SizedBox(width: 8),
                          Text('NOW',
                              style: TextStyle(
                                  color: AppColors.textMuted, fontSize: 11)),
                        ],
                      ),
                    ),
                  Text(vendor.name,
                      style: const TextStyle(
                          fontSize: 26, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),
                  Text(vendor.subCategory,
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 14)),
                  const SizedBox(height: 8),
                  Text('${vendor.distanceMiles.toStringAsFixed(1)} mi away',
                      style: const TextStyle(
                          color: AppColors.textSecondary, fontSize: 13)),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: _statusChip(
                          vendor.isLive ? 'Open' : 'Offline',
                          'Closes 11:00 PM',
                          vendor.isLive,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _statusChip(
                          vendor.priceTier,
                          vendor.cashOnly ? 'Cash Only' : 'Cards Accepted',
                          null,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Text(vendor.description,
                      style: const TextStyle(
                          color: AppColors.textSecondary, height: 1.5)),
                  const SizedBox(height: 20),
                  const Divider(),
                  const SizedBox(height: 8),
                  // Only clickable-for-directions while the vendor is
                  // actually live and we have a real coordinate — a
                  // suspended/offline vendor has no current position to
                  // navigate to, so this stays a plain, non-tappable row
                  // in that case.
                  if (hasLiveLocation)
                    _tappableInfoRow(
                      icon: Icons.navigation_outlined,
                      label: 'Current Location',
                      value: 'Get Directions',
                      onTap: () => _openDirections(context),
                    )
                  else
                    _infoRow(Icons.place_outlined, 'Current Location', 'Not live right now'),
                  _infoRow(Icons.access_time, 'Operating Hours', vendor.operatingHours),
                  _infoRow(Icons.map_outlined, 'Service Area', vendor.serviceAreaMiles),
                  if (vendor.instagramHandle != null)
                    _infoRow(Icons.camera_alt_outlined, 'Instagram', vendor.instagramHandle!),
                  if (vendor.website != null)
                    _infoRow(Icons.link, 'Website', vendor.website!),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _openChat(context),
                          icon: const Icon(Icons.chat_bubble_outline, size: 18),
                          label: const Text('Message'),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => vendorProvider.toggleFavorite(vendor.id),
                          icon: Icon(
                            isFav ? Icons.favorite : Icons.favorite_border,
                            size: 18,
                            color: isFav ? AppColors.neon : AppColors.textPrimary,
                          ),
                          label: const Text('Save'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _circleIconButton({
    required IconData icon,
    required VoidCallback onTap,
    Color iconColor = Colors.white,
  }) {
    return Padding(
      padding: const EdgeInsets.all(6),
      child: CircleAvatar(
        backgroundColor: Colors.black.withOpacity(0.5),
        child: IconButton(
          icon: Icon(icon, color: iconColor, size: 20),
          onPressed: onTap,
        ),
      ),
    );
  }

  Widget _statusChip(String title, String subtitle, bool? isLiveStyled) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceRaised,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isLiveStyled == true ? AppColors.neon : AppColors.border,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: isLiveStyled == true ? AppColors.neon : AppColors.textPrimary,
              )),
          Text(subtitle,
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary)),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.textMuted),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
          ),
          Text(value,
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
        ],
      ),
    );
  }

  /// Same visual layout as _infoRow, but the value is styled as a link and
  /// the whole row responds to a tap — used specifically for "Get
  /// Directions" so it's obviously actionable, not just informational.
  Widget _tappableInfoRow({
    required IconData icon,
    required String label,
    required String value,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.neon),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label, style: const TextStyle(color: AppColors.textSecondary)),
            ),
            Text(value,
                style: const TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: AppColors.neon,
                  decoration: TextDecoration.underline,
                )),
            const SizedBox(width: 4),
            const Icon(Icons.chevron_right, size: 16, color: AppColors.neon),
          ],
        ),
      ),
    );
  }

  void _showReportSheet(BuildContext context, Vendor vendor) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Report this vendor',
                style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            const SizedBox(height: 6),
            const Text(
              'Let us know if something looks off. Reports are reviewed by our admin team.',
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
            const SizedBox(height: 16),
            ...['Inaccurate location', 'Inappropriate content', 'Safety concern', 'Other']
                .map((reason) => ListTile(
                      contentPadding: EdgeInsets.zero,
                      title: Text(reason),
                      trailing: const Icon(Icons.chevron_right, color: AppColors.textMuted),
                      onTap: () async {
                        Navigator.pop(context);
                        try {
                          await ApiClient.instance.post('/reports', body: {
                            'vendor_id': vendor.id,
                            'reason': reason,
                          });
                        } catch (_) {}
                      },
                    )),
          ],
        ),
      ),
    );
  }
}