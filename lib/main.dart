
import 'package:flutter/material.dart';
import 'package:michael_chess/screens/ChessBoard.dart';

void main() => runApp(const MyApp());

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      title: 'Stockfish Example',
      home: ChessBoardScreen(),
    );
  }
}