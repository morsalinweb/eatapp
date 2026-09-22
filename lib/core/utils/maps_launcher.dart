// path: lib/core/utils/maps_launcher.dart
import 'package:url_launcher/url_launcher.dart';

/// Opens Google Maps (the app if installed, otherwise a browser fallback)
/// with turn-by-turn directions to the given coordinate. Uses Google's
/// universal "dir" URL, which both platforms and Google Maps itself know
/// how to route through their own app when it's present.
class MapsLauncher {
  MapsLauncher._();

  static Future<bool> openDirections({
    required double lat,
    required double lng,
    String? label,
  }) async {
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': '$lat,$lng',
      if (label != null && label.isNotEmpty) 'destination_place_id': '',
    });

    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }
}