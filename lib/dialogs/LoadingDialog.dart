import 'package:flutter/material.dart';

import '../Quote.dart';
import '../services/QuoteService.dart';

class LoadingDialog extends StatefulWidget {
  final String message;
  final Color backgroundColor;
  final Color textColor;
  final double radius;

  LoadingDialog({
    this.message = 'Loading...',
    this.backgroundColor = Colors.black54,
    this.textColor = Colors.white,
    this.radius = 10.0,
  });

  void show(BuildContext context) {
    _initializeQuote().then((quote) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (BuildContext context) {
          return _buildDialog(context, quote);
        },
      );
    });
  }
  Future<Quote> _initializeQuote() async {
    Quote q = await QuoteService.getRandomQuote();
    return q;
  }

  void hide(BuildContext context) {
    Navigator.of(context).pop();
  }

  Widget _buildDialog(BuildContext context, Quote quote) {
    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      child: Container(
        padding: const EdgeInsets.all(16.0),
        decoration: BoxDecoration(
          color: backgroundColor,
          borderRadius: BorderRadius.circular(radius),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16.0),
            Text(
              message,
              style: TextStyle(
                color: textColor,
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 16.0),
            Text(
              quote.quote,
              style: TextStyle(
                color: textColor,
                fontSize: 16.0,
                fontStyle: FontStyle.italic,
              ),
            ),
            SizedBox(height: 8.0),
            Text(
              "-${quote.author}",
              style: TextStyle(
                color: textColor,
                fontSize: 16.0,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  _LoadingDialogState createState() => _LoadingDialogState();
}

class _LoadingDialogState extends State<LoadingDialog> {
  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
