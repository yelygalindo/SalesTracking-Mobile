import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter/widgets.dart';
import 'package:http/http.dart' as http;

import 'app/urbantrack_app.dart';
import 'config/app_environment.dart';
import 'data/repositories/remote_auth_repository.dart';
import 'data/repositories/remote_workday_repository.dart';
import 'data/services/geolocator_location_service.dart';
import 'data/services/auth_service.dart';
import 'data/services/workday_service.dart';
import 'data/storage/secure_session_storage.dart';
import 'ui/core/branding/urbantrack_brand.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  final environment = AppEnvironment.current;
  final authHttpClient = http.Client();
  final authRepository = RemoteAuthRepository(
    AuthService(Uri.parse(environment.apiBaseUrl), authHttpClient),
    SecureSessionStorage(const FlutterSecureStorage()),
    Platform.isIOS ? 'ios' : 'android',
  );
  final workdayRepository = RemoteWorkdayRepository(
    WorkdayService(Uri.parse(environment.apiBaseUrl), http.Client()),
    authRepository,
  );

  runApp(
    UrbanTrackApp(
      brand: UrbanTrackBrand.config,
      environment: environment,
      authRepository: authRepository,
      workdayRepository: workdayRepository,
      locationService: const GeolocatorLocationService(),
    ),
  );
}
