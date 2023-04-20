import 'package:flutter/material.dart';
import 'package:michael_chess/screens/ChessBoardScreen.dart';



const anderssenDufresne = '[Event "Casual Game"]\n'
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


const fischerSpassky = '''
[Event "World Chess Championship"]
[Site "Reykjavik, Iceland"]
[Date "1972.07.21"]
[Round "1"]
[White "Bobby Fischer"]
[Black "Boris Spassky"]
[Result "1-0"]

1.e4 e5 2.Nf3 Nc6 3.Bb5 a6 4.Ba4 Nf6 5.O-O Be7 6.Re1 b5 7.Bb3 d6
8.c3 O-O 9.h3 Nb8 10.d4 Nbd7 11.Nbd2 Bb7 12.Bc2 Re8 13.Nf1 Bf8 14.Ng3 g6
15.b3 Bg7 16.d5 Qe7 17.c4 c6 18.Be3 Rec8 19.Qd2 Qf8 20.Rad1 cxd5 21.cxd5 a5
22.Bd3 Ba6 23.Rc1 Qd8 24.Rxc8 Rxc8 25.Rc1 Rxc1+ 26.Qxc1 Qb8 27.Qc6 Bc8
28.Bxb5 Bf8 29.Nd2 Nc5 30.Bxc5 dxc5 31.Nc4 Bd7 32.Qxf6 Bxb5 33.Nxe5 Qc7
34.Nc6 a4 35.e5 axb3 36.axb3 Bxc6 37.dxc6 Bg7 38.Qd6 Bxe5 39.Qxc7 Bxc7
40.Ne4 Bb6 41.Nf6+ Kg7 42.Nd7 Ba7 43.c7 1-0
''';

const fischerReshevsky = '''
[Event "Portoroz Interzonal"]
[Site "Portoroz YUG"]
[Date "1958.10.06"]
[EventDate "1958.09.15"]
[Round "17"]
[Result "1-0"]
[White "Robert James Fischer"]
[Black "Samuel Reshevsky"]
[ECO "B32"]
[WhiteElo "?"]
[BlackElo "?"]
[PlyCount "75"]

1.e4 c5 2.Nf3 Nc6 3.d4 cxd4 4.Nxd4 g6 5.Nc3 Bg7 6.Be3 Nf6 7.Bc4 O-O 8.Bb3 d6 9.f3 Bd7 10.Qd2 Rc8 11.h4 Ne5 12.O-O-O Nc4 13.Bxc4 Rxc4 14.h5 Nxh5 15.g4 Nf6 16.Bh6 Nxe4 17.Qe3 Nxc3 18.Bxg7 Nxd1 19.Qh6 f6 20.Bxf8 Kf7 21.Qxh7+ Kxf8 22.Qh8+ Kf7 23.Rh7# 1-0
''';


const fischerSpassky2 = '''
[Event "Reykjavik WCC"]
[Site "Reykjavik ISL"]
[Date "1972.08.31"]
[EventDate "?"]
[Round "6"]
[Result "1-0"]
[White "Robert James Fischer"]
[Black "Boris Spassky"]
[ECO "D59"]
[WhiteElo "?"]
[BlackElo "?"]
[PlyCount "81"]

1.d4 Nf6 2.c4 e6 3.Nf3 d5 4.Nc3 Be7 5.Bg5 h6 6.Bh4 O-O 7.e3 b6 8.Rc1 Bb7 9.cxd5 Nxd5 10.Bxe7 Qxe7 11.Nxd5 Bxd5 12.Bc4 Qb4+ 13.Qd2 Qxd2+ 14.Kxd2 Bxc4 15.Rxc4 c6 16.Ne5 Rc8 17.Rhc1 f6 18.Nxc6 Nxc6 19.Rxc6 Rxc6 20.Rxc6 Kf7 21.Rc7+ Kg6 22.Kd3 f5 23.f3 Kf6 24.e4 fxe4+ 25.fxe4 a5 26.Rc6 Rb8 27.d5 b5 28.Rxe6+ Kf7 29.Ra6 a4 30.e5 Rd8 31.Kd4 Rc8 32.Rc6 Rd8 33.Kc5 Re8 34.e6+ Kf6 35.Kxb5 Rb8+ 36.Rb6 Rd8 37.Kc6 Ke5 38.e7 Re8 39.Kd7 Ra8 40.e8=Q+ Rxe8 41.Kxe8 Kxd5 42.Rb4 1-0
''';

class MenuScreen extends StatelessWidget {


  const MenuScreen({Key? key}) : super(key: key);



  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a chess game'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            ElevatedButton(
              onPressed: () {
                // Navigate to the first chess game
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChessBoardScreen(pgnString: fischerSpassky),
                  ),
                );              },
              child: const Text('Fisher Spassky 1972'),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                // Navigate to the second chess game
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const ChessBoardScreen(pgnString: anderssenDufresne),
                  ),
                );
              },
              child: const Text('Andersseen Dufresne 1852'),
            ),
          ],
        ),
      ),
    );
  }
}
