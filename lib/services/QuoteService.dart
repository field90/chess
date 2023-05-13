import 'package:yaml/yaml.dart';
import 'package:flutter/services.dart' show rootBundle;

import '../Quote.dart';

class QuoteService {
  static Future<List<Quote>> getQuotes() async {
    String quotesYaml = await rootBundle.loadString('assets/chess_quotes.yaml');
    var quotesData = loadYaml(quotesYaml);

    List<Quote> quotes = [];

    for (var quote in quotesData['quotes']) {
      quotes.add(Quote.fromYaml(quote));
    }

    return quotes;
  }

  static Future<Quote> getRandomQuote() async {
    List<Quote> quotes = await getQuotes();
    int randomIndex = DateTime.now().millisecondsSinceEpoch % quotes.length;
    return quotes[randomIndex];
  }
}
