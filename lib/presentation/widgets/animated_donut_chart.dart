import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:vku_ocr_expense/domain/entities/transaction_entity.dart';

class AnimatedDonutChart extends StatefulWidget {
  final Map<ExpenseCategory, double> data;
  final double radius;
  final double holeRadiusRatio;
  final Duration animationDuration;

  const AnimatedDonutChart({
    super.key,
    required this.data,
    this.radius = 95,
    this.holeRadiusRatio = 0.58,
    this.animationDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<AnimatedDonutChart> createState() => _AnimatedDonutChartState();
}

class _AnimatedDonutChartState extends State<AnimatedDonutChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  static const Map<ExpenseCategory, Color> categoryColors = {
    ExpenseCategory.food: Color(0xFFFF5722), // Vibrant Orange
    ExpenseCategory.study: Color(0xFF2196F3), // Bright Blue
    ExpenseCategory.travel: Color(0xFF4CAF50), // Fresh Green
    ExpenseCategory.gear: Color(0xFF9C27B0), // Purple
    ExpenseCategory.entertainment: Color(0xFFFFC107), // Amber
    ExpenseCategory.salary: Color(0xFF009688), // Teal
    ExpenseCategory.gift: Color(0xFFE91E63), // Pink
    ExpenseCategory.other: Color(0xFF607D8B), // Blue Grey
  };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeOutCubic,
    );
    _controller.forward();
  }

  @override
  void didUpdateWidget(covariant AnimatedDonutChart oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.data != widget.data) {
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
    final total = widget.data.values.fold<double>(0.0, (sum, val) => sum + val);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return SizedBox(
          width: double.infinity,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center, // Bắt buộc căn giữa
            children: [
              Center(
                child: SizedBox(
                  width: widget.radius * 2,
                  height: widget.radius * 2,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      CustomPaint(
                        size: Size(widget.radius * 2, widget.radius * 2),
                        painter: _DonutChartPainter(
                          data: widget.data,
                          progress: _animation.value,
                          holeRatio: widget.holeRadiusRatio,
                          categoryColors: categoryColors,
                          total: total,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            'Tổng chi',
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            _formatCompact(total * _animation.value),
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.bold,
                              color: Color(0xFF1E293B),
                            ),
                          ),
                          Text(
                            'VND',
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.grey.shade500,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 18),
              // Legend căn giữa
              Center(
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.center,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: widget.data.entries.where((e) => e.value > 0).map((entry) {
                    final percent = total > 0 ? (entry.value / total * 100) : 0.0;
                    final color = categoryColors[entry.key] ?? Colors.grey;
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: color.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: color.withValues(alpha: 0.25)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 8,
                            height: 8,
                            decoration: BoxDecoration(
                              color: color,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '${entry.key.displayName} ${percent.toStringAsFixed(0)}%',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: color.withValues(alpha: 0.9),
                            ),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  String _formatCompact(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    } else if (value >= 1000) {
      return '${(value / 1000).toStringAsFixed(0)}k';
    }
    return value.toStringAsFixed(0);
  }
}

class _DonutChartPainter extends CustomPainter {
  final Map<ExpenseCategory, double> data;
  final double progress;
  final double holeRatio;
  final Map<ExpenseCategory, Color> categoryColors;
  final double total;

  _DonutChartPainter({
    required this.data,
    required this.progress,
    required this.holeRatio,
    required this.categoryColors,
    required this.total,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final outerRadius = size.width / 2;
    final innerRadius = outerRadius * holeRatio;
    final strokeWidth = outerRadius - innerRadius;
    final drawRadius = innerRadius + (strokeWidth / 2);

    final bgPaint = Paint()
      ..color = Colors.grey.shade200
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    if (total <= 0) {
      canvas.drawCircle(center, drawRadius, bgPaint);
      return;
    }

    double startAngle = -math.pi / 2;
    final maxSweepAngle = 2 * math.pi * progress;
    double accumulatedSweep = 0;

    for (final entry in data.entries) {
      if (entry.value <= 0) continue;

      final categorySweep = (entry.value / total) * 2 * math.pi;
      final currentSweep = math.min(categorySweep, math.max(0.0, maxSweepAngle - accumulatedSweep));

      if (currentSweep > 0) {
        final paint = Paint()
          ..color = categoryColors[entry.key] ?? Colors.grey
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.butt;

        canvas.drawArc(
          Rect.fromCircle(center: center, radius: drawRadius),
          startAngle,
          currentSweep,
          false,
          paint,
        );

        final dividerPaint = Paint()
          ..color = Colors.white
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2;

        final dividerX1 = center.dx + innerRadius * math.cos(startAngle);
        final dividerY1 = center.dy + innerRadius * math.sin(startAngle);
        final dividerX2 = center.dx + outerRadius * math.cos(startAngle);
        final dividerY2 = center.dy + outerRadius * math.sin(startAngle);
        canvas.drawLine(Offset(dividerX1, dividerY1), Offset(dividerX2, dividerY2), dividerPaint);
      }

      startAngle += categorySweep;
      accumulatedSweep += categorySweep;
      if (accumulatedSweep >= maxSweepAngle) break;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.data != data ||
        oldDelegate.total != total;
  }
}
