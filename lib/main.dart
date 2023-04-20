
import 'package:flutter/material.dart';
import 'package:michael_chess/screens/ChessBoardScreen.dart';
import 'package:michael_chess/screens/MenuScreen.dart';

void main() => runApp(const MichaelChess());

class MichaelChess extends StatelessWidget {
  const MichaelChess({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Michael Chess',
      home: MenuScreen(),
    );
  }
}