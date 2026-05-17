import 'package:flutter/material.dart';

import 'playground_screen.dart';

void main() => runApp(const PlaygroundApp());

class PlaygroundApp extends StatelessWidget {
  const PlaygroundApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Moamalat Pay Playground',
      theme: ThemeData(colorSchemeSeed: Colors.indigo, useMaterial3: true),
      home: const PlaygroundScreen(),
    );
  }
}
