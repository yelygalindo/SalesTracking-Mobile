import 'package:flutter/material.dart';

import 'brand_config.dart';

abstract final class UrbanTrackBrand {
  static final config = BrandConfig(
    id: 'urbantrack-crm',
    appName: 'UrbanTrackCRM',
    monogram: 'UT',
    website: Uri.parse('https://urbantrack.io/'),
    primaryColor: const Color(0xFFF87315),
    inkColor: const Color(0xFF0F162A),
    canvasColor: const Color(0xFFF2F2F2),
    fontFamily: 'Poppins',
    logoAsset: 'assets/branding/urbantrackcrm/launcher-legacy.png',
  );
}
