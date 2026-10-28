import 'package:flutter/material.dart';

class CalculatorButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CalculatorButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  Color _getButtonColor() {
    if ("0123456789.".contains(text)) {
      return Colors.blueGrey;
    }

    if ("+-×÷=".contains(text)) {
      return Colors.orange;
    }

    return Colors.grey;
  }

  @override
Widget build(BuildContext context) {
  return SizedBox.expand(
    child: ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.all(8),
        backgroundColor: _getButtonColor(),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double fontSize = constraints.maxWidth * 0.8;

          return FittedBox(
            fit: BoxFit.scaleDown,
            child: Text(
              text,
              style: TextStyle(
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          );
        },
      ),
    ),
  );
}
}