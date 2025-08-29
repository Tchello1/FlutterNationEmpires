import 'package:flutter/material.dart';
import 'ui/menu_page.dart';
import 'ui/game_page.dart';

void main() => runApp(const CivMobileApp());

class CivMobileApp extends StatelessWidget {
  const CivMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Civ Mobile',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorSchemeSeed: Colors.teal,
      ),
      routes: {
        '/': (_) => const MenuPage(),
        '/game': (_) => const GamePage(),
      },
    );
  }
}
