import 'package:flutter/material.dart';
import 'screens/home_screen.dart';

void main() => runApp(const MovisualApp());

class MovisualApp extends StatelessWidget {
  const MovisualApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Movisual Edge',
      theme: ThemeData.dark(),
      home: const HomeScreen(),
    );
  }
}
