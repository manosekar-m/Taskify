import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:taskify/theme/palette.dart';
import 'screens/home_screen.dart';
import 'models/task.dart';
import 'models/subtask.dart';
import 'models/note.dart';
import 'models/user.dart';
import 'screens/splash_screen.dart';
import 'services/notification_service.dart';
import 'services/hive_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await NotificationService().init();
  await Hive.initFlutter();
  Hive.registerAdapter(TaskAdapter());
  Hive.registerAdapter(SubtaskAdapter());
  Hive.registerAdapter(NoteAdapter());
  Hive.registerAdapter(UserAdapter());
  
  await Hive.openBox<Task>(HiveService.taskBoxName);
  await Hive.openBox<Subtask>(HiveService.subtaskBoxName);
  await Hive.openBox<Note>(HiveService.noteBoxName);
  await Hive.openBox<User>(HiveService.userBoxName);
  await Hive.openBox('session');
  await Hive.openBox('settings');
  runApp(const TaskifyApp());
}

class TaskifyApp extends StatelessWidget {
  const TaskifyApp({super.key});

  @override
  Widget build(BuildContext context) {
    final settingsBox = Hive.box('settings');

    return ValueListenableBuilder(
      valueListenable: settingsBox.listenable(),
      builder: (context, Box settings, _) {
        final bool isDarkMode = settings.get('isDarkMode', defaultValue: false);

        final lightThemeBase = ThemeData(
          useMaterial3: true,
          brightness: Brightness.light,
          primaryColor: Palette.primary,
          scaffoldBackgroundColor: Palette.backgroundLight,
          cardColor: Palette.surfaceLight,
          hintColor: Palette.hintLight,
          dividerColor: Palette.dividerLight,
        );

        final darkThemeBase = ThemeData(
          useMaterial3: true,
          brightness: Brightness.dark,
          primaryColor: Palette.primary,
          scaffoldBackgroundColor: Palette.backgroundDark,
          cardColor: Palette.surfaceDark,
          hintColor: Palette.hintDark,
          dividerColor: Palette.dividerDark,
        );

        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'Taskify',
          themeMode: isDarkMode ? ThemeMode.dark : ThemeMode.light,
          theme: lightThemeBase.copyWith(
            textTheme: GoogleFonts.plusJakartaSansTextTheme(lightThemeBase.textTheme),
            colorScheme: ColorScheme.fromSeed(
          seedColor: Palette.primary,
              brightness: Brightness.light,
              primary: Palette.primary,
              secondary: Palette.secondary,
              surface: Palette.surfaceLight,
              error: Palette.errorLight,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF18181B),
              contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              actionTextColor: const Color(0xFF818CF8),
              elevation: 8,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          darkTheme: darkThemeBase.copyWith(
            textTheme: GoogleFonts.plusJakartaSansTextTheme(darkThemeBase.textTheme),
            colorScheme: ColorScheme.fromSeed(
              seedColor: Palette.secondary,
              brightness: Brightness.dark,
              primary: Palette.primary,
              secondary: Palette.secondary,
              surface: Palette.surfaceDark,
              error: Palette.errorDark,
            ),
            snackBarTheme: SnackBarThemeData(
              backgroundColor: const Color(0xFF27272A),
              contentTextStyle: GoogleFonts.plusJakartaSans(color: Colors.white, fontWeight: FontWeight.w600),
              actionTextColor: const Color(0xFFF472B6),
              elevation: 8,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            ),
          ),
          home: const SplashScreen(
            nextScreen: HomeScreen(),
          ),
        );
      },
    );
  }
}
