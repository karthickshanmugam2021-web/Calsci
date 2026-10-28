import 'package:flutter/material.dart';

class Display extends StatelessWidget {
  final String expression;
  final String result;

  const Display({
    super.key,
    required this.expression,
    required this.result,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      alignment: Alignment.bottomRight,
      decoration: BoxDecoration(
        color: Colors.grey.shade900,
        borderRadius: BorderRadius.circular(20),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final double expressionFontSize =
              constraints.maxWidth * 0.055;

          final double resultFontSize =
              constraints.maxWidth * 0.12;

          return Column(
            mainAxisAlignment: MainAxisAlignment.end,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              // Expression
              Flexible(
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      expression,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: expressionFontSize,
                        color: Colors.grey,
                      ),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 8),

              // Result
              Flexible(
                flex: 2,
                child: SizedBox(
                  width: double.infinity,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.bottomRight,
                    child: Text(
                      result.isEmpty ? expression : result,
                      textAlign: TextAlign.right,
                      style: TextStyle(
                        fontSize: resultFontSize,
                        color: Colors.white,
                        fontWeight: FontWeight.w300,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}