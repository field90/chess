import 'package:flutter/material.dart';
import 'package:michael_chess/MoveInfo.dart';
import 'package:michael_chess/screens/ChessBoardScreen.dart';

import 'package:flutter/services.dart' show rootBundle;
import 'package:yaml/yaml.dart';

class Game {
  final String title;
  final String pgn;
  final List<MoveInfo> bestMoves; // Add this property

  Game({required this.title, required this.pgn, required this.bestMoves}); // Update the constructor
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
        final List<dynamic>? bestMovesList = gameData['bestMoves'] as List<dynamic>?;


        final List<MoveInfo> bestMoves = (bestMovesList != null && bestMovesList.isNotEmpty)
            ? bestMovesList.map((move) {
          final YamlMap moveMap = move as YamlMap;
          final String moveString = moveMap['move'] as String;
          final String bestMoveString = moveMap['bestMove'] as String;
          final int evaluation = moveMap['evaluation'] as int;
          return MoveInfo(moveString, bestMoveString, evaluation);
        }).toList()
            : [];

        games.add(Game(
          title: gameData['title'],
          pgn: gameData['pgn'],
          bestMoves: bestMoves, // Pass the bestMoves to the Game object
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
                builder: (context) => ChessBoardScreen(titleString: game.title, pgnString: game.pgn, bestMoves: game.bestMoves,),
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
