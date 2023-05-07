import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';
import 'package:yaml/yaml.dart';

import '../MoveInfo.dart';

class ChessBoardScreen extends StatefulWidget {
  final String titleString;
  final String pgnString;
  final List<MoveInfo> bestMoves;


  const ChessBoardScreen(
      {super.key, required this.titleString, required this.pgnString,   required this.bestMoves, });

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
  late final List<MoveInfo> bestMoves;

  late Future<List<Object>> masterTuple;

  late Future<List<Object>> humanMove;

  // Define two state variables to hold the evaluations
  int? _bestMoveEvaluation;
  int? _bestMoveBlackEvaluation;
  int? _userMoveEvaluation;
  String? _bestMoveWhite;
  String? _bestMoveBlack;
  String? _bestMoveBlackForUserMove;

  String? _fenWithYourMove;

  @override
  void initState() {
    super.initState();
    final pgnString = widget.pgnString;

    bestMoves = widget.bestMoves;

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
    // _precomputeMoves();
  }

  void _precomputeMoves() async {
    List<MoveInfo> moveInfoList = [];

    int moveIndex = 0;
    int turnNumber = 0;

    // Best move
    for (int i = 0; i < moves.length; i++) {
      turnNumber = i + 1;

      masterMoveNotation = getMoveFromPGN(i, 'white');
      opponentMoveNotation = getMoveFromPGN(i, 'black');

      String fen = _controller.getFen();
      const depth = 15;
      final bestMoveWhiteTuple = await evalResult(fen, depth, false);

      final bestMoveWhite = bestMoveWhiteTuple[0] as String;
      final evaluationWhite = bestMoveWhiteTuple[1] as int;

      MoveInfo moveInfoWhite = MoveInfo(
        '$turnNumber.$masterMoveNotation',
        '$turnNumber.$bestMoveWhite',
        evaluationWhite,
      );
      moveInfoList.add(moveInfoWhite);

      print("Move: ${moveInfoWhite.move}");
      print("Best Move: ${moveInfoWhite.bestMove}");
      print("Evaluation: ${moveInfoWhite.evaluation}");

      // move white
      makeMoveFromIndex(moveIndex);
      moveIndex++;

      //now evaluate black
      //updated fen
      fen = _controller.getFen();
      final bestMoveBlackTuple = await evalResult(fen, depth, true);

      final bestMoveBlack = bestMoveBlackTuple[0] as String;
      final evaluationBlack = bestMoveBlackTuple[1] as int;
      MoveInfo moveInfoBlack = MoveInfo(
        '..$turnNumber.$opponentMoveNotation',
        '..$turnNumber.$bestMoveBlack',
        evaluationBlack,
      );
      print("Move: ${moveInfoBlack.move}");
      print("Best Move: ${moveInfoBlack.bestMove}");
      print("Evaluation: ${moveInfoBlack.evaluation}");
      moveInfoList.add(moveInfoBlack);
      if (turnNumber != moves.length) {
        // move black
        try {
          makeMoveFromIndex(moveIndex);
          moveIndex++;
        } catch (e) {
          String stringMoveInfo = moveInfoList.toString();
          print(stringMoveInfo);
        }
      }
      print("STATE OF THE LIST");
      String stringMoveInfo = moveInfoList.toString();
      print(stringMoveInfo);

      // Store the results in a data structure or file
      // ...
    }
    String stringMoveInfo = moveInfoList.toString();
    print(stringMoveInfo);
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
/*    _stockfish.stdout.listen((line) {
      print("StockFish output: $line");
      final pattern = RegExp(r'^Final evaluation\s+(\S+)\s+\(white side\)');
      final match = pattern.firstMatch(line);
      if (match != null) {
        final score = match.group(1)!;
        setState(() {
          _eval = 'Evaluation: $score';
        });
      }
    });*/
    //do this when necessary to get the computer moves
    // _precomputeMoves();
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

    // wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    resetBoardWithoutLastMove();
    // Get the cp after the move was played.

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
    // _prepStockfish();

    // Wait for both futures to complete concurrently
    // ok request the evaluation here
    final userEvaluationFuture =
        getBestMoveAndEvaluation(_fenWithYourMove!, 15);
    final results = await userEvaluationFuture;

    final bestMoveBlack = results[0];
    final userMoveEvaluation = results[1];

    // Update the state of your widget with the new evaluation results
    setState(() {
      _bestMoveBlackForUserMove = bestMoveBlack as String?;
      _userMoveEvaluation = userMoveEvaluation as int?;
      // set the best moves
      _bestMoveWhite = bestMoves[_currentMoveIndex - 2].bestMove;
      _bestMoveEvaluation = bestMoves[_currentMoveIndex -2 ].evaluation;
      _bestMoveBlack = bestMoves[_currentMoveIndex - 1].bestMove;
      _bestMoveBlackEvaluation = bestMoves[_currentMoveIndex - 1].evaluation;
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

  Future<List<Object>> evalResult(String fen, int depth, bool flip) async {
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
        int score;

        if (flip) {
          score =
              cp * -1; //flipped because we're looking at the user perspective
        } else {
          score = cp;
        }

        subscription?.cancel();
        completer.complete([bestMove, score]);
      }
    });
    return completer.future;
  }

  Future<List<Object>> getBestMoveAndEvaluation(String fen, int depth) async {
    final evalResulted = await evalResult(fen, depth, true);
    final bestMove = evalResulted[0] as String;
    final evaluation = evalResulted[1] as int;

    print("Best move: $bestMove");
    print("Evaluation: $evaluation");

    return [bestMove, evaluation];
  }

  void _prepStockfish() {
    // prep stockfish
    _stockfish.stdin = 'isready \n';
    _stockfish.stdin = 'go movetime 3000 \n';
    _stockfish.stdin = 'go infinite \n';
    _stockfish.stdin = 'uci\n';
    _stockfish.stdin = 'stop \n';
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
                    "Best Move White: $_bestMoveWhite",
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
                    "Best Move Black: $_bestMoveBlack",
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
                    "Best Response (YM): $_bestMoveBlackForUserMove",
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
