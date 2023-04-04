import 'package:flutter/material.dart';
import 'package:chess/chess.dart' as chess;

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Chess Demo',
      theme: ThemeData(
        primarySwatch: Colors.blue,
      ),
      home: MyHomePage(),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  _MyHomePageState createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  chess.Chess _chess = chess.Chess();


  void _resetBoard() {
    setState(() {
      _chess = chess.Chess();
    });
  }
  void _runRandomGame() {
    while (!_chess.game_over) {
      print('position: ${_chess.fen}');
      print(_chess.ascii);
      var moves = _chess.moves();
      moves.shuffle();
      var move = moves[0];
      _chess.move(move);
      print('move: ' + move);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Chess Demo'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              'Current FEN:',
            ),
            Text(
              _chess.fen,
              style: Theme.of(context).textTheme.headline4,
            ),
            ElevatedButton(
              onPressed: _runRandomGame,
              child: const Text('Run Random Game'),
            ),
          ],
        ),
      ),
    );
  }
}