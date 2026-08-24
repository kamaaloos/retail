import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/sale.dart';
import 'theme.dart';
import 'widgets.dart';

/// Pick refund quantities per line (0 = skip). Returns productId → qty.
Future<Map<int, double>?> showPartialRefundDialog({
  required BuildContext context,
  required AppStrings t,
  required SaleDetail detail,
  required String currencySymbol,
}) {
  return showDialog<Map<int, double>>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _PartialRefundDialog(
      t: t,
      detail: detail,
      currencySymbol: currencySymbol,
    ),
  );
}

class _PartialRefundDialog extends StatefulWidget {
  final AppStrings t;
  final SaleDetail detail;
  final String currencySymbol;

  const _PartialRefundDialog({
    required this.t,
    required this.detail,
    required this.currencySymbol,
  });

  @override
  State<_PartialRefundDialog> createState() => _PartialRefundDialogState();
}

class _PartialRefundDialogState extends State<_PartialRefundDialog> {
  late final Map<int, TextEditingController> _qtyCtrls;
  String? _error;

  List<SaleItem> get _refundable =>
      widget.detail.items.where((i) => i.remainingQuantity > 0.0001).toList();

  @override
  void initState() {
    super.initState();
    _qtyCtrls = {
      for (final item in _refundable)
        item.productId: TextEditingController(
          text: _fmt(item.remainingQuantity),
        ),
    };
  }

  @override
  void dispose() {
    for (final c in _qtyCtrls.values) {
      c.dispose();
    }
    super.dispose();
  }

  String _fmt(double q) =>
      q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(2);

  void _refundAll() {
    setState(() {
      _error = null;
      for (final item in _refundable) {
        _qtyCtrls[item.productId]?.text = _fmt(item.remainingQuantity);
      }
    });
  }

  void _clearAll() {
    setState(() {
      _error = null;
      for (final c in _qtyCtrls.values) {
        c.text = '0';
      }
    });
  }

  void _submit() {
    final quantities = <int, double>{};
    for (final item in _refundable) {
      final raw = _qtyCtrls[item.productId]?.text.trim().replaceAll(',', '.') ?? '0';
      final qty = double.tryParse(raw) ?? 0;
      if (qty < -0.0001) {
        setState(() => _error = widget.t.refundInvalidQty);
        return;
      }
      if (qty > item.remainingQuantity + 0.0001) {
        setState(() => _error = widget.t.refundQtyTooHigh
            .replaceAll('{name}', item.productName)
            .replaceAll('{max}', _fmt(item.remainingQuantity)));
        return;
      }
      if (qty > 0.0001) {
        quantities[item.productId] = (quantities[item.productId] ?? 0) + qty;
      }
    }
    if (quantities.isEmpty) {
      setState(() => _error = widget.t.refundNothingSelected);
      return;
    }
    Navigator.pop(context, quantities);
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final sym = widget.currencySymbol;

    if (_refundable.isEmpty) {
      return AlertDialog(
        title: Text(t.refund),
        content: Text(t.refundNothingLeft),
        actions: [
          FilledButton(onPressed: () => Navigator.pop(context), child: Text(t.closeBtn)),
        ],
      );
    }

    return AlertDialog(
      title: Text(t.refundSelectTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.refundSelectHint, style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 12),
              for (final item in _refundable) ...[
                Container(
                  margin: const EdgeInsets.only(bottom: 10),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.productName,
                        style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '${t.soldLabel}: ${_fmt(item.quantity)} · ${t.alreadyRefunded}: ${_fmt(item.refundedQuantity)} · ${t.remainingLabel}: ${_fmt(item.remainingQuantity)} ${item.unit}',
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      Text(
                        Money.format(item.unitPrice, symbol: sym),
                        style: TextStyle(color: AppColors.muted, fontSize: 12),
                      ),
                      const SizedBox(height: 8),
                      TextField(
                        controller: _qtyCtrls[item.productId],
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                        ],
                        decoration: InputDecoration(
                          labelText: t.refundQtyLabel.replaceAll('{unit}', item.unit),
                          isDense: true,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
              if (_error != null)
                Text(_error!, style: const TextStyle(color: AppColors.red, fontSize: 13)),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _clearAll, child: Text(t.clearBtn)),
        TextButton(onPressed: _refundAll, child: Text(t.refundAllRemaining)),
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _submit, child: Text(t.continueRefund)),
      ],
    );
  }
}
