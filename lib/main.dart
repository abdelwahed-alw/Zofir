import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:provider/provider.dart';
import 'app_state.dart';
import 'screens/setup_screen.dart';
import 'screens/home_screen.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox('expense_box');
  runApp(const SplitApp());
}

class SplitApp extends StatelessWidget {
  const SplitApp({super.key});

  ThemeData _light() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.light,
        ),
      );

  ThemeData _dark() => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.teal,
          brightness: Brightness.dark,
        ),
      );

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AppState()..init(),
      child: Consumer<AppState>(
        builder: (ctx, state, _) => MaterialApp(
          title: 'Roommates Split',
          debugShowCheckedModeBanner: false,
          theme: _light(),
          darkTheme: _dark(),
          themeMode: state.themeMode,
          locale: Locale(state.localeCode),
          // Force RTL when Arabic, LTR when English.
          builder: (context, child) => Directionality(
            textDirection:
                state.isArabic ? TextDirection.rtl : TextDirection.ltr,
            child: child!,
          ),
          home: !state.loaded
              ? const Scaffold(
                  body: Center(child: CircularProgressIndicator()))
              : state.hasUsers
                  ? const HomeScreen()
                  : const SetupScreen(),
        ),
      ),
    );
  }
}
