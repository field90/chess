
import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';

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

class ChessBoardScreen extends StatefulWidget {
  const ChessBoardScreen({super.key});

  @override
  _ChessBoardScreenState createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late ChessBoardController _controller;
  late Stockfish _stockfish;
  late Chess chess;

  String _eval = 'Evaluation: N/A';
  int _currentMoveIndex = 0;

  String lastMoveNotation = "";

  @override
  void initState() {
    super.initState();
    _controller = ChessBoardController();


    const pgn = '[Event "Casual Game"]\n'
        '[Site "Berlin GER"]\n'
        '[Date "1852.??.??"]\n'
        '[EventDate "?"]\n'
        '[Round "?"]\n'
        '[Result "1-0"]\n'
        '[White "Adolf Anderssen"]\n'
        '[Black "Jean Dufresne"]\n'
        '[ECO "C52"]\n'
        '[PlyCount "47"]\n'
        '\n'
        '1.e4 e5 2.Nf3 Nc6 3.Bc4 Bc5 4.b4 Bxb4 5.c3 Ba5 6.d4 exd4 7.O-O\n'
        'dxc3 8.Qb3 Qf6 9.e5 Qg6 10.Nxc3 Nge7 11.Ba3 O-O 12.Rad1 Bxc3 13.Qxc3\n'
        'Re8 14.Rfe1 Nd8 15.Nh4 Qh5 16.g3 Ne6 17.f4 Nf5 18.Be2 Qxh4 19.gxh4 Nxf4\n'
        '20.Bg4 Nxh4 21.Qg3 Nfg6 22.Bh5 b6 23.Bxg6 Nxg6 24.h4 h5 25.Qg5 Bb7 26.Rxd7\n'
        'Bf3 27.e6 1-0';

    chess = Chess();
    chess.load_pgn(pgn);
    _initStockFish();

  }
  /*
      Makes the move from a half turn and puts it on the board
   */
  makeMoveFromIndex(int i) {
    int from = chess.history[i].move.from;
    int to  = chess.history[i].move.to;

    String fromSquare =  Chess.SQUARES.entries.firstWhere((entry) => entry.value == from).key; // Convert to algebraic notation
    String toSquare =  Chess.SQUARES.entries.firstWhere((entry) => entry.value == to).key; // Convert to algebraic notation

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

  // on user input
  Future<void> _onMove() async {

    // Get the current state of the board
    final gameHistory = _controller.game.history;


// Get the last move
    Move lastMove = gameHistory.last.move;

// Convert the last move to SAN notation
    lastMoveNotation =  Chess().move_to_san(lastMove);

// Print the last move notation
     print(lastMoveNotation);

// wait for 1 second
    await Future.delayed(const Duration(seconds: 1));

    resetBoardWithoutLastMove();
// wait for 1 second

    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;
    // play opponent move too
    // wait for 1 second
    await Future.delayed(const Duration(seconds: 1));
    makeMoveFromIndex(_currentMoveIndex);
    _currentMoveIndex++;
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
              const SizedBox(height: 16), // add some spacing between the game board and the text fields
              Text("Your move: $lastMoveNotation"),
              const TextField(),
              const SizedBox(height: 16), // add some spacing between the text fields
              const Text("Master's move:"),
              const TextField(),
              const SizedBox(height: 16), // add some spacing between the text fields
              Text("Opponent's move:"),
              TextField(),
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
                child: const Text('Next Move'),
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