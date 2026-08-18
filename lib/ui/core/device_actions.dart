import 'package:url_launcher/url_launcher.dart';

Uri? phoneUri(String phone) {
  final normalized = phone.trim().replaceAll(RegExp(r'[^0-9+]'), '');
  if (normalized.isEmpty) return null;
  return Uri(scheme: 'tel', path: normalized);
}

Uri? mapUri({
  required double? latitude,
  required double? longitude,
  required String address,
}) {
  final query = latitude != null && longitude != null
      ? '$latitude,$longitude'
      : address.trim();
  if (query.isEmpty) return null;
  return Uri.https('www.google.com', '/maps/search/', {
    'api': '1',
    'query': query,
  });
}

Future<bool> launchDeviceAction(Uri? uri) async {
  if (uri == null) return false;
  return launchUrl(uri, mode: LaunchMode.externalApplication);
}
