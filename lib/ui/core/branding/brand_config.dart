import 'package:flutter/material.dart';

@immutable
class BrandConfig {
  const BrandConfig({
    required this.id,
    required this.appName,
    required this.monogram,
    required this.website,
    required this.primaryColor,
    required this.inkColor,
    required this.canvasColor,
    required this.fontFamily,
    this.logoAsset,
  });

  final String id;
  final String appName;
  final String monogram;
  final Uri website;
  final Color primaryColor;
  final Color inkColor;
  final Color canvasColor;
  final String fontFamily;
  final String? logoAsset;
}
