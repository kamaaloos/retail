import 'dart:io';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import 'theme.dart';

class Money {
  static String format(num value, {String symbol = '€'}) {
    return NumberFormat.currency(symbol: symbol, decimalDigits: 2).format(value);
  }
}

class ShopPanel extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final Color? color;

  const ShopPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    // Keep border outside Material so ListTile/SwitchListTile ink is not
    // obscured by an intermediate colored DecoratedBox (Flutter assertion).
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.line),
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: color ?? AppColors.panel,
        child: Padding(
          padding: padding,
          child: child,
        ),
      ),
    );
  }
}

class PageTitle extends StatelessWidget {
  final String title;
  final String? subtitle;
  final List<Widget>? actions;

  const PageTitle({
    super.key,
    required this.title,
    this.subtitle,
    this.actions,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.headlineMedium),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(subtitle!, style: Theme.of(context).textTheme.bodyMedium),
              ],
            ],
          ),
        ),
        if (actions != null) ...actions!,
      ],
    );
  }
}

class StatCard extends StatelessWidget {
  final String label;
  final String value;
  final Color color;
  final IconData icon;

  const StatCard({
    super.key,
    required this.label,
    required this.value,
    required this.color,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 210,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 18),
          Text(label, style: TextStyle(color: color.withValues(alpha: 0.9), fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(color: AppColors.text),
          ),
        ],
      ),
    );
  }
}

class SoftChip extends StatelessWidget {
  final String label;
  final bool selected;
  final Color? dot;
  final VoidCallback onTap;

  const SoftChip({
    super.key,
    required this.label,
    required this.selected,
    required this.onTap,
    this.dot,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          decoration: BoxDecoration(
            color: selected ? AppColors.accent : AppColors.card,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: selected ? AppColors.accent : AppColors.line),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (selected) ...[
                const Icon(Icons.check, size: 14, color: Colors.white),
                const SizedBox(width: 6),
              ] else if (dot != null) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: selected ? Colors.white : AppColors.text,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Alias used by pages.
typedef StatusPill = StatusBadge;

class StatusBadge extends StatelessWidget {
  final String text;
  final Color color;

  const StatusBadge({super.key, required this.text, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(text, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
    );
  }
}

class ProductThumb extends StatelessWidget {
  final String? imagePath;
  final String colorHex;
  final double? size;
  final double radius;

  const ProductThumb({
    super.key,
    required this.imagePath,
    required this.colorHex,
    this.size = 40,
    this.radius = 10,
  });

  @override
  Widget build(BuildContext context) {
    final color = parseHexColor(colorHex);
    final path = imagePath;
    final Widget child;
    if (path != null && path.isNotEmpty && File(path).existsSync()) {
      child = Image.file(File(path), fit: BoxFit.cover, width: double.infinity, height: double.infinity);
    } else {
      child = ColoredBox(
        color: color.withValues(alpha: 0.22),
        child: Center(
          child: Icon(Icons.inventory_2_outlined, color: color, size: (size ?? 48) * 0.42),
        ),
      );
    }
    return ClipRRect(
      borderRadius: BorderRadius.circular(radius),
      child: size == null
          ? SizedBox.expand(child: child)
          : SizedBox(width: size, height: size, child: child),
    );
  }
}
