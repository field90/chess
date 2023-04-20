import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';

class ChessBoardScreen extends StatefulWidget {
  final String pgnString;

  const ChessBoardScreen({super.key, required this.pgnString});
 

  @override
  _ChessBoardScreenState createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late ChessBoardController _controller;
  late Stockfish _stockfish;
  late Chess chess;
  late Chess otherchess;
  late List<String> moves;
  String _eval = 'Evaluation: N/A';
  int _currentMoveIndex = 0;
  int _currentTurnIndex = 0;

  String lastMoveNotation = "";
  String masterMoveNotation = "";
  String opponentMoveNotation = "";



  @override
  void initState() {
    super.initState();
    final pgnString = widget.pgnString;
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

    otherchess = Chess();
    _initStockFish();
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
    });
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
    // Get the current state of the board
    final gameHistory = _controller.game.history;


// Get the last move
    Move lastMove = gameHistory.last.move;

// Convert the last move to SAN notation
    lastMoveNotation = otherchess.move_to_san(lastMove);

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

  void _prepStockfish() {
    final fen = _controller.getFen();

    // prep stockfish
    _stockfish.stdin = 'isready \n';
    _stockfish.stdin = 'go movetime 3000 \n';
    _stockfish.stdin = 'go infinite \n';
    _stockfish.stdin = 'stop \n';

    // give it position
    _stockfish.stdin = 'position fen $fen\n';
    _stockfish.stdin = 'go depth 5\n';

    // eval
    _stockfish.stdin = 'eval \n';
  }

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
                  ),
                  const SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
                  ),
                  const SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
                  ),
                  const SizedBox(
                    width: 200,
                    child: TextField(
                      decoration: InputDecoration(
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
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
