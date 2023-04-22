import 'package:flutter/material.dart';
import 'package:michael_chess/screens/ChessBoardScreen.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class Game {
  final String title;
  final String pgn;

  Game({required this.title, required this.pgn});
}

Future<List<Game>> loadGames() async {
  final List<Game> games = [];

  try {
    final yamlData = await rootBundle.loadString('assets/games.yaml');
    final gamesData = loadYaml(yamlData) as YamlMap;
    final List<dynamic> gamesList = gamesData['Classical Games'];



    for (final gameData in gamesList) {
      games.add(Game(
        title: gameData['title'],
        pgn: gameData['pgn'],
      ));
    }
  }catch(e){
    print("exception: $e");
  }



  return games;
}

class MenuScreen extends StatelessWidget {


  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a chess game'),
      ),
      body: FutureBuilder<List<Game>>(
        future: loadGames(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final List<Game> games = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: games.map((game) => ElevatedButton(
                  onPressed: () {
                    // Navigate to the chess game
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => ChessBoardScreen(pgnString: game.pgn),
                      ),
                    );
                  },
                  child: Text(game.title),
                )).toList(),
              ),
            );
          } else if (snapshot.hasError) {
            return Text('Error loading games data: ${snapshot.error}');
          } else {
            return CircularProgressIndicator();
          }
        },
      ),
    );
  }


}
