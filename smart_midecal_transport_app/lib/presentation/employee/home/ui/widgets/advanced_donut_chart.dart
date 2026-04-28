import 'dart:math';
import 'package:flutter/material.dart';

class AdvancedDonutChart extends StatefulWidget {
  final Map<String, int> data;

  const AdvancedDonutChart({super.key, required this.data});

  @override
  State<AdvancedDonutChart> createState() => _AdvancedDonutChartState();
}

class _AdvancedDonutChartState extends State<AdvancedDonutChart> {
  int? selectedIndex;

  @override
  Widget build(BuildContext context) {
    final total = widget.data.values.fold(0.0, (a, b) => a + b);

    if (total == 0) {
      return const Center(child: Text("No data available"));
    }

    return SizedBox(
      height: 250,
      child: Stack(
        alignment: Alignment.center,
        children: [
          GestureDetector(
            onTapUp: (details) {
              // Simple hit detection (approx)
              setState(() {
                selectedIndex = null;
              });
            },
            child: CustomPaint(
              size: const Size(250, 250),
              painter: _DonutPainter(
                data: widget.data.map((key, value) => MapEntry(key, value.toDouble())),
                selectedIndex: selectedIndex,
              ),
            ),
          ),

          /// CENTER ICON
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.credit_card, size: 40),
              const SizedBox(height: 4),
              Text(
                selectedIndex == null
                    ? total.toInt().toString()
                    : widget.data.values.elementAt(selectedIndex!).toInt().toString(),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}


class _DonutPainter extends CustomPainter {
  final Map<String, double> data;
  final int? selectedIndex;

  _DonutPainter({required this.data, this.selectedIndex});

  @override
  void paint(Canvas canvas, Size size) {
    final total = data.values.fold(0.0, (a, b) => a + b);

    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = 30.0;

    final rect = Rect.fromCircle(center: center, radius: radius);

    double startAngle = -pi / 2;

    final colors = [
      Colors.green,
      Colors.orange,
      Colors.blue,
      Colors.red,
    ];

    int i = 0;

    data.forEach((label, value) {
      final sweepAngle = (value / total) * 2 * pi;

      final paint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = selectedIndex == i ? 36 : strokeWidth
        ..color = colors[i % colors.length];

      canvas.drawArc(rect, startAngle, sweepAngle, false, paint);

      /// DRAW LABEL LINE
      final midAngle = startAngle + sweepAngle / 2;

      final lineStart = Offset(
        center.dx + cos(midAngle) * radius,
        center.dy + sin(midAngle) * radius,
      );

      final lineEnd = Offset(
        center.dx + cos(midAngle) * (radius + 20),
        center.dy + sin(midAngle) * (radius + 20),
      );

      final linePaint = Paint()
        ..color = Colors.grey
        ..strokeWidth = 1;

      canvas.drawLine(lineStart, lineEnd, linePaint);

      /// TEXT POSITION
      final textOffset = Offset(
        center.dx + cos(midAngle) * (radius + 40),
        center.dy + sin(midAngle) * (radius + 40),
      );

      final percent = ((value / total) * 100).toStringAsFixed(0);

      final textPainter = TextPainter(
        text: TextSpan(
          text: "$label\n${value.toInt()} ($percent%)",
          style: const TextStyle(color: Colors.black, fontSize: 10),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();

      textPainter.paint(canvas, textOffset);

      startAngle += sweepAngle;
      i++;
    });

    /// INNER CIRCLE (to make donut)
    final innerPaint = Paint()..color = Colors.white;
    canvas.drawCircle(center, radius - strokeWidth, innerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}