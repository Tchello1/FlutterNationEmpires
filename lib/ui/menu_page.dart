import 'package:flutter/material.dart';

class MenuPage extends StatelessWidget {
  const MenuPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Civ Mobile')),
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              'Bem-vindo ao Civ Mobile!',
              style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 32),
            FilledButton(
              onPressed: () => Navigator.pushNamed(context, '/game'),
              child: const Text('Novo Jogo'),
            ),
            const SizedBox(height: 16),
            FilledButton.tonal(
              onPressed: () {},
              child: const Text('Opções'),
            ),
          ],
        ),
      ),
    );
  }
}
