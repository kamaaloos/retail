import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../l10n/app_strings.dart';
import '../models/settings_config.dart';
import '../util/cash_rounding.dart';
import 'theme.dart';
import 'widgets.dart';

class PaymentSplit {
  final String method;
  final double amount;

  const PaymentSplit({required this.method, required this.amount});
}

class CheckoutResult {
  final List<PaymentSplit> payments;
  /// Exact cart total before cash rounding.
  final double rawTotal;
  /// Amount charged (nickel-rounded when any non-card tender is used).
  final double amountDue;
  final double amountReceived;
  final double change;

  const CheckoutResult({
    required this.payments,
    required this.rawTotal,
    required this.amountDue,
    required this.amountReceived,
    required this.change,
  });

  String get paymentMethod => payments.isEmpty ? 'cash' : payments.first.method;

  double get cashRounding => CashRounding.adjustment(rawTotal, amountDue);
}

/// Checkout with optional split tender + cash change.
/// Non-card payments (or any split that includes cash/mobile) round to nearest $0.05.
Future<CheckoutResult?> showCheckoutDialog({
  required BuildContext context,
  required AppStrings t,
  required double total,
  required String currencySymbol,
  required List<PaymentMethodConfig> paymentMethods,
}) {
  return showDialog<CheckoutResult>(
    context: context,
    barrierDismissible: false,
    builder: (_) => _CheckoutDialog(
      t: t,
      total: total,
      currencySymbol: currencySymbol,
      paymentMethods: paymentMethods,
    ),
  );
}

Future<void> showChangeDueDialog({
  required BuildContext context,
  required AppStrings t,
  required double change,
  required String currencySymbol,
  required String receiptNumber,
}) {
  return showDialog<void>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(t.changeDue),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            Money.format(change, symbol: currencySymbol),
            style: Theme.of(ctx).textTheme.displaySmall?.copyWith(
                  color: AppColors.green,
                  fontWeight: FontWeight.w800,
                ),
          ),
          const SizedBox(height: 12),
          Text(
            t.saleCompleted.replaceAll('{receipt}', receiptNumber),
            textAlign: TextAlign.center,
            style: TextStyle(color: AppColors.muted),
          ),
        ],
      ),
      actions: [
        FilledButton(
          onPressed: () => Navigator.pop(ctx),
          child: Text(t.done),
        ),
      ],
    ),
  );
}

class _TenderLine {
  String method;
  final TextEditingController amountCtrl;

  _TenderLine({required this.method, required String amountText})
      : amountCtrl = TextEditingController(text: amountText);

  void dispose() => amountCtrl.dispose();

  double get amount {
    final raw = amountCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }
}

class _CheckoutDialog extends StatefulWidget {
  final AppStrings t;
  final double total;
  final String currencySymbol;
  final List<PaymentMethodConfig> paymentMethods;

  const _CheckoutDialog({
    required this.t,
    required this.total,
    required this.currencySymbol,
    required this.paymentMethods,
  });

  @override
  State<_CheckoutDialog> createState() => _CheckoutDialogState();
}

class _CheckoutDialogState extends State<_CheckoutDialog> {
  late final List<_TenderLine> _lines;
  late final TextEditingController _receivedCtrl;
  String? _error;
  bool _split = false;

  double get _rawTotal => double.parse(widget.total.toStringAsFixed(2));

  bool _isCardCode(String code) {
    final match = widget.paymentMethods.where((m) => m.code == code);
    final label = match.isEmpty ? '' : match.first.label;
    return CashRounding.isCardPayment(code) || CashRounding.isCardPayment(label);
  }

  bool get _needsCashRounding => _lines.any((l) => !_isCardCode(l.method));

  double get _amountDue {
    final key = _needsCashRounding ? 'cash' : 'card';
    return CashRounding.amountDue(_rawTotal, key);
  }

  double get _rounding => CashRounding.adjustment(_rawTotal, _amountDue);

  bool get _hasCashLine => _lines.any((l) => l.method.toLowerCase().contains('cash'));

  double get _tenderSum =>
      double.parse(_lines.fold(0.0, (s, l) => s + l.amount).toStringAsFixed(2));

  double get _received {
    final raw = _receivedCtrl.text.trim().replaceAll(',', '.');
    return double.tryParse(raw) ?? 0;
  }

  double get _cashPortion {
    var sum = 0.0;
    for (final l in _lines) {
      if (l.method.toLowerCase().contains('cash')) sum += l.amount;
    }
    return double.parse(sum.toStringAsFixed(2));
  }

  double get _change {
    if (!_hasCashLine) return 0;
    final change = _received - _cashPortion;
    return change > 0 ? change : 0;
  }

  bool get _canComplete {
    if (widget.paymentMethods.isEmpty || _lines.isEmpty) return false;
    if ((_tenderSum - _amountDue).abs() > 0.02) return false;
    if (_hasCashLine && _received + 0.0001 < _cashPortion) return false;
    return true;
  }

  @override
  void initState() {
    super.initState();
    final first = widget.paymentMethods.isNotEmpty
        ? widget.paymentMethods.first.code
        : 'cash';
    _lines = [
      _TenderLine(method: first, amountText: _amountDueForMethod(first).toStringAsFixed(2)),
    ];
    _receivedCtrl = TextEditingController(text: _amountDue.toStringAsFixed(2));
    _receivedCtrl.addListener(() => setState(() => _error = null));
  }

  double _amountDueForMethod(String code) {
    final key = _isCardCode(code) ? 'card' : 'cash';
    return CashRounding.amountDue(_rawTotal, key);
  }

  @override
  void dispose() {
    for (final l in _lines) {
      l.dispose();
    }
    _receivedCtrl.dispose();
    super.dispose();
  }

  void _syncSingleLineAmount() {
    if (_lines.length == 1) {
      _lines.first.amountCtrl.text = _amountDue.toStringAsFixed(2);
    }
    if (_hasCashLine) {
      _receivedCtrl.text = _cashPortion > 0
          ? _cashPortion.toStringAsFixed(2)
          : _amountDue.toStringAsFixed(2);
    }
  }

  void _setMethod(int index, String code) {
    setState(() {
      _lines[index].method = code;
      _error = null;
      if (!_split) {
        _lines[index].amountCtrl.text = _amountDue.toStringAsFixed(2);
      }
      _syncSingleLineAmount();
    });
  }

  void _enableSplit(bool value) {
    setState(() {
      _split = value;
      _error = null;
      if (!value && _lines.length > 1) {
        final first = _lines.first;
        for (var i = 1; i < _lines.length; i++) {
          _lines[i].dispose();
        }
        _lines
          ..clear()
          ..add(first);
        first.amountCtrl.text = _amountDue.toStringAsFixed(2);
      }
      _syncSingleLineAmount();
    });
  }

  void _addLine() {
    if (widget.paymentMethods.isEmpty) return;
    final remaining = double.parse((_amountDue - _tenderSum).toStringAsFixed(2));
    final code = widget.paymentMethods
        .firstWhere(
          (m) => !_lines.any((l) => l.method == m.code),
          orElse: () => widget.paymentMethods.first,
        )
        .code;
    setState(() {
      _lines.add(
        _TenderLine(
          method: code,
          amountText: (remaining > 0 ? remaining : 0).toStringAsFixed(2),
        ),
      );
      _error = null;
    });
  }

  void _removeLine(int index) {
    if (_lines.length <= 1) return;
    setState(() {
      _lines.removeAt(index).dispose();
      _error = null;
      if (_lines.length == 1) {
        _split = false;
        _lines.first.amountCtrl.text = _amountDue.toStringAsFixed(2);
      }
    });
  }

  void _setReceived(double amount) {
    _receivedCtrl.text = amount.toStringAsFixed(2);
    _receivedCtrl.selection = TextSelection.collapsed(offset: _receivedCtrl.text.length);
    setState(() => _error = null);
  }

  void _complete() {
    if (!_canComplete) {
      setState(() {
        if ((_tenderSum - _amountDue).abs() > 0.02) {
          _error = widget.t.splitMustEqualDue
              .replaceAll('{due}', Money.format(_amountDue, symbol: widget.currencySymbol))
              .replaceAll('{sum}', Money.format(_tenderSum, symbol: widget.currencySymbol));
        } else {
          _error = widget.t.amountTooLow;
        }
      });
      return;
    }
    final due = _amountDue;
    final payments = <PaymentSplit>[
      for (final l in _lines)
        if (l.amount > 0.0001) PaymentSplit(method: l.method, amount: double.parse(l.amount.toStringAsFixed(2))),
    ];
    final received = _hasCashLine ? _received : due;
    Navigator.pop(
      context,
      CheckoutResult(
        payments: payments,
        rawTotal: _rawTotal,
        amountDue: due,
        amountReceived: received,
        change: _change,
      ),
    );
  }

  List<double> _suggestions() {
    final total = _hasCashLine ? _cashPortion : _amountDue;
    final values = <double>{
      double.parse(total.toStringAsFixed(2)),
      total.ceilToDouble(),
    };
    for (final step in [5.0, 10.0, 20.0, 50.0, 100.0, 200.0, 500.0]) {
      final next = (total / step).ceil() * step;
      if (next >= total - 0.0001) {
        values.add(double.parse(next.toStringAsFixed(2)));
      }
    }
    final sorted = values.toList()..sort();
    return sorted.take(8).toList();
  }

  String _labelFor(String code) {
    for (final m in widget.paymentMethods) {
      if (m.code == code) return m.label;
    }
    return code;
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.t;
    final sym = widget.currencySymbol;
    final due = _amountDue;
    final rounding = _rounding;

    return AlertDialog(
      title: Text(t.chargeTitle),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.amountDue, style: TextStyle(color: AppColors.muted, fontSize: 13)),
              const SizedBox(height: 4),
              Text(
                Money.format(due, symbol: sym),
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.w800),
              ),
              if (_needsCashRounding && rounding.abs() > 0.0001) ...[
                const SizedBox(height: 6),
                Text(
                  t.cashRoundingNote
                      .replaceAll('{raw}', Money.format(_rawTotal, symbol: sym))
                      .replaceAll('{rounded}', Money.format(due, symbol: sym)),
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
              const SizedBox(height: 14),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.splitPayment),
                subtitle: Text(t.splitPaymentHint, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                value: _split,
                onChanged: widget.paymentMethods.length < 2 ? null : _enableSplit,
              ),
              const SizedBox(height: 8),
              if (!_split) ...[
                Text(t.selectPayment, style: TextStyle(color: AppColors.muted, fontSize: 13)),
                const SizedBox(height: 8),
                if (widget.paymentMethods.isEmpty)
                  Text(t.noPaymentMethodsYet, style: TextStyle(color: AppColors.muted))
                else
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final method in widget.paymentMethods)
                        ChoiceChip(
                          label: Text(method.label),
                          selected: _lines.first.method == method.code,
                          onSelected: (_) => _setMethod(0, method.code),
                          selectedColor: AppColors.accent.withValues(alpha: 0.25),
                          labelStyle: TextStyle(
                            color: _lines.first.method == method.code ? AppColors.text : AppColors.muted,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                    ],
                  ),
              ] else ...[
                for (var i = 0; i < _lines.length; i++) ...[
                  Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: DropdownButtonFormField<String>(
                          value: _lines[i].method,
                          decoration: InputDecoration(labelText: t.selectPayment, isDense: true),
                          items: [
                            for (final m in widget.paymentMethods)
                              DropdownMenuItem(value: m.code, child: Text(m.label)),
                          ],
                          onChanged: (v) {
                            if (v != null) _setMethod(i, v);
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        flex: 2,
                        child: TextField(
                          controller: _lines[i].amountCtrl,
                          keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          inputFormatters: [
                            FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                          ],
                          decoration: InputDecoration(
                            labelText: t.amount,
                            prefixText: '$sym ',
                            isDense: true,
                          ),
                          onChanged: (_) => setState(() => _error = null),
                        ),
                      ),
                      if (_lines.length > 1)
                        IconButton(
                          icon: const Icon(Icons.remove_circle_outline, color: AppColors.red),
                          onPressed: () => _removeLine(i),
                        ),
                    ],
                  ),
                  const SizedBox(height: 8),
                ],
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: _addLine,
                    icon: const Icon(Icons.add, size: 18),
                    label: Text(t.addPaymentLine),
                  ),
                ),
                Text(
                  '${t.splitAllocated}: ${Money.format(_tenderSum, symbol: sym)} / ${Money.format(due, symbol: sym)}',
                  style: TextStyle(
                    color: (_tenderSum - due).abs() <= 0.02 ? AppColors.green : AppColors.amber,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ],
              if (_hasCashLine) ...[
                const SizedBox(height: 18),
                TextField(
                  controller: _receivedCtrl,
                  autofocus: true,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: t.amountReceived,
                    prefixText: '$sym ',
                    helperText: _split
                        ? t.cashPortionHint.replaceAll(
                            '{amount}',
                            Money.format(_cashPortion, symbol: sym),
                          )
                        : null,
                    errorText: _error,
                  ),
                  onSubmitted: (_) {
                    if (_canComplete) _complete();
                  },
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    for (final amount in _suggestions())
                      ActionChip(
                        label: Text(Money.format(amount, symbol: sym)),
                        onPressed: () => _setReceived(amount),
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _change > 0
                        ? AppColors.green.withValues(alpha: 0.12)
                        : AppColors.cardAlt,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: _change > 0 ? AppColors.green.withValues(alpha: 0.35) : AppColors.line,
                    ),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          t.changeDue,
                          style: TextStyle(color: AppColors.muted, fontWeight: FontWeight.w600),
                        ),
                      ),
                      Text(
                        Money.format(_change, symbol: sym),
                        style: TextStyle(
                          color: _change > 0 ? AppColors.green : AppColors.text,
                          fontWeight: FontWeight.w800,
                          fontSize: 22,
                        ),
                      ),
                    ],
                  ),
                ),
              ] else if (_error != null) ...[
                const SizedBox(height: 12),
                Text(_error!, style: const TextStyle(color: AppColors.red)),
              ],
              if (_split && _lines.isNotEmpty) ...[
                const SizedBox(height: 12),
                Text(
                  _lines.map((l) => '${_labelFor(l.method)} ${Money.format(l.amount, symbol: sym)}').join(' · '),
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
              ],
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t.cancel),
        ),
        FilledButton(
          onPressed: _canComplete ? _complete : null,
          child: Text(t.completeSale),
        ),
      ],
    );
  }
}
