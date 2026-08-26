import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'screens/main_navigation_screen.dart';
import 'screens/onboarding_screen.dart';
import 'utils/app_theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Inisialisasi format tanggal bahasa Indonesia
  await initializeDateFormatting('id_ID', null);

  // Cek apakah sudah pernah melihat intro onboarding
  final prefs = await SharedPreferences.getInstance();
  final bool hasSeenOnboarding = prefs.getBool(OnboardingScreen.prefKey) ?? false;

  // Set status bar transparan modern
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.cardBg,
      systemNavigationBarBrightness: Brightness.dark,
    ),
  );

  runApp(
    ProviderScope(
      child: MaoneArtKeuanganApp(showOnboarding: !hasSeenOnboarding),
    ),
  );
}

class MaoneArtKeuanganApp extends StatelessWidget {
  final bool showOnboarding;
  const MaoneArtKeuanganApp({super.key, required this.showOnboarding});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'MaoneArt Keuangan',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: showOnboarding ? const OnboardingScreen() : const MainNavigationScreen(),
    );
  }
}
