import 'package:flutter/material.dart';

import 'brand_scope.dart';

class BrandMark extends StatelessWidget {
  const BrandMark({required this.size, required this.borderRadius, super.key});

  final double size;
  final double borderRadius;

  @override
  Widget build(BuildContext context) {
    final brand = BrandScope.of(context);
    final fallback = Center(
      child: Text(
        brand.monogram,
        style: TextStyle(
          color: Colors.white,
          fontSize: size * .34,
          fontWeight: FontWeight.w900,
        ),
      ),
    );

    return Semantics(
      image: true,
      label: 'Logo de ${brand.appName}',
      child: Container(
        width: size,
        height: size,
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: brand.primaryColor,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: switch (brand.logoAsset) {
          final asset? => Image.asset(
            asset,
            key: const ValueKey('brand-logo-image'),
            fit: BoxFit.contain,
            errorBuilder: (_, _, _) => fallback,
          ),
          null => fallback,
        },
      ),
    );
  }
}
