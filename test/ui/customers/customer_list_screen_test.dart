import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:urbantrack/data/models/common/user_reference.dart';
import 'package:urbantrack/data/models/customer/customer_page.dart';
import 'package:urbantrack/data/models/customer/customer_status.dart';
import 'package:urbantrack/data/models/customer/customer_summary.dart';
import 'package:urbantrack/data/repositories/customer_repository.dart';
import 'package:urbantrack/ui/core/branding/brand_scope.dart';
import 'package:urbantrack/ui/core/branding/urbantrack_brand.dart';
import 'package:urbantrack/ui/customers/customer_list_screen.dart';

void main() {
  testWidgets('renders customers without overflow on phone and tablet', (
    tester,
  ) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      BrandScope(
        brand: UrbanTrackBrand.config,
        child: MaterialApp(
          home: CustomerListScreen(repository: _CustomerScreenRepository()),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Ricardo Alarcón'), findsOneWidget);
    expect(find.text('Constructora Horizonte'), findsOneWidget);
    expect(find.text('Activo'), findsWidgets);
    expect(tester.takeException(), isNull);

    await tester.binding.setSurfaceSize(const Size(1024, 900));
    await tester.pumpAndSettle();

    expect(find.text('Mariana Gómez'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}

class _CustomerScreenRepository implements CustomerRepository {
  @override
  Future<CustomerPage> getCustomers({
    String? status,
    String? externalUserId,
    String? search,
    int page = 1,
    int pageSize = 20,
  }) async => CustomerPage(
    customers: [_customerOne, _customerTwo],
    page: 1,
    pageSize: 20,
    totalItems: 2,
    totalPages: 1,
  );

  @override
  Future<List<CustomerStatus>> getStatuses() async => const [
    CustomerStatus(value: 1, label: 'Prospecto'),
    CustomerStatus(value: 2, label: 'Activo'),
  ];
}

final _customerOne = CustomerSummary(
  id: 1,
  externalId: 'customer-1',
  name: 'Ricardo Alarcón',
  companyName: 'Constructora Horizonte',
  phone: '700 10001',
  email: '',
  status: 'Activo',
  createdAtUtc: DateTime.utc(2026, 8, 7),
  seller: const UserReference(externalId: 'seller-id', name: 'Carlos Gómez'),
);

final _customerTwo = CustomerSummary(
  id: 2,
  externalId: 'customer-2',
  name: 'Mariana Gómez',
  companyName: 'Inmobiliaria del Valle',
  phone: '700 20002',
  email: '',
  status: 'Prospecto',
  createdAtUtc: DateTime.utc(2026, 8, 7),
  seller: const UserReference(externalId: 'seller-id', name: 'Carlos Gómez'),
);
