import 'package:flutter/material.dart';
import '../utils/theme.dart';


// ── Sparkline ──────────────────────────────────────────────────────────────

class SparklineWidget extends StatelessWidget {
  final List<double> data;
  final Color color;
  final double height;
  final double width;

  const SparklineWidget({
    super.key,
    required this.data,
    required this.color,
    this.height = 32,
    this.width = double.infinity,
  });

  @override
  Widget build(BuildContext context) {
    if (data.isEmpty) return SizedBox(height: height);
    return SizedBox(
      height: height,
      width: width,
      child: CustomPaint(
        painter: _SparklinePainter(data: data, color: color),
        size: Size.infinite,
      ),
    );
  }
}

class _SparklinePainter extends CustomPainter {
  final List<double> data;
  final Color color;

  _SparklinePainter({required this.data, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (data.length < 2) return;
    final min = data.reduce((a, b) => a < b ? a : b);
    final max = data.reduce((a, b) => a > b ? a : b);
    final range = (max - min).abs();
    final safeRange = range == 0 ? 1.0 : range;

    double xStep = size.width / (data.length - 1);

    final path = Path();
    final fillPath = Path();

    for (int i = 0; i < data.length; i++) {
      final x = i * xStep;
      final y = size.height - ((data[i] - min) / safeRange) * size.height * 0.85 - size.height * 0.075;
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath.lineTo((data.length - 1) * xStep, size.height);
    fillPath.close();

    canvas.drawPath(
      fillPath,
      Paint()
        ..color = color.withValues(alpha: 0.08)
        ..style = PaintingStyle.fill,
    );

    canvas.drawPath(
      path,
      Paint()
        ..color = color
        ..strokeWidth = 1.5
        ..style = PaintingStyle.stroke
        ..strokeJoin = StrokeJoin.round,
    );
  }

  @override
  bool shouldRepaint(_SparklinePainter old) => old.data != data;
}

// ── Change chip ────────────────────────────────────────────────────────────

class ChangeChip extends StatelessWidget {
  final double? value;
  final bool isPercent;
  final double fontSize;

  const ChangeChip({
    super.key,
    required this.value,
    this.isPercent = true,
    this.fontSize = 11,
  });

  @override
  Widget build(BuildContext context) {
    if (value == null) {
      return Text('—', style: TextStyle(color: AppTheme.textMuted, fontSize: fontSize, fontFamily: 'Courier'));
    }
    final isPos = value! >= 0;
    final color = isPos ? AppTheme.accentGreen : AppTheme.accentRed;
    final arrow = isPos ? '▲' : '▼';
    final sign = isPos ? '+' : '';
    final formatted = isPercent
        ? '$arrow $sign${value!.toStringAsFixed(2)}%'
        : '$arrow $sign${value!.toStringAsFixed(2)}';
    return Text(
      formatted,
      style: TextStyle(
        color: color,
        fontSize: fontSize,
        fontFamily: 'Courier',
        fontWeight: FontWeight.w500,
      ),
    );
  }
}

// ── Metric card ────────────────────────────────────────────────────────────

class MetricCard extends StatelessWidget {
  final String label;
  final String value;
  final Widget? suffix;
  final String? subtext;

  const MetricCard({
    super.key,
    required this.label,
    required this.value,
    this.suffix,
    this.subtext,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppTheme.bgCard,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppTheme.bgCardBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              color: AppTheme.textMuted,
              fontSize: 9,
              letterSpacing: 0.6,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: const TextStyle(
                    color: AppTheme.textPrimary,
                    fontSize: 15,
                    fontFamily: 'Courier',
                    fontWeight: FontWeight.w500,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (suffix != null) ...[const SizedBox(width: 4), suffix!],
            ],
          ),
          if (subtext != null)
            Padding(
              padding: const EdgeInsets.only(top: 3),
              child: Text(
                subtext!,
                style: const TextStyle(color: AppTheme.textMuted, fontSize: 9),
              ),
            ),
        ],
      ),
    );
  }
}

// ── 52-week range bar ──────────────────────────────────────────────────────

class RangeBar extends StatelessWidget {
  final double low;
  final double high;
  final double current;

  const RangeBar({
    super.key,
    required this.low,
    required this.high,
    required this.current,
  });

  @override
  Widget build(BuildContext context) {
    final pct = high == low ? 0.5 : (current - low) / (high - low);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          height: 4,
          child: LayoutBuilder(builder: (ctx, constraints) {
            final w = constraints.maxWidth;
            return Stack(
              children: [
                Container(
                  width: w,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.bgHighlight,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Positioned(
                  left: (pct.clamp(0.0, 1.0) * w - 2).clamp(0, w - 4),
                  child: Container(
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      color: AppTheme.accentGreen,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
              ],
            );
          }),
        ),
        const SizedBox(height: 3),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text('${_fmt(low)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'Courier')),
            Text('${_fmt(high)}', style: const TextStyle(color: AppTheme.textMuted, fontSize: 9, fontFamily: 'Courier')),
          ],
        )
      ],
    );
  }

  String _fmt(double v) => v >= 1000 ? v.toStringAsFixed(0) : v.toStringAsFixed(2);
}

// ── Loading shimmer placeholder ────────────────────────────────────────────

class ShimmerBox extends StatefulWidget {
  final double width;
  final double height;
  final double radius;

  const ShimmerBox({super.key, required this.width, required this.height, this.radius = 6});

  @override
  State<ShimmerBox> createState() => _ShimmerBoxState();
}

class _ShimmerBoxState extends State<ShimmerBox> with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))..repeat(reverse: true);
    _anim = Tween(begin: 0.04, end: 0.12).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => Container(
        width: widget.width,
        height: widget.height,
        decoration: BoxDecoration(
          color: AppTheme.textPrimary.withValues(alpha: _anim.value),
          borderRadius: BorderRadius.circular(widget.radius),
        ),
      ),
    );
  }
}
