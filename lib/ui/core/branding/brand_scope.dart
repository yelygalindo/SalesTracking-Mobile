import 'package:flutter/widgets.dart';

import 'brand_config.dart';

class BrandScope extends InheritedWidget {
  const BrandScope({required this.brand, required super.child, super.key});

  final BrandConfig brand;

  static BrandConfig of(BuildContext context) {
    final scope = context.dependOnInheritedWidgetOfExactType<BrandScope>();
    assert(scope != null, 'BrandScope is missing above this context.');
    return scope!.brand;
  }

  @override
  bool updateShouldNotify(BrandScope oldWidget) => brand != oldWidget.brand;
}
