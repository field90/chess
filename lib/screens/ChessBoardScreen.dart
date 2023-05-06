import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';
import 'dart:isolate';

class ChessBoardScreen extends StatefulWidget {
  final String titleString;
  final String pgnString;

  const ChessBoardScreen(
      {super.key, required this.titleString, required this.pgnString});

  @override
  _ChessBoardScreenState createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late ChessBoardController _controller;
  late Stockfish _stockfish;
  late Chess chess;
  late List<String> moves;
  String _eval = 'Evaluation: N/A';
  int _currentMoveIndex = 0;
  int _currentTurnIndex = 0;

  String lastMoveNotation = "";
  String masterMoveNotation = "";
  String opponentMoveNotation = "";
  String bestMoveNotation = "";

  String titleString = "";

  late Future<List<Object>> masterTuple;

  late Future<List<Object>> humanMove;

  // Define two state variables to hold the evaluations
  int? _bestMoveEvaluation;
  int? _userMoveEvaluation;
  String? _bestMoveBlack;

  String? _fenWithYourMove;

  @override
  void initState() {
    super.initState();
    final pgnString = widget.pgnString;
    titleString = widget.titleString;
    final moveText = pgnString.replaceAll(RegExp(r'\[.*\]\s*'), '');

    // Parse the PGN into moves
    // Filter out empty strings
    moves = moveText
        .replaceAll('\n', ' ')
        .split(RegExp(r'\d+\.'))
        .where((move) => move.isNotEmpty)
        .toList();
    _controller = ChessBoardController();
    // get the fen

    _fenWithYourMove = _controller.getFen();
    chess = Chess();
    chess.load_pgn(pgnString);

    _initStockFish();
    // start the process of calcuating the next move.
  }

  makeMoveFromIndex(int i) {
    int from = chess.history[i].move.from;
    int to = chess.history[i].move.to;

    String fromSquare = Chess.SQUARES.entries
        .firstWhere((entry) => entry.value == from)
        .key; // Convert to algebraic notation
    String toSquare = Chess.SQUARES.entries
        .firstWhere((entry) => entry.value == to)
        .key; // Convert to algebraic notation

    _controller.makeMove(from: fromSquare, to: toSquare);
  }

  void _initStockFish() async {
    _stockfish = await stockfishAsync();

    // for debugging purposes only now
    /*
    _stockfish.stdout.listen((line) {
      print("StockFish output: $line");
      final pattern = RegExp(r'^Final evaluation\s+(\S+)\s+\(white side\)');
      final match = pattern.firstMatch(line);
      if (match != null) {
        final score = match.group(1)!;
        setState(() {
          _eval = 'Evaluation: $score';
        });
      }
    });
    */
  }

  String getMoveFromPGN(int moveIndex, String color) {
    // Remove metadata at start of PGN

    final move = moves[moveIndex].trim().split(' ');

    if (color == 'white') {
      return move[0];
    } else if (color == 'black') {
      return move[1];
    } else {
      return move[0];
    }
  }

  // on user input
  Future<void> _onMove() async {
    _fenWithYourMove = _controller.getFen();
    // Listen for the completion of the future
    lastMoveNotation = _controller.getSan().last!;
    // Print the last move notation
    print(lastMoveNotation);

    // request the evaluation here
    final userEvaluationFuture = getBestMoveAndEvaluation(_fenWithYourMove!, 15);

    // wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    resetBoardWithoutLastMove();
    // Get the cp after the move was played.

    // wait for 1 second
    masterMoveNotation = getMoveFromPGN(_currentTurnIndex, 'white');
    opponentMoveNotation = getMoveFromPGN(_currentTurnIndex, 'black');

    // master move
    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;

    // play opponent move too
    // wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;
    _currentTurnIndex++;

    // ok request the evaluation here
    final results = await userEvaluationFuture;

    final bestMoveBlack = results[0];
    final userMoveEvaluation = results[1];

    // Update the state of your widget with the new evaluation results
    setState(() {
      _bestMoveBlack = bestMoveBlack as String?;
      _userMoveEvaluation = userMoveEvaluation as int?;
    });
    // Do something with the results, e.g. print them
    print("Best Move Black: $bestMoveBlack");
    print("User Move Evaluation: $userMoveEvaluation");

  }

  void makeMoveString() {}

  void resetBoardWithoutLastMove() {
    List history = _controller.game.history;
    _controller.resetBoard();
    for (int i = 0; i < history.length - 1; i++) {
      makeMoveFromIndex(i);
    }
  }

  Future<List<Object>> evalResult(String fen, int depth) async {

    // evaluate this position

    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth $depth\n';
    final completer = Completer<List<Object>>();
    var buffer = StringBuffer();

    StreamSubscription? subscription;
    subscription = _stockfish.stdout.listen((data) {
      buffer.write(data);
      if (buffer.toString().contains('bestmove')) {
        final bestMove = data.split(' ')[1];
        final scoreLine = buffer.toString().trim().split('\n').last;
        int cpIndex = scoreLine.indexOf("score cp");
        String cpString = scoreLine.substring(cpIndex + 8).trimLeft();
        int spaceIndex = cpString.indexOf(" ");
        int cp = int.parse(cpString.substring(0, spaceIndex));

        final score = cp * -1; //flipped because we're looking at the user perspective

        subscription?.cancel();
        completer.complete([bestMove, score]);
      }
    });

    _stockfish.stdin = 'position fen $fen';
    _stockfish.stdin = 'go depth $depth';

    return completer.future;
  }

  Future<List<Object>> getBestMoveAndEvaluation(String fen, int depth) async {
    final evalResulted = await evalResult(fen, depth);
    final bestMove = evalResulted[0] as String;
    final evaluation = evalResulted[1] as int;

    print("Best move: $bestMove");
    print("Evaluation: $evaluation");

    return [bestMove, evaluation];
  }

  void _prepStockfish() {
    final fen = _controller.getFen();

    // prep stockfish
    // prep stockfish
    _stockfish.stdin = 'isready \n';
    _stockfish.stdin = 'go movetime 3000 \n';
    _stockfish.stdin = 'go infinite \n';
    _stockfish.stdin = 'uci\n';
    _stockfish.stdin = 'stop \n';


    // // give it position
    // _stockfish.stdin = 'position fen $fen\n';
    // _stockfish.stdin = 'go depth 15\n';
    //
    // // eval
    // _stockfish.stdin = 'eval \n';
  }

/*
  double _scoreMove() {
    final fen = _controller.getFen();
    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth 5\n';
    // final score = _stockfish.getScore();

    // Normalize the score to a range of -10 to 10
    final normalizedScore = score / 100;
    final scoreOutOfTen = (normalizedScore + 1) * 5;
    return scoreOutOfTen;
  }
*/

  @override
  void dispose() {
    _controller.dispose();
    _stockfish.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MichaelChess'),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            child: Text('$titleString', style: TextStyle(fontSize: 24)),
          ),
          Expanded(
            child: Center(
              child: ChessBoard(
                controller: _controller,
                onMove: _onMove,
              ),
            ),
          ),
          Column(
            children: [
              const SizedBox(height: 16),
              // add some spacing between the game board and the text fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Your move: $lastMoveNotation",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              // add some spacing between the text fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Master's move: $masterMoveNotation",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              const SizedBox(height: 16),
              // add some spacing between the text fields
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Opponent's move: $opponentMoveNotation",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "User Move Evaluation (CP): $_userMoveEvaluation",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Best Move Evaluation (CP): $_bestMoveEvaluation",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Text(
                    "Best Move Opponent: $_bestMoveBlack",
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  )
                ],
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    makeMoveFromIndex(_currentMoveIndex);
                    // maybe not perfect, but this will get stockfish going
                     _prepStockfish();
                    _currentMoveIndex++;
                  });
                },
                child: const Text('Skip'),
              ),
              const SizedBox(width: 20),
              Text(_eval),
            ],
          ),
        ],
      ),
    );
  }
}
