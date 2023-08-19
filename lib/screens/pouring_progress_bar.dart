import 'package:flutter/material.dart';

class PouringProgressBar extends StatefulWidget {
  final double value;
  final double requiredAmount;

  const PouringProgressBar({super.key, required this.value, required this.requiredAmount});

  @override
  _PouringProgressBarState createState() => _PouringProgressBarState();
}

class _PouringProgressBarState extends State<PouringProgressBar> {
  double relativeValue = 0.0;
  double maxDeviation = 0.0015; // maximum deviation of user value from required amount
  double adjustedRelativeValue = 0.0; // normalize the relative value
  Color dotColor = Colors.blue;


  Color getDotColor() {
    if (widget.value == 0) {
      return Colors.blue;
    } else if (relativeValue.abs() >= maxDeviation) {
      return Colors.red;
    } else if (relativeValue.abs() >= maxDeviation / 2) {
      return Colors.orange;
    } else if (relativeValue.abs() >= maxDeviation / 4) {
      return Colors.yellow;
    } else {
      return Colors.green;
    }
  }

  void calculateRelativeValue() {
    relativeValue = (widget.value - widget.requiredAmount) / widget.requiredAmount;
    adjustedRelativeValue = widget.value == 0
        ? 0
        : (relativeValue / maxDeviation).clamp(-1, 1); // normalize the relative value
    dotColor = getDotColor();
  }

  @override
  Widget build(BuildContext context) {
    calculateRelativeValue();

    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return Container(
          height: 10,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                Colors.red.withOpacity(0.5),
                Colors.orange.withOpacity(0.5),
                Colors.yellow.withOpacity(0.5),
                Colors.green.withOpacity(0.5),
                Colors.yellow.withOpacity(0.5),
                Colors.orange.withOpacity(0.5),
                Colors.red.withOpacity(0.5)
              ],
              stops: const [0.0, 0.15, 0.3, 0.5, 0.7, 0.85, 1.0],  // Define where the colors start to blend
            ),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Stack(
            children: [
              // Moving dot
              AnimatedPositioned(
                duration: const Duration(milliseconds: 500),
                left: (constraints.maxWidth / 2) - 5 + (adjustedRelativeValue * constraints.maxWidth / 2),
                child: TweenAnimationBuilder<Color?>(
                  tween: ColorTween(begin: dotColor, end: getDotColor()),
                  duration: const Duration(milliseconds: 500),
                  builder: (BuildContext context, Color? color, Widget? child) => Container(
                    height: 10,
                    width: 10,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              ),

            ],
          ),
        );
      },
    );
  }
}