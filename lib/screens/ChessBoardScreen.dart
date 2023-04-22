import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';
import 'package:tuple/tuple.dart';


class ChessBoardScreen extends StatefulWidget {
  final String titleString;
  final String pgnString;

  const ChessBoardScreen({super.key, required this.titleString, required this.pgnString});

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
  String _bestMove = "";

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
    chess = Chess();
    chess.load_pgn(pgnString);
    _initStockFish();

    // start the process of calcuating the next move.

    // _prepStockfish();
  }

  /*
      Makes the move from a half turn and puts it on the board
   */
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

      // Listen for the best move
      final patternBestMove = RegExp(r'^bestmove (\S+)(?: ponder (\S+))?\s*$');
      final matchBestMove = patternBestMove.firstMatch(line);
      if (matchBestMove != null) {
        final bestMove = matchBestMove.group(1)!;
        setState(() {
          _bestMove = 'Best move: $bestMove';
        });
      }
    });
    try {
      await getBestMoveAndEvaluation();
      // Rest of your code here...
    } catch (e) {
      // Handle any errors that may have occurred...
      print(e);
    }
    // _prepStockfish();
  }

  Future<String> getBestMove(String fen, int depth) async {
    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth $depth\n';
    final completer = Completer<String>();
    var buffer = StringBuffer();

    StreamSubscription? subscription;
    subscription = _stockfish.stdout.listen((data) {
      buffer.write(data);
      if (buffer.toString().contains('bestmove')) {
        subscription?.cancel();
        final moveLine = buffer.toString().trim().split('\n').last;
        final move = moveLine.split(' ').last;
        completer.complete(move);
      }
    });

    return completer.future;
  }
  Future<int> getEvaluation(String fen, int depth) async {
    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth $depth\n';
    final completer = Completer<int>();
    var buffer = StringBuffer();

    StreamSubscription? subscription;
    subscription = _stockfish.stdout.listen((data) {
      buffer.write(data);
      if (buffer.toString().contains('score')) {
        subscription?.cancel();
        final scoreLine = buffer.toString().trim().split('\n').last;
        int cpIndex = scoreLine.indexOf("score cp");
        String cpString = scoreLine.substring(cpIndex + 8).trimLeft();
        int spaceIndex = cpString.indexOf(" ");
        int cp = int.parse(cpString.substring(0, spaceIndex));

        final score = cp;
        completer.complete(score);
      }
    });

    return completer.future;
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

  String move_to_san(Move move) {
    // Create a copy of the current board state
    var boardCopy = Chess.fromFEN(_controller.getFen());

    // Make the move on the copied board
    boardCopy.move(move);

    // Calculate the SAN notation based on the state of the copied board
    var moves = boardCopy.moves();
    var moveText = move.toString();
    for (var i = 0; i < moves.length; i++) {
      if (moves[i].toString() == moveText) {
        return boardCopy.move_to_san(moves[i]);
      }
    }

    // If we didn't find a matching move, return an empty string
    return "";
  }

  // on user input
  Future<void> _onMove() async {
    // Get the current state of the board


    lastMoveNotation = _controller.getSan().last!;
    // Print the last move notation
    print(lastMoveNotation);

// wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    resetBoardWithoutLastMove();
// wait for 1 second

    masterMoveNotation = getMoveFromPGN(_currentTurnIndex, 'white');
    opponentMoveNotation = getMoveFromPGN(_currentTurnIndex, 'black');

    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;
    // play opponent move too
    // wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;
    _currentTurnIndex++;
    _prepStockfish();
  }

  void makeMoveString() {}

  void resetBoardWithoutLastMove() {
    List history = _controller.game.history;
    _controller.resetBoard();
    for (int i = 0; i < history.length - 1; i++) {
      makeMoveFromIndex(i);
    }
  }

  Future<Tuple2<String, int>> getBestMoveAndEvaluation() async {
    final bestMove = await getBestMove(_controller.getFen(), 15);
    print("Best move: $bestMove");

    final evaluation = await getEvaluation(_controller.getFen(), 15);

    print("Evaluation: $evaluation");
    return Tuple2<String, int>(bestMove, evaluation);
  }

  void _prepStockfish() {
    final fen = _controller.getFen();

    // prep stockfish
    _stockfish.stdin = 'isready \n';
    _stockfish.stdin = 'go movetime 3000 \n';
    _stockfish.stdin = 'go infinite \n';
    _stockfish.stdin = 'stop \n';

    // give it position
    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth 15\n';

    // eval
    _stockfish.stdin = 'eval \n';
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
