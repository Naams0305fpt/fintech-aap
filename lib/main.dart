import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'theme/app_theme.dart';
import 'screens/home_screen.dart';
import 'screens/lock_screen.dart';
import 'providers/app_provider.dart';
import 'services/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set system UI style
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
      systemNavigationBarColor: AppTheme.surface,
      systemNavigationBarIconBrightness: Brightness.light,
    ),
  );

  // Initialize app
  final appProvider = AppProvider();
  await appProvider.init();

  runApp(
    ChangeNotifierProvider.value(value: appProvider, child: const FinTechApp()),
  );
}

class FinTechApp extends StatelessWidget {
  const FinTechApp({super.key});

  @override
  Widget build(BuildContext context) {
    final authService = AuthService.instance;

    return MaterialApp(
      title: 'FinTech',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme,
      // Show lock screen if PIN is enabled
      home: authService.isLockEnabled ? const LockScreen() : const HomeScreen(),
    );
  }
}
