import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/core/theme/app_theme.dart';

void main() {
  test('UrbanTrackCRM exposes the approved brand tokens', () {
    final brand = UrbanTrackBrand.config;

    expect(brand.primaryColor, const Color(0xFFF87315));
    expect(brand.inkColor, const Color(0xFF0F162A));
    expect(brand.canvasColor, const Color(0xFFF2F2F2));
    expect(brand.fontFamily, 'Poppins');
  });

  testWidgets('the application theme renders with Poppins and brand colors', (
    tester,
  ) async {
    final brand = UrbanTrackBrand.config;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(brand),
        home: const Scaffold(body: Text('UrbanTrackCRM')),
      ),
    );

    final context = tester.element(find.text('UrbanTrackCRM'));
    final theme = Theme.of(context);

    expect(DefaultTextStyle.of(context).style.fontFamily, brand.fontFamily);
    expect(theme.colorScheme.primary, brand.primaryColor);
    expect(theme.colorScheme.onSurface, brand.inkColor);
    expect(theme.scaffoldBackgroundColor, brand.canvasColor);
  });

  testWidgets('all declared Poppins weights and their license are bundled', (
    tester,
  ) async {
    const assets = <String>[
      'assets/fonts/Poppins-Regular.ttf',
      'assets/fonts/Poppins-Medium.ttf',
      'assets/fonts/Poppins-SemiBold.ttf',
      'assets/fonts/Poppins-Bold.ttf',
      'assets/fonts/Poppins-ExtraBold.ttf',
      'assets/fonts/Poppins-Black.ttf',
      'assets/fonts/OFL.txt',
    ];

    for (final asset in assets) {
      final data = await rootBundle.load(asset);
      expect(data.lengthInBytes, greaterThan(0), reason: asset);
    }
  });
}
