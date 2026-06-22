import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/theme/app_theme.dart';
import 'services/hive_service.dart';

/// App entry point. We must initialize Hive (and open its boxes) *before*
/// `runApp`, because the DI providers read boxes synchronously. We also lock the
/// system UI overlay to match the pure-black canvas.
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(AppTheme.overlayStyle);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  await HiveService.init();

  runApp(const ProviderScope(child: BulbulApp()));
}
