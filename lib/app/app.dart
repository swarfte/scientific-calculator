import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/calculator/view/calculator_screen.dart';
import 'theme.dart';
import 'theme_settings.dart';

class ScientificCalculatorApp extends ConsumerWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeSettingsProvider).themeMode;

    return MaterialApp(
      title: 'Scientific Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: themeMode,
      home: const CalculatorScreen(),
    );
  }
}
