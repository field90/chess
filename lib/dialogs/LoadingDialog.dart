import 'package:flutter/material.dart';

class LoadingDialog extends StatelessWidget {
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

  late BuildContext _dialogContext;

  void show(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        _dialogContext = context;
        return _buildDialog();
      },
    );
  }

  void hide() {
    Navigator.of(_dialogContext).pop();
  }

  Widget _buildDialog() {
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
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container();
  }
}
