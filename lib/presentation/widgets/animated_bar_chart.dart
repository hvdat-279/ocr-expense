import 'dart:math' as math;
import 'package:flutter/material.dart';

class AnimatedBarChart extends StatefulWidget {
  final Map<String, double> weeklyData;
  final double height;
  final Color barColor;
  final Duration animationDuration;

  const AnimatedBarChart({
    super.key,
    required this.weeklyData,
    this.height = 200,
    this.barColor = const Color(0xFF3B82F6),
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutBack,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedBarChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.weeklyData != widget.weeklyData) {
      _controller.reset();
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          height: widget.height,
          child: CustomPaint(
            painter: _BarChartPainter(
              weeklyData: widget.weeklyData,
              progress: _animation.value,
              barColor: widget.barColor,
            ),
          ),
        );
      },
    );
  }
}

class _BarChartPainter extends CustomPainter {
  final Map<String, double> weeklyData;
  final double progress;
  final Color barColor;

  _BarChartPainter({
    required this.weeklyData,
    required this.progress,
    required this.barColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const bottomLabelHeight = 24.0;
    const topPadding = 18.0;
    const leftPadding = 8.0;
    const rightPadding = 8.0;

    final chartHeight = size.height - bottomLabelHeight - topPadding;
    final chartWidth = size.width - leftPadding - rightPadding;

    if (chartHeight <= 0 || chartWidth <= 0) return;

    // Find maximum spending for scaling
    final maxSpending = weeklyData.values.fold<double>(
      0.0,
      (max, val) => math.max(max, val),
    );
    // Baseline scale minimum (at least 100,000 to prevent division by 0)
    final effectiveMax = maxSpending <= 0 ? 100000.0 : maxSpending * 1.15;

    // Background horizontal dashed gridlines
    final gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.18)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    for (int i = 0; i <= 3; i++) {
      final y = topPadding + (chartHeight / 3) * i;
      canvas.drawLine(
        Offset(leftPadding, y),
        Offset(size.width - rightPadding, y),
        gridPaint,
      );
    }

    final keys = weeklyData.keys.toList();
    final count = keys.length;
    if (count == 0) return;

    final slotWidth = chartWidth / count;
    final barWidth = math.min(slotWidth * 0.48, 28.0);

    for (int i = 0; i < count; i++) {
      final day = keys[i];
      final val = weeklyData[day] ?? 0.0;
      final ratio = (val / effectiveMax).clamp(0.0, 1.0);
      final barHeight = chartHeight * ratio * progress;

      final barCenterX = leftPadding + (i + 0.5) * slotWidth;
      final barLeft = barCenterX - (barWidth / 2);
      final barTop = topPadding + chartHeight - barHeight;

      // Draw Bar gradient
      final rect = Rect.fromLTWH(barLeft, barTop, barWidth, barHeight);
      final barPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0xFF60A5FA),
            Color(0xFF2563EB),
          ],
        ).createShader(rect)
        ..style = PaintingStyle.fill;

      // Draw rounded top bar
      final rrect = RRect.fromRectAndCorners(
        rect,
        topLeft: const Radius.circular(6),
        topRight: const Radius.circular(6),
      );
      canvas.drawRRect(rrect, barPaint);

      // Draw value text on top of the bar if > 0
      if (val > 0 && progress > 0.6) {
        final textSpan = TextSpan(
          text: _formatCompact(val),
          style: TextStyle(
            color: Colors.blueGrey.shade700,
            fontSize: 9.5,
            fontWeight: FontWeight.bold,
          ),
        );
        final tp = TextPainter(
          text: textSpan,
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(
          canvas,
          Offset(barCenterX - (tp.width / 2), barTop - tp.height - 2),
        );
      }

      // Draw X-axis day label
      final labelSpan = TextSpan(
        text: day,
        style: TextStyle(
          color: Colors.grey.shade600,
          fontSize: 11,
          fontWeight: FontWeight.w600,
        ),
      );
      final labelPainter = TextPainter(
        text: labelSpan,
        textDirection: TextDirection.ltr,
      );
      labelPainter.layout();
      labelPainter.paint(
        canvas,
        Offset(
          barCenterX - (labelPainter.width / 2),
          size.height - bottomLabelHeight + 5,
        ),
      );
    }
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }

  @override
  bool shouldRepaint(covariant _BarChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.weeklyData != weeklyData;
  }
}
