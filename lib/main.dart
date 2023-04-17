import 'dart:io';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_chess_board/flutter_chess_board.dart';
import 'package:stockfish/stockfish.dart';
import 'package:chess/chess.dart' as chessLib;







void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Stockfish Example',
      home: ChessBoardScreen(),
    );
  }
}

class ChessBoardScreen extends StatefulWidget {
  @override
  _ChessBoardScreenState createState() => _ChessBoardScreenState();
}

class _ChessBoardScreenState extends State<ChessBoardScreen> {
  late ChessBoardController _controller;
  late Stockfish _stockfish;

  String _eval = 'Evaluation: N/A';

  final test_pgn = '''
 [Event "F/S Return Match"]
 [Site "Belgrade, Serbia JUG"]
 [Date "1992.11.04"]
 [Round "29"]
 [White "Fischer, Robert J."]
 [Black "Spassky, Boris V."]
 [Result "1/2-1/2"]
 
 1. e4 e5 2. Nf3 Nc6 3. Bb5 a6 4. Ba4 Nf6 5. O-O Be7 6. Re1 b5
 7. Bb3 d6 8. c3 O-O 9. h3 Na5 10. Bc2 c5 11. d4 Qc7 12. Nbd2 Bd7
 13. Nf1 Rfc8 14. Ne3 cxd4 15. cxd4 Nc6 16. d5 Nb4 17. Bb1 a5
 18. Bd2 Na6 19. Bd3 Nc5 20. Rc1 Qb7 21. Bb1 Ncxe4 22. Rxc8+ Bxc8
 23. Bxa5 Nxf2 24. Kxf2 Rxa5 25. Kg1 g6 26. Qd2 Ra8 27. Rd1 Bd8
 28. Kh2 Bb6 29. Nc2 Bc5 30. b4 Bb6 31. Ne3 Bd7 32. Nf1 Ra3
 33. Ng3 Be3 34. Qb2 Qa7 35. Rd3 Rxd3 36. Bxd3 Bf4 37. Ng1 Nh5
 38. N1e2 Nxg3 39. Nxg3 Qe3 40. Be2 Bxg3+ 41. Kh1 Qf2 42. Qc1 Qxe2
 43. a3 Bxh3 44. Qg1 Bf5 45. Qc1 Be4 46. Qc8+ Kg7 47. Qh3 Qf1#
''';

  @override
  void initState() {
    super.initState();
    _controller = ChessBoardController();

    final pgn = '[Event "Casual Game"]\n'
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

    final chess = Chess();
    chess.load_pgn(pgn);


    // load the pgn
    // _controller.loadPGN(pgn);
    // loop through the moves of the game

    // Get the moves in the game

    _initStockfish();

    // Loop through getHistory and make each move

    for(int i = 0; i< chess.history.length; i++) {
     int from = chess.history[i].move.from;
     int to  = chess.history[i].move.to;

     String fromSquare =  Chess.SQUARES.entries.firstWhere((entry) => entry.value == from).key; // Convert to algebraic notation
     String toSquare =  Chess.SQUARES.entries.firstWhere((entry) => entry.value == to).key; // Convert to algebraic notation


     Future<void> makeMove() async {
       // Add a 3 second delay before making the move
       await Future.delayed(Duration(seconds: 3));

       // Make the move
       // ...
       _controller.makeMove(from: fromSquare, to: toSquare);

     }
     makeMove();

    }
  }

  void _initStockfish() async {
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

  void _onMove() {
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
        title: Text('Chess Board'),
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
          Text(_eval),
        ],
      ),
    );
  }
}