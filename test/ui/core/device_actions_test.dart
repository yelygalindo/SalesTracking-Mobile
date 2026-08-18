import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/ui/core/device_actions.dart';

void main() {
  test('builds a normalized telephone URI', () {
    expect(phoneUri(' +591 700-10 001 ')?.toString(), 'tel:+59170010001');
    expect(phoneUri('   '), isNull);
  });

  test('prefers coordinates when building a map URI', () {
    final uri = mapUri(
      latitude: -17.75,
      longitude: -63.18,
      address: 'Av. Banzer',
    );

    expect(uri?.scheme, 'https');
    expect(uri?.host, 'www.google.com');
    expect(uri?.queryParameters['api'], '1');
    expect(uri?.queryParameters['query'], '-17.75,-63.18');
  });

  test('falls back to the address when coordinates are unavailable', () {
    final uri = mapUri(
      latitude: null,
      longitude: null,
      address: 'Av. Banzer, Santa Cruz',
    );

    expect(uri?.queryParameters['query'], 'Av. Banzer, Santa Cruz');
    expect(mapUri(latitude: null, longitude: null, address: '  '), isNull);
  });
}
