import 'package:flutter/material.dart';

import 'brand_config.dart';

abstract final class UrbanTrackBrand {
  static final config = BrandConfig(
    id: 'urbantrack',
    appName: 'UrbanTrack',
    monogram: 'UT',
    website: Uri.parse('https://urbantrack.io/'),
    primaryColor: const Color(0xFFF97316),
    inkColor: const Color(0xFF0F1B33),
    canvasColor: const Color(0xFFF4F6FA),
  );
}
