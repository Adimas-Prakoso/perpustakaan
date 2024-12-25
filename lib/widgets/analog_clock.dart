import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';

class AnalogClock extends StatefulWidget {
  final double size;
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color borderColor;
  final Color backgroundColor;
  final Color numberColor;

  const AnalogClock({
    super.key,
    this.size = 100.0,
    this.hourHandColor = Colors.white,
    this.minuteHandColor = Colors.white,
    this.secondHandColor = Colors.white,
    this.borderColor = Colors.white,
    this.backgroundColor = Colors.transparent,
    this.numberColor = Colors.white,
  });

  @override
  State<AnalogClock> createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  late Timer timer;

  @override
  void initState() {
    super.initState();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (mounted) {
        setState(() {});
      }
    });
  }

  @override
  void dispose() {
    timer.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: widget.backgroundColor,
        border: Border.all(
          color: widget.borderColor,
          width: 2,
        ),
      ),
      child: CustomPaint(
        painter: ClockPainter(
          hourHandColor: widget.hourHandColor,
          minuteHandColor: widget.minuteHandColor,
          secondHandColor: widget.secondHandColor,
          numberColor: widget.numberColor,
        ),
      ),
    );
  }
}

class ClockPainter extends CustomPainter {
  final Color hourHandColor;
  final Color minuteHandColor;
  final Color secondHandColor;
  final Color numberColor;

  ClockPainter({
    required this.hourHandColor,
    required this.minuteHandColor,
    required this.secondHandColor,
    required this.numberColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2;

    // Draw clock numbers
    final textPainter = TextPainter(
      textDirection: TextDirection.ltr,
    );

    for (int i = 1; i <= 12; i++) {
      final angle = -pi / 2 + (2 * pi / 12) * i;
      final numberRadius = radius - 20;
      final x = center.dx + numberRadius * cos(angle);
      final y = center.dy + numberRadius * sin(angle);

      textPainter.text = TextSpan(
        text: '$i',
        style: TextStyle(
          color: numberColor,
          fontSize: radius / 5,
          fontWeight: FontWeight.bold,
        ),
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(x - textPainter.width / 2, y - textPainter.height / 2),
      );
    }

    // Get current time
    final now = DateTime.now();
    final hour = now.hour % 12;
    final minute = now.minute;
    final second = now.second;

    // Hour hand
    final hourAngle = pi / 6 * hour + pi / 360 * minute;
    _drawHand(canvas, center, hourAngle, radius * 0.5, hourHandColor, 4);

    // Minute hand
    final minuteAngle = pi / 30 * minute + pi / 1800 * second;
    _drawHand(canvas, center, minuteAngle, radius * 0.7, minuteHandColor, 3);

    // Second hand
    final secondAngle = pi / 30 * second;
    _drawHand(canvas, center, secondAngle, radius * 0.8, secondHandColor, 1);

    // Draw center dot
    final centerPaint = Paint()..color = secondHandColor;
    canvas.drawCircle(center, 4, centerPaint);
  }

  void _drawHand(Canvas canvas, Offset center, double angle, double length,
      Color color, double strokeWidth) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.round;

    final x = center.dx + length * cos(angle - pi / 2);
    final y = center.dy + length * sin(angle - pi / 2);

    canvas.drawLine(center, Offset(x, y), paint);
  }

  @override
  bool shouldRepaint(CustomPainter oldDelegate) => true;
}
