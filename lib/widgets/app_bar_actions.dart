import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_state.dart';

/// Shared AppBar actions: theme toggle (sun/moon) + language toggle (EN/AR).
class ThemeLangActions extends StatelessWidget {
  const ThemeLangActions({super.key});

  @override
  Widget build(BuildContext context) {
    final state = context.watch<AppState>();
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          tooltip: state.isDark ? state.tr('lightMode') : state.tr('darkMode'),
          icon: Icon(state.isDark ? Icons.light_mode : Icons.dark_mode),
          onPressed: () => context.read<AppState>().toggleTheme(),
        ),
        TextButton(
          onPressed: () => context.read<AppState>().toggleLocale(),
          style: TextButton.styleFrom(
            foregroundColor: Theme.of(context).colorScheme.onSurface,
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          child: Text(
            state.isArabic ? 'EN' : 'AR',
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
        ),
      ],
    );
  }
}
