import 'package:flutter/material.dart';
import 'package:michael_chess/screens/ChessBoardScreen.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class Game {
  final String title;
  final String pgn;

  Game({required this.title, required this.pgn});
}

Future<Map<String, List<Game>>> loadGames() async {
  final Map<String, List<Game>> gameCategories = {};

  try {
    final yamlData = await rootBundle.loadString('assets/games.yaml');
    final gamesData = loadYaml(yamlData) as YamlMap;

    for (final category in gamesData.keys) {
      final List<dynamic> gamesList = gamesData[category];
      final List<Game> games = [];

      for (final gameData in gamesList) {
        games.add(Game(
          title: gameData['title'],
          pgn: gameData['pgn'],
        ));
      }

      gameCategories[category] = games;
    }
  } catch (e) {
    print("exception: $e");
  }

  return gameCategories;
}

class CategoryScreen extends StatelessWidget {
  final List<Game> games;
  final String category;

  CategoryScreen({required this.games, required this.category});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(category),
      ),
      body: ListView(
        children: games.map((game) => ListTile(
          title: Text(game.title),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChessBoardScreen(pgnString: game.pgn),
              ),
            );
          },
        )).toList(),
      ),
    );
  }
}

class MenuScreen extends StatelessWidget {
  const MenuScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Select a chess game'),
      ),
      body: FutureBuilder<Map<String, List<Game>>>(
        future: loadGames(),
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            final Map<String, List<Game>> gameCategories = snapshot.data!;
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: gameCategories.keys.map((category) => ElevatedButton(
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => CategoryScreen(games: gameCategories[category]!, category: category),
                      ),
                    );
                  },
                  child: Text(category),
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
