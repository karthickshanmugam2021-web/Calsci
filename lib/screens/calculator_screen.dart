import 'package:flutter/material.dart';
import '../widgets/calculator_appbar.dart';
import '../widgets/display.dart';
import '../constants/button_data.dart';
import '../widgets/calculator_button.dart';
import '../services/calculator_engine.dart';

class CalculatorScreen extends StatefulWidget {
  const CalculatorScreen({super.key});

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String expression = "0";
  String result = "";
  bool justCalculated = false;
  final CalculatorEngine engine = CalculatorEngine();

  // Maximum characters the user can type (prevents unreadable giant input)
  static const int maxExpressionLength = 60;

  // "%" is no longer an infix operator: it is a postfix mark after a number
  bool isOperator(String text) {
    return ["+", "-", "×", "÷"].contains(text);
  }

  bool isDigit(String text) {
    return RegExp(r'^[0-9]$').hasMatch(text);
  }

  // The number currently being typed ("" if the expression ends in a symbol)
  String currentNumber() {
    return expression.split(RegExp(r'[+\-×÷%()]')).last;
  }

  bool hasDecimalPoint() {
    return currentNumber().contains(".");
  }

  // How many "(" are still waiting for a ")"
  int openParenCount() {
    final int opens = expression.split("(").length - 1;
    final int closes = expression.split(")").length - 1;
    return opens - closes;
  }

  void onButtonPressed(String button) {
    setState(() {
      // ======================
      // AC
      // ======================
      if (button == "AC") {
        expression = "0";
        result = "";
        justCalculated = false;
        return;
      }

      // ======================
      // Backspace
      // ======================
      if (button == "⌫") {
        if (expression.length > 1) {
          expression = expression.substring(0, expression.length - 1);
        } else {
          expression = "0";
        }

        result = "";
        justCalculated = false;
        return;
      }

      // ======================
      // Equals
      // ======================
      if (button == "=") {
        // Pressing = again on a finished result does nothing
        if (justCalculated) return;

        // Auto-close any open brackets so "(2+3" works like "(2+3)"
        final int missing = openParenCount();
        if (missing > 0) {
          expression += ")" * missing;
        }

        result = engine.evaluate(expression);
        justCalculated = true;
        return;
      }

      // ======================
      // Typing after "="
      // ======================
      if (justCalculated) {
        final bool wasError = engine.isError(result);

        if (isDigit(button) || button == ".") {
          // Start a brand-new calculation
          expression = "0";
        } else {
          // Operator, %, or bracket: continue from the result,
          // but never from an error message
          if (wasError) return;
          expression = result;
        }
        result = "";
        justCalculated = false;
        // fall through: the normal rules below handle the button
      }

      // Input length limit
      if (expression.length >= maxExpressionLength) return;

      final String lastChar = expression[expression.length - 1];

      // ======================
      // Operators + - × ÷
      // ======================
      if (isOperator(button)) {
        // After "(" only a minus sign makes sense, e.g. (-5)
        if (lastChar == "(" && button != "-") return;

        // Replace the previous operator instead of stacking two
        if (isOperator(lastChar)) {
          if (expression.length >= 2 &&
              expression[expression.length - 2] == "(") {
            return;
          }
          expression =
              expression.substring(0, expression.length - 1) + button;
          result = "";
          return;
        }

        // "5." followed by an operator becomes "5.0+"
        if (lastChar == ".") {
          expression += "0";
        }

        expression += button;
        result = "";
        return;
      }

      // ======================
      // Percent (only directly after a digit)
      // ======================
      if (button == "%") {
        if (!isDigit(lastChar)) return;
        expression += "%";
        result = "";
        return;
      }

      // ======================
      // Smart bracket ( )
      // ======================
      if (button == "()") {
        final bool endsLikeNumber =
            isDigit(lastChar) || lastChar == ")" || lastChar == "%";

        // Close a bracket if one is open and the expression can end here
        if (openParenCount() > 0 && (endsLikeNumber || lastChar == ".")) {
          if (lastChar == ".") expression += "0";
          expression += ")";
        }
        // Otherwise open a bracket
        else if (expression == "0") {
          expression = "(";
        } else if (lastChar == ".") {
          expression += "0×(";
        } else if (endsLikeNumber) {
          // 2( → 2×(
          expression += "×(";
        } else {
          expression += "(";
        }

        result = "";
        return;
      }

      // ======================
      // Decimal point
      // ======================
      if (button == ".") {
        // No decimal directly after ")" or "%"
        if (lastChar == ")" || lastChar == "%") return;

        // Only one decimal point per number
        if (hasDecimalPoint()) return;

        if (isOperator(lastChar) || lastChar == "(") {
          expression += "0.";
        } else {
          expression += ".";
        }

        result = "";
        return;
      }

      // ======================
      // Digits
      // ======================
      if (isDigit(button)) {
        // A digit straight after % is ambiguous (5%3): ignore it
        if (lastChar == "%") return;

        // (2+3)4 → (2+3)×4
        if (lastChar == ")") {
          expression += "×$button";
          result = "";
          return;
        }

        // Avoid leading zeros in the current number (0 → 5, 5+0 → 5+7)
        if (currentNumber() == "0") {
          if (button == "0") return;
          expression =
              expression.substring(0, expression.length - 1) + button;
        } else {
          expression += button;
        }

        result = "";
        return;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CalculatorAppBar(),
      body: LayoutBuilder(
        builder: (context, constraints) {
          return Padding(
            padding: const EdgeInsets.all(15),
            child: Column(
              children: [
                Flexible(
                  flex: 2,
                  child: Display(
                    expression: expression,
                    result: result,
                  ),
                ),

                const SizedBox(height: 20),

                Expanded(
                  flex: 5,
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.grey.shade800,
                      borderRadius: BorderRadius.circular(15),
                    ),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        const double padding = 10;
                        const double spacing = 10;
                        const int columns = 4;

                        final int rows =
                            (ButtonData.basicButtons.length / columns).ceil();

                        final double availableWidth = constraints.maxWidth -
                            (padding * 2) -
                            (spacing * (columns - 1));

                        final double availableHeight = constraints.maxHeight -
                            (padding * 2) -
                            (spacing * (rows - 1));

                        final double buttonWidth = availableWidth / columns;

                        final double buttonHeight = availableHeight / rows;

                        final double aspectRatio = buttonWidth / buttonHeight;

                        return GridView.builder(
                          physics: const NeverScrollableScrollPhysics(),
                          padding: const EdgeInsets.all(padding),
                          itemCount: ButtonData.basicButtons.length,
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount: columns,
                            crossAxisSpacing: spacing,
                            mainAxisSpacing: spacing,
                            childAspectRatio: aspectRatio,
                          ),
                          itemBuilder: (context, index) {
                            return CalculatorButton(
                              text: ButtonData.basicButtons[index],
                              onPressed: () {
                                onButtonPressed(
                                  ButtonData.basicButtons[index],
                                );
                              },
                            );
                          },
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}