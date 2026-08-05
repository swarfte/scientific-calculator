import 'package:flutter/material.dart';

import '../features/calculator/view/calculator_screen.dart';
import 'theme.dart';

class ScientificCalculatorApp extends StatelessWidget {
  const ScientificCalculatorApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Scientific Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const CalculatorScreen(),
    );
  }
}
