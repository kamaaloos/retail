import 'dart:io';
import 'dart:typed_data';

import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../l10n/app_strings.dart';
import '../models/sale.dart';
import '../models/settings_config.dart';
import '../models/staff.dart';

class ReceiptStoreInfo {
  final String storeName;
  final String phone;
  final String email;
  final String address;
  final String receiptHeader;
  final String receiptFooter;
  final String currencySymbol;
  final String taxName;
  final String? logoPath;

  const ReceiptStoreInfo({
    required this.storeName,
    this.phone = '',
    this.email = '',
    this.address = '',
    this.receiptHeader = '',
    this.receiptFooter = '',
    this.currencySymbol = '\$',
    this.taxName = 'Tax',
    this.logoPath,
  });
}

class ReceiptPrintOptions {
  final double? amountReceived;
  final double? change;
  final bool forceDialog;
  final int paperWidthMm;

  const ReceiptPrintOptions({
    this.amountReceived,
    this.change,
    this.forceDialog = false,
    this.paperWidthMm = 80,
  });
}

class ReceiptPrinter {
  ReceiptPrinter._();

  static PrinterConfig? defaultPrinter(List<PrinterConfig> printers) {
    final active = printers.where((p) => p.active).toList();
    if (active.isEmpty) return null;
    for (final p in active) {
      if (p.isDefault) return p;
    }
    return active.first;
  }

  static Future<void> printSale({
    required SaleDetail detail,
    required ReceiptStoreInfo store,
    required AppStrings t,
    required String Function(String method) paymentLabel,
    List<PrinterConfig> printers = const [],
    ReceiptPrintOptions options = const ReceiptPrintOptions(),
  }) async {
    final config = defaultPrinter(printers);
    final widthMm = config?.paperWidth ?? options.paperWidthMm;
    final bytes = await buildReceiptPdf(
      detail: detail,
      store: store,
      t: t,
      paymentLabel: paymentLabel,
      paperWidthMm: widthMm,
      amountReceived: options.amountReceived,
      change: options.change,
    );

    final jobName = 'Receipt ${detail.sale.receiptNumber}';

    if (!options.forceDialog && config != null) {
      final systemPrinters = await Printing.listPrinters();
      final match = _matchPrinter(systemPrinters, config);
      if (match != null) {
        try {
          await Printing.directPrintPdf(
            printer: match,
            name: jobName,
            onLayout: (_) async => bytes,
          );
          return;
        } catch (_) {
          // Fall through to dialog if direct print fails.
        }
      }
    }

    await Printing.layoutPdf(
      name: jobName,
      onLayout: (_) async => bytes,
    );
  }

  static Future<void> printTest({
    required ReceiptStoreInfo store,
    required AppStrings t,
    PrinterConfig? printer,
  }) async {
    final widthMm = printer?.paperWidth ?? 80;
    final doc = pw.Document();
    final pageFormat = PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      120 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.center,
          children: [
            pw.Text(
              store.storeName,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),
            pw.Text(t.testPrintTitle, style: const pw.TextStyle(fontSize: 11)),
            pw.SizedBox(height: 6),
            pw.Text(
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              style: const pw.TextStyle(fontSize: 9),
            ),
            pw.SizedBox(height: 10),
            pw.Text(
              t.testPrintBody,
              style: const pw.TextStyle(fontSize: 9),
              textAlign: pw.TextAlign.center,
            ),
            if (printer != null) ...[
              pw.SizedBox(height: 8),
              pw.Text(
                '${printer.name} · ${printer.paperWidth}mm',
                style: const pw.TextStyle(fontSize: 8),
              ),
            ],
          ],
        ),
      ),
    );
    await Printing.layoutPdf(
      name: 'MayleSoft test print',
      onLayout: (_) => doc.save(),
    );
  }

  static Future<void> printZReport({
    required ShiftSummary summary,
    required ReceiptStoreInfo store,
    required AppStrings t,
    required String Function(String method) paymentLabel,
    List<PrinterConfig> printers = const [],
    double? countedCash,
    bool forceDialog = false,
  }) async {
    final config = defaultPrinter(printers);
    final widthMm = config?.paperWidth ?? 80;
    final money = NumberFormat.currency(symbol: store.currencySymbol, decimalDigits: 2);
    final shift = summary.shift;
    final opened = DateTime.tryParse(shift.openedAt ?? '') ?? DateTime.now();
    final closed = DateTime.tryParse(shift.closedAt ?? '') ?? DateTime.now();
    final counted = countedCash ?? shift.closingCash;
    final expected = shift.expectedCash ?? summary.expectedCash;
    final difference = counted != null ? counted - expected : shift.difference;

    final doc = pw.Document();
    final pageFormat = PdfPageFormat(
      widthMm * PdfPageFormat.mm,
      200 * PdfPageFormat.mm,
      marginAll: 4 * PdfPageFormat.mm,
    );
    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) => pw.Column(
          crossAxisAlignment: pw.CrossAxisAlignment.stretch,
          children: [
            pw.Text(
              store.storeName,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 4),
            pw.Text(
              t.zReportTitle,
              textAlign: pw.TextAlign.center,
              style: pw.TextStyle(fontSize: 11, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 6),
            _kv(t.cashierLabel, shift.employeeName ?? '—'),
            _kv(t.openedAtLabel, DateFormat('yyyy-MM-dd HH:mm').format(opened)),
            _kv(t.closedAtLabel, DateFormat('yyyy-MM-dd HH:mm').format(closed)),
            _divider(),
            _kv(t.salesCount, '${summary.saleCount}'),
            _kv(t.totalSalesLabel, money.format(summary.totalSales)),
            _kv(paymentLabel('cash'), money.format(summary.cashSales)),
            _kv(paymentLabel('card'), money.format(summary.cardSales)),
            if (summary.otherSales > 0.0001)
              _kv(t.otherPayments, money.format(summary.otherSales)),
            if (summary.refunds > 0.0001)
              _kv(t.refundsLabel, money.format(summary.refunds)),
            _divider(),
            _kv(t.openingCash, money.format(shift.openingCash)),
            _kv(t.cashSales, money.format(summary.cashSales)),
            _kv(t.cashInBtn, money.format(summary.cashIn)),
            _kv(t.cashOutBtn, money.format(summary.cashOut)),
            _kv(t.expectedCash, money.format(expected), bold: true),
            if (counted != null) _kv(t.colClosing, money.format(counted), bold: true),
            if (difference != null)
              _kv(t.differenceLabel, money.format(difference), bold: true),
            if (summary.movements.isNotEmpty) ...[
              _divider(),
              pw.Text(
                t.cashMovements,
                style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 4),
              ...summary.movements.take(12).map((m) {
                final label = m.movementType == 'in' ? t.movementIn : t.movementOut;
                final note = (m.note != null && m.note!.isNotEmpty) ? ' · ${m.note}' : '';
                return _kv('$label$note', money.format(m.amount));
              }),
            ],
            pw.SizedBox(height: 8),
            _divider(),
            pw.Text(
              DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
              textAlign: pw.TextAlign.center,
              style: const pw.TextStyle(fontSize: 8),
            ),
          ],
        ),
      ),
    );

    final bytes = await doc.save();
    final jobName = 'Z-Report ${shift.id ?? ''}';
    if (!forceDialog && config != null) {
      final systemPrinters = await Printing.listPrinters();
      final match = _matchPrinter(systemPrinters, config);
      if (match != null) {
        try {
          await Printing.directPrintPdf(
            printer: match,
            name: jobName,
            onLayout: (_) async => bytes,
          );
          return;
        } catch (_) {}
      }
    }
    await Printing.layoutPdf(
      name: jobName,
      onLayout: (_) async => bytes,
    );
  }

  static Printer? _matchPrinter(List<Printer> system, PrinterConfig config) {
    final target = config.name.trim().toLowerCase();
    final address = config.address.trim().toLowerCase();
    for (final p in system) {
      final name = p.name.toLowerCase();
      if (target.isNotEmpty && (name == target || name.contains(target) || target.contains(name))) {
        return p;
      }
      if (address.isNotEmpty && name.contains(address)) return p;
    }
    return null;
  }

  static Future<Uint8List> buildReceiptPdf({
    required SaleDetail detail,
    required ReceiptStoreInfo store,
    required AppStrings t,
    required String Function(String method) paymentLabel,
    int paperWidthMm = 80,
    double? amountReceived,
    double? change,
  }) async {
    final sale = detail.sale;
    final money = NumberFormat.currency(symbol: store.currencySymbol, decimalDigits: 2);
    final when = DateTime.tryParse(sale.soldAt ?? '') ?? DateTime.now();
    final dateStr = DateFormat('yyyy-MM-dd HH:mm').format(when);

    pw.ImageProvider? logo;
    final logoPath = store.logoPath;
    if (logoPath != null && logoPath.isNotEmpty) {
      final file = File(logoPath);
      if (await file.exists()) {
        logo = pw.MemoryImage(await file.readAsBytes());
      }
    }

    final doc = pw.Document();
    final pageWidth = paperWidthMm * PdfPageFormat.mm;
    final estimatedMm = 90.0 + detail.items.length * 14.0 + detail.payments.length * 6.0;
    final pageFormat = PdfPageFormat(
      pageWidth,
      estimatedMm.clamp(140, 600) * PdfPageFormat.mm,
      marginAll: 3.5 * PdfPageFormat.mm,
    );

    doc.addPage(
      pw.Page(
        pageFormat: pageFormat,
        build: (context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              if (logo != null) ...[
                pw.Center(child: pw.Image(logo, height: 36, fit: pw.BoxFit.contain)),
                pw.SizedBox(height: 6),
              ],
              pw.Text(
                store.storeName,
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontSize: 13, fontWeight: pw.FontWeight.bold),
              ),
              if (store.address.trim().isNotEmpty)
                pw.Text(store.address, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (store.phone.trim().isNotEmpty)
                pw.Text(store.phone, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (store.email.trim().isNotEmpty)
                pw.Text(store.email, textAlign: pw.TextAlign.center, style: const pw.TextStyle(fontSize: 8)),
              if (store.receiptHeader.trim().isNotEmpty) ...[
                pw.SizedBox(height: 4),
                pw.Text(
                  store.receiptHeader,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                ),
              ],
              pw.SizedBox(height: 6),
              _divider(),
              _kv(t.receiptLabel, sale.receiptNumber, bold: true),
              _kv(t.dateLabel, dateStr),
              if ((sale.employeeName ?? '').isNotEmpty) _kv(t.cashierLabel, sale.employeeName!),
              pw.SizedBox(height: 4),
              _divider(),
              ...detail.items.map((item) {
                final qty = item.quantity == item.quantity.roundToDouble()
                    ? item.quantity.toInt().toString()
                    : item.quantity.toStringAsFixed(2);
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 4),
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                    children: [
                      pw.Text(item.productName, style: const pw.TextStyle(fontSize: 9)),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            '$qty × ${money.format(item.unitPrice)}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                          pw.Text(money.format(item.lineTotal), style: const pw.TextStyle(fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                );
              }),
              _divider(),
              _kv(t.subtotal, money.format(sale.subtotal)),
              if (sale.discount > 0.0001) _kv(t.discount, '-${money.format(sale.discount)}'),
              if (sale.tax > 0.0001) _kv(store.taxName, money.format(sale.tax)),
              if (() {
                final preRound = sale.subtotal - sale.discount + sale.tax;
                return (sale.total - preRound).abs() > 0.0001;
              }())
                _kv(
                  t.cashRounding,
                  money.format(sale.total - (sale.subtotal - sale.discount + sale.tax)),
                ),
              pw.SizedBox(height: 2),
              _kv(t.total, money.format(sale.total), bold: true, large: true),
              pw.SizedBox(height: 4),
              ...detail.payments.map(
                (p) => _kv(paymentLabel(p.method), money.format(p.amount)),
              ),
              if (amountReceived != null && amountReceived > 0)
                _kv(t.amountReceived, money.format(amountReceived)),
              if (change != null && change > 0.0001)
                _kv(t.changeDue, money.format(change), bold: true),
              pw.SizedBox(height: 6),
              _divider(),
              if (store.receiptFooter.trim().isNotEmpty)
                pw.Text(
                  store.receiptFooter,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 8),
                )
              else
                pw.Text(
                  t.thankYou,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 9),
                ),
            ],
          );
        },
      ),
    );

    return doc.save();
  }

  static pw.Widget _divider() => pw.Container(
        margin: const pw.EdgeInsets.symmetric(vertical: 3),
        decoration: const pw.BoxDecoration(
          border: pw.Border(top: pw.BorderSide(width: 0.4)),
        ),
        height: 1,
      );

  static pw.Widget _kv(String label, String value, {bool bold = false, bool large = false}) {
    final style = pw.TextStyle(
      fontSize: large ? 11 : 8,
      fontWeight: bold ? pw.FontWeight.bold : pw.FontWeight.normal,
    );
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 1),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(label, style: style),
          pw.Text(value, style: style),
        ],
      ),
    );
  }
}
