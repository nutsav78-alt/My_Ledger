import 'package:flutter/material.dart';
import 'screens/business_profile_screen.dart';
import 'screens/profile_list_screen.dart';
import 'screens/main_shell.dart';
import 'services/storage_service.dart';

final ValueNotifier<ThemeMode> themeNotifier = ValueNotifier(ThemeMode.system);
final ValueNotifier<String> languageNotifier = ValueNotifier('English');
final ValueNotifier<String> dateTypeNotifier = ValueNotifier('AD');

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  final theme = await StorageService.getThemeMode();
  if (theme == 'light') {
    themeNotifier.value = ThemeMode.light;
  } else if (theme == 'dark') {
    themeNotifier.value = ThemeMode.dark;
  }

  final lang = await StorageService.getLanguage();
  languageNotifier.value = lang;

  final dateType = await StorageService.getDateType();
  dateTypeNotifier.value = dateType;

  final activeProfileId = await StorageService.getActiveProfileId();
  final allProfiles = await StorageService.getAllProfiles();
  
  Widget initial;
  if (activeProfileId != null) {
    final activeFY = await StorageService.getActiveFY() ?? '';
    initial = MainShell(activeFY: activeFY);
  } else if (allProfiles.isNotEmpty) {
    initial = const ProfileListScreen();
  } else {
    initial = const BusinessProfileScreen();
  }

  runApp(MyLedgerApp(initialScreen: initial));
}

class MyLedgerApp extends StatelessWidget {
  final Widget initialScreen;
  const MyLedgerApp({super.key, required this.initialScreen});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<ThemeMode>(
      valueListenable: themeNotifier,
      builder: (context, mode, child) {
        return MaterialApp(
          title: 'My Ledger',
          debugShowCheckedModeBanner: false,
          themeMode: mode,
          theme: ThemeData(
            colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
            useMaterial3: true,
            appBarTheme: const AppBarTheme(
              centerTitle: true,
              elevation: 0,
            ),
          ),
          darkTheme: ThemeData(
            colorScheme: ColorScheme.fromSeed(
              seedColor: Colors.teal,
              brightness: Brightness.dark,
            ),
            useMaterial3: true,
            brightness: Brightness.dark,
          ),
          home: initialScreen,
        );
      },
    );
  }
}
