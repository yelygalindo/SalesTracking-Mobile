import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/branding/brand_mark.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';

void main() {
  test('the approved UrbanTrackCRM mark is bundled', () async {
    final asset = UrbanTrackBrand.config.logoAsset;

    expect(asset, isNotNull);
    final data = await rootBundle.load(asset!);
    expect(data.lengthInBytes, greaterThan(0));
  });

  testWidgets('BrandMark renders the configured asset and semantics', (
    tester,
  ) async {
    final brand = UrbanTrackBrand.config;

    await tester.pumpWidget(
      BrandScope(
        brand: brand,
        child: const MaterialApp(
          home: Scaffold(body: BrandMark(size: 58, borderRadius: 17)),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('brand-logo-image')), findsOneWidget);
    expect(find.bySemanticsLabel('Logo de ${brand.appName}'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
