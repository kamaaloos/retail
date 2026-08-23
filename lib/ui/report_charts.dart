import 'dart:math' show pi;

import 'package:flutter/material.dart';

import '../models/sale.dart';
import 'theme.dart';
import 'widgets.dart';

class ReportChartPanel extends StatelessWidget {
  final String title;
  final Widget child;
  final double height;

  const ReportChartPanel({
    super.key,
    required this.title,
    required this.child,
    this.height = 240,
  });

  @override
  Widget build(BuildContext context) {
    return ShopPanel(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),
          SizedBox(height: height, width: double.infinity, child: child),
        ],
      ),
    );
  }
}

class SalesTrendChart extends StatelessWidget {
  final List<DailySalesPoint> points;
  final String Function(DateTime) formatLabel;
  final String emptyLabel;

  const SalesTrendChart({
    super.key,
    required this.points,
    required this.formatLabel,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (points.every((p) => p.revenue <= 0)) {
      return Center(child: Text(emptyLabel, style: TextStyle(color: AppColors.muted)));
    }
    return CustomPaint(
      painter: _SalesTrendPainter(
        points: points,
        formatLabel: formatLabel,
        lineColor: AppColors.accent,
        fillColor: AppColors.accent.withValues(alpha: 0.18),
        gridColor: AppColors.line,
        textColor: AppColors.muted,
      ),
      child: const SizedBox.expand(),
    );
  }
}

class RevenueProfitChart extends StatelessWidget {
  final double revenue;
  final double profit;
  final String revenueLabel;
  final String profitLabel;
  final String currencySymbol;

  const RevenueProfitChart({
    super.key,
    required this.revenue,
    required this.profit,
    required this.revenueLabel,
    required this.profitLabel,
    required this.currencySymbol,
  });

  @override
  Widget build(BuildContext context) {
    final max = [revenue, profit, 1.0].reduce((a, b) => a > b ? a : b);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Expanded(
          child: _MetricBar(
            label: revenueLabel,
            value: Money.format(revenue, symbol: currencySymbol),
            ratio: revenue / max,
            color: AppColors.accent,
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: _MetricBar(
            label: profitLabel,
            value: Money.format(profit, symbol: currencySymbol),
            ratio: profit / max,
            color: AppColors.green,
          ),
        ),
      ],
    );
  }
}

class TopProductsBarChart extends StatelessWidget {
  final List<TopProduct> products;
  final String emptyLabel;

  const TopProductsBarChart({
    super.key,
    required this.products,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (products.isEmpty) {
      return Center(child: Text(emptyLabel, style: TextStyle(color: AppColors.muted)));
    }
    final top = products.take(6).toList();
    final maxQty = top.map((p) => p.quantity).reduce((a, b) => a > b ? a : b).clamp(1, double.infinity);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        for (var i = 0; i < top.length; i++) ...[
          if (i > 0) const SizedBox(width: 10),
          Expanded(
            child: _ProductBar(
              name: top[i].name,
              quantity: top[i].quantity,
              ratio: top[i].quantity / maxQty,
              color: _barColor(i),
            ),
          ),
        ],
      ],
    );
  }

  static Color _barColor(int index) {
    const colors = [AppColors.accent, AppColors.cyan, AppColors.green, AppColors.amber, AppColors.purple, AppColors.red];
    return colors[index % colors.length];
  }
}

class PaymentDonutChart extends StatelessWidget {
  final List<PaymentBreakdown> payments;
  final String Function(String method) methodLabel;
  final String currencySymbol;
  final String emptyLabel;

  const PaymentDonutChart({
    super.key,
    required this.payments,
    required this.methodLabel,
    required this.currencySymbol,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (payments.isEmpty) {
      return Center(child: Text(emptyLabel, style: TextStyle(color: AppColors.muted)));
    }
    final total = payments.fold(0.0, (sum, p) => sum + p.amount);
    if (total <= 0) {
      return Center(child: Text(emptyLabel, style: TextStyle(color: AppColors.muted)));
    }
    final colors = [AppColors.accent, AppColors.cyan, AppColors.green, AppColors.amber, AppColors.purple];
    return Row(
      children: [
        SizedBox(
          width: 160,
          height: 160,
          child: CustomPaint(
            painter: _DonutPainter(
              segments: [
                for (var i = 0; i < payments.length; i++)
                  _DonutSegment(
                    value: payments[i].amount / total,
                    color: colors[i % colors.length],
                  ),
              ],
            ),
          ),
        ),
        const SizedBox(width: 20),
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              for (var i = 0; i < payments.length; i++) ...[
                if (i > 0) const SizedBox(height: 10),
                _LegendRow(
                  color: colors[i % colors.length],
                  label: methodLabel(payments[i].method),
                  value: Money.format(payments[i].amount, symbol: currencySymbol),
                  percent: '${((payments[i].amount / total) * 100).toStringAsFixed(0)}%',
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _MetricBar extends StatelessWidget {
  final String label;
  final String value;
  final double ratio;
  final Color color;

  const _MetricBar({
    required this.label,
    required this.value,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(color: AppColors.muted, fontSize: 12, fontWeight: FontWeight.w600)),
        const SizedBox(height: 8),
        Text(value, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w800, fontSize: 18)),
        const SizedBox(height: 12),
        Align(
          alignment: Alignment.bottomCenter,
          child: Container(
            height: 120 * ratio.clamp(0.08, 1.0),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.85),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(10)),
              boxShadow: [
                BoxShadow(color: color.withValues(alpha: 0.25), blurRadius: 12, offset: const Offset(0, 6)),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _ProductBar extends StatelessWidget {
  final String name;
  final double quantity;
  final double ratio;
  final Color color;

  const _ProductBar({
    required this.name,
    required this.quantity,
    required this.ratio,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          quantity % 1 == 0 ? quantity.toInt().toString() : quantity.toStringAsFixed(1),
          style: TextStyle(color: AppColors.muted, fontSize: 11, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        Expanded(
          child: Align(
            alignment: Alignment.bottomCenter,
            child: Container(
              width: double.infinity,
              height: 130 * ratio.clamp(0.06, 1.0),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          name,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
          style: TextStyle(color: AppColors.text, fontSize: 10, height: 1.2),
        ),
      ],
    );
  }
}

class _LegendRow extends StatelessWidget {
  final Color color;
  final String label;
  final String value;
  final String percent;

  const _LegendRow({
    required this.color,
    required this.label,
    required this.value,
    required this.percent,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 10, height: 10, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 8),
        Expanded(child: Text(label, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600))),
        Text(value, style: TextStyle(color: AppColors.muted, fontSize: 12)),
        const SizedBox(width: 8),
        Text(percent, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
      ],
    );
  }
}

class _DonutSegment {
  final double value;
  final Color color;

  const _DonutSegment({required this.value, required this.color});
}

class _DonutPainter extends CustomPainter {
  final List<_DonutSegment> segments;

  _DonutPainter({required this.segments});

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.shortestSide / 2;
    final stroke = radius * 0.34;
    var start = -pi / 2;
    for (final segment in segments) {
      final sweep = segment.value * pi * 2;
      final paint = Paint()
        ..color = segment.color
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - stroke / 2),
        start,
        sweep,
        false,
        paint,
      );
      start += sweep;
    }
    final innerPaint = Paint()..color = AppColors.panel;
    canvas.drawCircle(center, radius - stroke - 2, innerPaint);
  }

  @override
  bool shouldRepaint(covariant _DonutPainter oldDelegate) => oldDelegate.segments != segments;
}

class _SalesTrendPainter extends CustomPainter {
  final List<DailySalesPoint> points;
  final String Function(DateTime) formatLabel;
  final Color lineColor;
  final Color fillColor;
  final Color gridColor;
  final Color textColor;

  _SalesTrendPainter({
    required this.points,
    required this.formatLabel,
    required this.lineColor,
    required this.fillColor,
    required this.gridColor,
    required this.textColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    const leftPad = 42.0;
    const bottomPad = 28.0;
    const topPad = 12.0;
    final chartWidth = size.width - leftPad - 8;
    final chartHeight = size.height - bottomPad - topPad;
    final maxRevenue = points.map((p) => p.revenue).fold(0.0, (a, b) => a > b ? a : b);
    final maxY = maxRevenue <= 0 ? 1.0 : maxRevenue * 1.15;

    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 4; i++) {
      final y = topPad + chartHeight * (i / 4);
      canvas.drawLine(Offset(leftPad, y), Offset(size.width, y), gridPaint);
      final label = (maxY * (1 - i / 4)).toStringAsFixed(maxY >= 100 ? 0 : 1);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(leftPad - tp.width - 6, y - tp.height / 2));
    }

    if (points.isEmpty) return;

    Offset pointAt(int index) {
      final x = leftPad + (points.length == 1 ? chartWidth / 2 : chartWidth * (index / (points.length - 1)));
      final y = topPad + chartHeight * (1 - points[index].revenue / maxY);
      return Offset(x, y);
    }

    final path = Path();
    final fillPath = Path();
    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
        fillPath.moveTo(p.dx, topPad + chartHeight);
        fillPath.lineTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
        fillPath.lineTo(p.dx, p.dy);
      }
    }
    fillPath.lineTo(pointAt(points.length - 1).dx, topPad + chartHeight);
    fillPath.close();

    canvas.drawPath(fillPath, Paint()..color = fillColor);
    canvas.drawPath(
      path,
      Paint()
        ..color = lineColor
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );

    for (var i = 0; i < points.length; i++) {
      final p = pointAt(i);
      canvas.drawCircle(p, 4, Paint()..color = lineColor);
      canvas.drawCircle(p, 2, Paint()..color = Colors.white);
    }

    final labelEvery = points.length <= 7 ? 1 : (points.length / 6).ceil();
    for (var i = 0; i < points.length; i += labelEvery) {
      final label = formatLabel(points[i].date);
      final tp = TextPainter(
        text: TextSpan(text: label, style: TextStyle(color: textColor, fontSize: 10)),
        textDirection: TextDirection.ltr,
      )..layout(maxWidth: chartWidth / 3);
      final x = pointAt(i).dx - tp.width / 2;
      tp.paint(canvas, Offset(x.clamp(0, size.width - tp.width), size.height - bottomPad + 4));
    }
  }

  @override
  bool shouldRepaint(covariant _SalesTrendPainter oldDelegate) => oldDelegate.points != points;
}
