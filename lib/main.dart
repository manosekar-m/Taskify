import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'screens/login_screen.dart';
import 'screens/home_screen.dart';
import 'models/task.dart';
import 'models/user.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(UserAdapter());
  await Hive.openBox<Task>('tasks');
  await Hive.openBox<User>('users');
  await Hive.openBox('session');
  await Hive.openBox('settings');
  runApp(const TaskifyApp());
}

class TaskifyApp extends StatelessWidget {
  const TaskifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');
    final sessionBox = Hive.box('session');
    final currentUserEmail = sessionBox.get('currentUserEmail');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box settings, _) {
        final bool isDarkMode = settings.get('isDarkMode', defaultValue: false);

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taskify',
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: ThemeData(
            useMaterial3: false, // Explicitly disabled to avoid shader compilation
            brightness: Brightness.light,
            primaryColor: const Color(0xFF1A1A1A),
            scaffoldBackgroundColor: const Color(0xFFF9F9F7),
            fontFamily: 'Roboto',
            cardColor: Colors.white,
            hintColor: const Color(0xFF8E8E93),
            dividerColor: const Color(0xFFE5E5EA),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Colors.white,
              contentTextStyle: TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
              actionTextColor: const Color(0xFF64B5F6), // Slightly muted blue for better readability or use primary
              elevation: 4,
              behavior: SnackBarBehavior.floating,
            ),
          ),
          darkTheme: ThemeData(
            useMaterial3: false, // Explicitly disabled to avoid shader compilation
            brightness: Brightness.dark,
            primaryColor: Colors.white,
            scaffoldBackgroundColor: const Color(0xFF0D0D0D),
            fontFamily: 'Roboto',
            cardColor: const Color(0xFF1C1C1E),
            hintColor: const Color(0xFF8E8E93),
            dividerColor: const Color(0xFF2C2C2E),
            snackBarTheme: const SnackBarThemeData(
              backgroundColor: Color(0xFF1C1C1E),
              contentTextStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              actionTextColor: Colors.lightBlueAccent,
              elevation: 4,
              behavior: SnackBarBehavior.floating,
            ),
          ),
          home: SplashScreen(
            nextScreen: currentUserEmail != null ? const HomeScreen() : const LoginScreen(),
          ),
        );
      },
    );
  }
}
