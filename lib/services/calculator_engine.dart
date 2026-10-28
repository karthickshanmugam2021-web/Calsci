import 'package:math_expressions/math_expressions.dart';

class CalculatorEngine {
  // Controlled error messages (expected situations, not app failures)
  static const String divideByZeroMessage = "Cannot divide by 0";
  static const String tooLargeMessage = "Result too large";
  static const String invalidMessage = "Error";

  /// True if [text] is one of the engine's error messages.
  bool isError(String text) {
    return text == divideByZeroMessage ||
        text == tooLargeMessage ||
        text == invalidMessage;
  }

  String evaluate(String expression) {
    try {
      // 1. Convert calculator symbols to parser symbols
      String text = expression.replaceAll("×", "*").replaceAll("÷", "/");

      // 2. Complete any decimal point not followed by a digit
      //    "5." -> "5.0"   and   "5.+3" -> "5.0+3"
      text = _completeDecimals(text);

      // 3. Turn every "number%" into plain arithmetic
      text = _resolvePercents(text);

      // 4. Parse and evaluate
      final Expression parsed = GrammarParser().parse(text);
      final double value =
          (parsed.evaluate(EvaluationType.REAL, ContextModel()) as num)
              .toDouble();

      // 5. Infinity / NaN: handle explicitly instead of crashing in toInt()
      if (value.isNaN || value.isInfinite) {
        return expression.contains("÷") ? divideByZeroMessage : tooLargeMessage;
      }

      // 6. Format for display only (the computed value is not rounded)
      return formatNumber(value);
    } catch (e) {
      return invalidMessage;
    }
  }

  /// "5." -> "5.0"; also fixes a dot in the middle ("5.+3" -> "5.0+3").
  String _completeDecimals(String text) {
    return text.replaceAllMapped(
      RegExp(r'(\d)\.(?!\d)'),
      (match) => '${match[1]}.0',
    );
  }

  /// Percentage rules:
  ///   A + n%  ->  A + (A * n / 100)   "n% of the total so far"
  ///   A - n%  ->  A - (A * n / 100)
  ///   A × n%  ->  A × (n / 100)
  ///   A ÷ n%  ->  A ÷ (n / 100)
  ///   n%      ->  n / 100
  /// "A" is everything to the left, back to the start or the enclosing "(".
  /// This is text substitution only: nothing is evaluated or rounded here.
  String _resolvePercents(String s) {
    final RegExp numberChar = RegExp(r'[0-9.]');
    int guard = 0;

    while (true) {
      final int p = s.indexOf('%');
      if (p == -1) return s;

      // Safety net against an endless loop
      if (++guard > 100) {
        throw const FormatException('Too many percent signs');
      }

      // The number written directly before the %
      int numStart = p;
      while (numStart > 0 && numberChar.hasMatch(s[numStart - 1])) {
        numStart--;
      }
      if (numStart == p) {
        throw const FormatException('% must follow a number');
      }
      final String number = s.substring(numStart, p);

      // The operator written before that number (if any)
      final int opIndex = numStart - 1;
      final String op = opIndex >= 0 ? s[opIndex] : '';

      if (op == '+' || op == '-') {
        // Find where the current group starts (start of text or open bracket)
        int depth = 0;
        int groupStart = 0;
        for (int i = opIndex - 1; i >= 0; i--) {
          if (s[i] == ')') {
            depth++;
          } else if (s[i] == '(') {
            if (depth == 0) {
              groupStart = i + 1;
              break;
            }
            depth--;
          }
        }

        final String left = s.substring(groupStart, opIndex);
        if (left.isNotEmpty) {
          final String replacement = '($left$op($left)*$number/100)';
          s = s.substring(0, groupStart) + replacement + s.substring(p + 1);
          continue;
        }
      }

      // Plain case: ×, ÷, start of expression, after "(", or a unary sign
      s = '${s.substring(0, numStart)}($number/100)${s.substring(p + 1)}';
    }
  }

  /// Display formatting. Keeps 15 significant digits (what a double reliably
  /// holds), which removes noise like 0.30000000000000004 -> 0.3.
  String formatNumber(double value) {
    if (value == 0) return "0";

    final double rounded = double.parse(value.toStringAsPrecision(15));
    final double magnitude = rounded.abs();

    // Very large / very small: scientific notation, trailing zeros trimmed
    if (magnitude >= 1e15 || magnitude < 1e-6) {
      final List<String> parts = rounded.toStringAsExponential(14).split('e');
      String mantissa = parts[0];
      if (mantissa.contains('.')) {
        mantissa = mantissa.replaceFirst(RegExp(r'\.?0+$'), '');
      }
      return '${mantissa}e${parts[1]}';
    }

    // Whole numbers: no ".0"
    if (rounded == rounded.truncateToDouble()) {
      return rounded.toStringAsFixed(0);
    }

    return rounded.toString();
  }
}