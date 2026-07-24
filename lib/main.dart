import 'package:flutter/material.dart';
import 'package:scientific_calculator/views/home.dart';
import 'package:get/get.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});
  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Scientific Calculator',
      theme: ThemeData(),
      home: const HomePage(),
    );
  }
}
