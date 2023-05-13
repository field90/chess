import 'package:yaml/yaml.dart';

class Quote {
  final String author;
  final String quote;

  Quote({required this.author, required this.quote});

  factory Quote.fromYaml(dynamic yamlData) {
    final author = yamlData['author'] as String? ?? '';
    final quote = yamlData['quote'] as String? ?? '';

    return Quote(author: author, quote: quote);
  }
}
