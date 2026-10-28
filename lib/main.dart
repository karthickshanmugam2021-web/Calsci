import 'package:flutter/material.dart';
import 'screens/calculator_screen.dart';

void main() {
  runApp(const CalSciApp());
}

class CalSciApp extends StatelessWidget {
  const CalSciApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'CalSci',
      theme: ThemeData.dark(),
      home: const CalculatorScreen(),
    );
  }
}