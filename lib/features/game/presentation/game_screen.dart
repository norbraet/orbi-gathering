import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GameScreen extends StatelessWidget {
  const GameScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Game')),
      body: Center(
        child: FilledButton(
          onPressed: () => context.go('/'),
          child: const Text('Back to home'),
        ),
      ),
    );
  }
}
