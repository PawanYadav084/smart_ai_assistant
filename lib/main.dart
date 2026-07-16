
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'features/splash/presentation/splash_screen.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await dotenv.load(fileName: ".env");
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  runApp(const SmartAIAssistantApp());
}


class SmartAIAssistantApp extends StatefulWidget {
  const SmartAIAssistantApp({super.key});

  @override
  State<SmartAIAssistantApp> createState() => _SmartAIAssistantAppState();
}

class _SmartAIAssistantAppState extends State<SmartAIAssistantApp> {
  final ThemeService _themeService = ThemeService.instance;

  @override
  void initState() {
    super.initState();
    _themeService.loadTheme();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _themeService,
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Smart AI Assistant',
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          themeMode: _themeService.themeMode,
          home: const SplashScreen(),
        );
      },
    );
  }
}