import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../data/product_images.dart';
import '../l10n/app_strings.dart';
import '../models/category.dart';
import '../models/product.dart';
import '../models/sale.dart';
import '../models/staff.dart';
import '../providers/retail_store.dart';
import 'report_charts.dart';
import 'theme.dart';
import 'widgets.dart';

AppStrings _t(BuildContext context) => AppStrings.of(context.read<RetailStore>().language);

String _fmtQty(double q, {bool decimal = false}) {
  if (decimal) return q.toStringAsFixed(q == q.roundToDouble() ? 0 : 1);
  return q == q.roundToDouble() ? q.toInt().toString() : q.toStringAsFixed(1);
}

String _fmtDate(String? iso, [AppStrings? strings]) {
  if (strings != null) return strings.formatDateIso(iso);
  if (iso == null || iso.isEmpty) return '—';
  final dt = DateTime.tryParse(iso);
  if (dt == null) return iso;
  return DateFormat('dd MMM yyyy, HH:mm').format(dt);
}

String _fmtShortDate(DateTime d, [AppStrings? strings]) {
  if (strings != null) return strings.formatDate(d, pattern: 'd MMM yyyy');
  return DateFormat('dd MMM yyyy').format(d);
}

Future<void> _snack(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(
      content: Text(message),
      backgroundColor: error ? AppColors.red : null,
    ),
  );
  return Future.value();
}

Future<double?> _promptAmount(
  BuildContext context, {
  required String title,
  String? label,
  double? initial,
}) async {
  final t = _t(context);
  final ctrl = TextEditingController(text: initial != null ? initial.toStringAsFixed(2) : '');
  final result = await showDialog<double>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(labelText: label ?? t.amount),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            final v = double.tryParse(ctrl.text.trim());
            if (v == null || v < 0) return;
            Navigator.pop(ctx, v);
          },
          child: Text(t.ok),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

Future<String?> _promptText(
  BuildContext context, {
  required String title,
  String? label,
  bool required = false,
}) async {
  final t = _t(context);
  final ctrl = TextEditingController();
  final result = await showDialog<String>(
    context: context,
    builder: (ctx) => AlertDialog(
      title: Text(title),
      content: TextField(
        controller: ctrl,
        autofocus: true,
        decoration: InputDecoration(labelText: label ?? t.note),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            final text = ctrl.text.trim();
            if (required && text.isEmpty) return;
            Navigator.pop(ctx, text);
          },
          child: Text(t.ok),
        ),
      ],
    ),
  );
  ctrl.dispose();
  return result;
}

// ─────────────────────────────────────────────────────────────────────────────
// Dashboard
// ─────────────────────────────────────────────────────────────────────────────

class DashboardHome extends StatelessWidget {
  final VoidCallback onOpenPos;

  const DashboardHome({super.key, required this.onOpenPos});

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final s = store.stats;
    final sym = store.currencySymbol;

    if (store.loading) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(
          title: t.dashboard,
          subtitle: t.dashboardSubtitle.replaceAll('{store}', store.storeName),
          actions: [
            FilledButton.icon(
              onPressed: onOpenPos,
              icon: const Icon(Icons.point_of_sale, size: 18),
              label: Text(t.openPos),
            ),
          ],
        ),
        const SizedBox(height: 24),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            StatCard(
              label: t.todaySales,
              value: Money.format(s.todaySales, symbol: sym),
              color: AppColors.accent,
              icon: Icons.payments_outlined,
            ),
            StatCard(
              label: t.transactions,
              value: '${s.todayTransactions}',
              color: AppColors.cyan,
              icon: Icons.receipt_long_outlined,
            ),
            StatCard(
              label: t.grossProfit,
              value: Money.format(s.todayGrossProfit, symbol: sym),
              color: AppColors.green,
              icon: Icons.trending_up,
            ),
            StatCard(
              label: t.lowStock,
              value: '${s.lowStockCount}',
              color: AppColors.amber,
              icon: Icons.warning_amber_rounded,
            ),
          ],
        ),
        const SizedBox(height: 28),
        ShopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(t.recentSales, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 14),
              if (store.recentSales.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(t.noSalesYet, style: TextStyle(color: AppColors.muted)),
                  ),
                )
              else
                ...store.recentSales.take(8).map((sale) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Row(
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColors.cardAlt,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(Icons.receipt, color: AppColors.accent, size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                sale.receiptNumber,
                                style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                              ),
                              Text(
                                '${sale.employeeName ?? t.staffFallback} · ${_fmtDate(sale.soldAt, t)}',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          Money.format(sale.total, symbol: sym),
                          style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text),
                        ),
                        const SizedBox(width: 10),
                        StatusBadge(
                          text: t.saleStatus(sale.status),
                          color: sale.status == 'refunded' ? AppColors.red : AppColors.green,
                        ),
                      ],
                    ),
                  );
                }),
            ],
          ),
        ),
        if (store.lowStockProducts.isNotEmpty) ...[
          const SizedBox(height: 20),
          ShopPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.lowStockAlerts, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                ...store.lowStockProducts.take(5).map((p) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 6),
                    child: Row(
                      children: [
                        CircleAvatar(
                          backgroundColor: parseHexColor(p.color).withValues(alpha: 0.25),
                          child: Icon(Icons.inventory_2, color: parseHexColor(p.color), size: 18),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(p.name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              Text(
                                '${t.stockLabel} ${_fmtQty(p.stockOnHand, decimal: p.isDecimalUnit)} ${p.unit} · ${t.reorderLabel} ${p.reorderLevel}',
                                style: TextStyle(color: AppColors.muted, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        StatusBadge(text: t.lowBadge, color: AppColors.amber),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// POS
// ─────────────────────────────────────────────────────────────────────────────

class PosPage extends StatefulWidget {
  const PosPage({super.key});

  @override
  State<PosPage> createState() => _PosPageState();
}

class _PosPageState extends State<PosPage> {
  final _searchCtrl = TextEditingController();
  int? _categoryId;
  List<Product> _products = [];
  bool _searching = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _reloadProducts());
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _reloadProducts() async {
    final store = context.read<RetailStore>();
    setState(() => _searching = true);
    final list = await store.searchProducts(_searchCtrl.text, categoryId: _categoryId);
    if (!mounted) return;
    setState(() {
      _products = list.where((p) => p.active).toList();
      _searching = false;
    });
  }

  Future<void> _onSearchSubmit() async {
    final q = _searchCtrl.text.trim();
    if (q.isEmpty) {
      await _reloadProducts();
      return;
    }
    final store = context.read<RetailStore>();
    final exact = await store.findProduct(q);
    if (exact != null && mounted) {
      store.addToCart(exact);
      _searchCtrl.clear();
      await _reloadProducts();
      return;
    }
    await _reloadProducts();
  }

  Future<void> _bumpQty(Product product, double delta) async {
    final store = context.read<RetailStore>();
    final existing = store.cart.where((c) => c.product.id == product.id).toList();
    if (existing.isEmpty) {
      if (delta > 0) store.addToCart(product, qty: delta);
      return;
    }
    store.updateCartQty(product.id!, existing.first.quantity + delta);
  }

  Future<void> _setQtyDialog(Product product, double current) async {
    final t = _t(context);
    final ctrl = TextEditingController(text: current.toString());
    final result = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.quantityTitle.replaceAll('{unit}', product.unit)),
        content: TextField(
          controller: ctrl,
          autofocus: true,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(labelText: t.qtyLabel.replaceAll('{unit}', product.unit)),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
          FilledButton(
            onPressed: () {
              final v = double.tryParse(ctrl.text.trim());
              if (v == null) return;
              Navigator.pop(ctx, v);
            },
            child: Text(t.set),
          ),
        ],
      ),
    );
    ctrl.dispose();
    if (result == null || !mounted) return;
    context.read<RetailStore>().updateCartQty(product.id!, result);
  }

  Future<void> _charge() async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    if (store.cart.isEmpty) {
      await _snack(context, t.cartEmpty, error: true);
      return;
    }
    final method = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.chargeTitle),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              Money.format(store.cartTotal, symbol: store.currencySymbol),
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            if (store.enabledPaymentMethods.isEmpty)
              Text(t.noPaymentMethodsYet, style: TextStyle(color: AppColors.muted))
            else
              ...store.enabledPaymentMethods.asMap().entries.map((entry) {
                final method = entry.value;
                final isFirst = entry.key == 0;
                return Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: isFirst
                      ? FilledButton(
                          onPressed: () => Navigator.pop(ctx, method.code),
                          child: Text(method.label),
                        )
                      : OutlinedButton(
                          onPressed: () => Navigator.pop(ctx, method.code),
                          child: Text(method.label),
                        ),
                );
              }),
          ],
        ),
      ),
    );
    if (method == null || !mounted) return;
    try {
      final sale = await store.checkout(paymentMethod: method);
      if (!mounted) return;
      await _reloadProducts();
      await _snack(context, t.saleCompleted.replaceAll('{receipt}', sale.receiptNumber));
    } catch (e) {
      if (!mounted) return;
      await _snack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final sym = store.currencySymbol;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            flex: 3,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                PageTitle(title: t.posTitle, subtitle: t.posSubtitle),
                const SizedBox(height: 14),
                TextField(
                  controller: _searchCtrl,
                  onChanged: (_) => _reloadProducts(),
                  onSubmitted: (_) => _onSearchSubmit(),
                  decoration: InputDecoration(
                    hintText: t.searchHint,
                    prefixIcon: Icon(Icons.search, color: AppColors.muted),
                    suffixIcon: IconButton(
                      icon: const Icon(Icons.qr_code_scanner, color: AppColors.accent),
                      onPressed: _onSearchSubmit,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      SoftChip(
                        label: t.allCategories,
                        selected: _categoryId == null,
                        onTap: () {
                          setState(() => _categoryId = null);
                          _reloadProducts();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...store.categories.map((c) {
                        return Padding(
                          padding: const EdgeInsets.only(right: 8),
                          child: SoftChip(
                            label: c.name,
                            selected: _categoryId == c.id,
                            dot: parseHexColor(c.color),
                            onTap: () {
                              setState(() => _categoryId = c.id);
                              _reloadProducts();
                            },
                          ),
                        );
                      }),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
                Expanded(
                  child: _searching
                      ? const Center(child: CircularProgressIndicator(color: AppColors.accent))
                      : _products.isEmpty
                          ? Center(
                              child: Text(t.noProductsFound, style: TextStyle(color: AppColors.muted)),
                            )
                          : GridView.builder(
                              gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                                maxCrossAxisExtent: 180,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                childAspectRatio: 0.72,
                              ),
                              itemCount: _products.length,
                              itemBuilder: (context, i) {
                                final p = _products[i];
                                final inCart = store.cart.where((c) => c.product.id == p.id).toList();
                                final qty = inCart.isEmpty ? 0.0 : inCart.first.quantity;
                                final color = parseHexColor(p.color);
                                return InkWell(
                                  onTap: () => store.addToCart(p),
                                  borderRadius: BorderRadius.circular(14),
                                  child: Container(
                                    decoration: BoxDecoration(
                                      color: AppColors.card,
                                      borderRadius: BorderRadius.circular(14),
                                      border: Border.all(color: AppColors.line),
                                    ),
                                    clipBehavior: Clip.antiAlias,
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.stretch,
                                      children: [
                                        AspectRatio(
                                          aspectRatio: 1.35,
                                          child: ProductThumb(
                                            imagePath: p.imagePath,
                                            colorHex: p.color,
                                            size: null,
                                            radius: 0,
                                          ),
                                        ),
                                        Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.all(12),
                                            child: Column(
                                              crossAxisAlignment: CrossAxisAlignment.start,
                                              children: [
                                                Row(
                                                  children: [
                                                    Expanded(
                                                      child: Text(
                                                        p.name,
                                                        maxLines: 2,
                                                        overflow: TextOverflow.ellipsis,
                                                        style: TextStyle(
                                                          color: AppColors.text,
                                                          fontWeight: FontWeight.w700,
                                                          fontSize: 13,
                                                        ),
                                                      ),
                                                    ),
                                                    if (qty > 0)
                                                      Container(
                                                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                                                        decoration: BoxDecoration(
                                                          color: AppColors.accent,
                                                          borderRadius: BorderRadius.circular(8),
                                                        ),
                                                        child: Text(
                                                          _fmtQty(qty, decimal: p.isDecimalUnit),
                                                          style: const TextStyle(
                                                            color: Colors.white,
                                                            fontWeight: FontWeight.w700,
                                                            fontSize: 11,
                                                          ),
                                                        ),
                                                      ),
                                                  ],
                                                ),
                                                const Spacer(),
                                                Text(
                                                  Money.format(p.sellingPrice, symbol: sym),
                                                  style: TextStyle(
                                                    color: AppColors.text,
                                                    fontWeight: FontWeight.w700,
                                                  ),
                                                ),
                                                Text(
                                                  '${_fmtQty(p.stockOnHand, decimal: p.isDecimalUnit)} ${p.unit}',
                                                  style: TextStyle(
                                                    color: p.isLowStock ? AppColors.amber : AppColors.muted,
                                                    fontSize: 11,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        Container(
                                          height: 6,
                                          color: color,
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          SizedBox(
            width: 340,
            child: ShopPanel(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      Text(t.cart, style: Theme.of(context).textTheme.titleLarge),
                      const Spacer(),
                      if (store.cart.isNotEmpty)
                        TextButton(
                          onPressed: store.clearCart,
                          child: Text(t.clearCart),
                        ),
                    ],
                  ),
                  Text(
                    t.cartItemsCount.replaceAll('{count}', '${store.cartCount}'),
                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                  ),
                  const SizedBox(height: 10),
                  Expanded(
                    child: store.cart.isEmpty
                        ? Center(
                            child: Text(t.tapProductsToAdd, style: TextStyle(color: AppColors.muted)),
                          )
                        : ListView.separated(
                            itemCount: store.cart.length,
                            separatorBuilder: (_, __) => Divider(color: AppColors.line, height: 16),
                            itemBuilder: (context, i) {
                              final item = store.cart[i];
                              final p = item.product;
                              final step = p.isDecimalUnit ? 0.1 : 1.0;
                              return Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    p.name,
                                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
                                  ),
                                  if (item.discount > 0) ...[
                                    const SizedBox(height: 2),
                                    Text(
                                      '${t.discountOff}: -${Money.format(item.discount, symbol: sym)}',
                                      style: TextStyle(color: AppColors.green, fontSize: 12, fontWeight: FontWeight.w600),
                                    ),
                                  ],
                                  const SizedBox(height: 2),
                                  Text(
                                    Money.format(item.lineTotal, symbol: sym),
                                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      _QtyBtn(
                                        icon: Icons.remove,
                                        onTap: () => _bumpQty(p, -step),
                                      ),
                                      InkWell(
                                        onTap: p.isDecimalUnit ? () => _setQtyDialog(p, item.quantity) : null,
                                        child: Padding(
                                          padding: const EdgeInsets.symmetric(horizontal: 12),
                                          child: Text(
                                            _fmtQty(item.quantity, decimal: p.isDecimalUnit),
                                            style: TextStyle(
                                              color: AppColors.text,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ),
                                      _QtyBtn(
                                        icon: Icons.add,
                                        onTap: () => _bumpQty(p, step),
                                      ),
                                      const Spacer(),
                                      IconButton(
                                        icon: const Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                                        onPressed: () => store.updateCartQty(p.id!, 0),
                                      ),
                                    ],
                                  ),
                                ],
                              );
                            },
                          ),
                  ),
                  Divider(color: AppColors.line),
                  _cartLine(t.subtotal, Money.format(store.cartSubtotal + store.cartDiscountTotal, symbol: sym)),
                  if (store.cartDiscountTotal > 0)
                    _cartLine(t.cartDiscount, '-${Money.format(store.cartDiscountTotal, symbol: sym)}'),
                  _cartLine(t.tax, Money.format(store.cartTax, symbol: sym)),
                  const SizedBox(height: 6),
                  _cartLine(t.total, Money.format(store.cartTotal, symbol: sym), bold: true),
                  const SizedBox(height: 14),
                  SizedBox(
                    height: 48,
                    child: FilledButton(
                      onPressed: store.cart.isEmpty ? null : _charge,
                      child: Text(t.chargeBtn.replaceAll('{amount}', Money.format(store.cartTotal, symbol: sym))),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _cartLine(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Text(
            label,
            style: TextStyle(
              color: bold ? AppColors.text : AppColors.muted,
              fontWeight: bold ? FontWeight.w700 : FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              color: AppColors.text,
              fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
              fontSize: bold ? 16 : 13,
            ),
          ),
        ],
      ),
    );
  }
}

class _QtyBtn extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;

  const _QtyBtn({required this.icon, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        width: 32,
        height: 32,
        decoration: BoxDecoration(
          color: AppColors.cardAlt,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.line),
        ),
        child: Icon(icon, size: 16, color: AppColors.text),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Products
// ─────────────────────────────────────────────────────────────────────────────

class ProductsPage extends StatelessWidget {
  const ProductsPage({super.key});

  Future<void> _openEditor(BuildContext context, {Product? existing}) async {
    final store = context.read<RetailStore>();
    final t = _t(context);
    final result = await showDialog<Product>(
      context: context,
      builder: (_) => _ProductEditorDialog(existing: existing, categories: store.categories),
    );
    if (result == null || !context.mounted) return;
    try {
      if (existing == null) {
        await store.addProduct(result);
        if (context.mounted) await _snack(context, t.productAdded);
      } else {
        await store.updateProduct(result);
        if (context.mounted) await _snack(context, t.productUpdated);
      }
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _delete(BuildContext context, Product p) async {
    final t = _t(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deactivateProduct),
        content: Text(t.deactivateProductConfirm.replaceAll('{name}', p.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(t.deactivateBtn),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<RetailStore>().deactivateProduct(p.id!);
    if (context.mounted) await _snack(context, t.productDeactivated);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final sym = store.currencySymbol;
    final products = store.productList.where((p) => p.active).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(
          title: t.products,
          subtitle: t.productsSubtitle.replaceAll('{count}', '${products.length}'),
          actions: [
            FilledButton.icon(
              onPressed: () => _openEditor(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.newProduct),
            ),
          ],
        ),
        const SizedBox(height: 20),
        ShopPanel(
          padding: EdgeInsets.zero,
          child: products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(t.noProductsYet, style: TextStyle(color: AppColors.muted))),
                )
              : SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(t.colName)),
                      DataColumn(label: Text(t.colPrice)),
                      DataColumn(label: Text(t.colCost)),
                      DataColumn(label: Text(t.colStock)),
                      DataColumn(label: Text(t.colSkuBarcode)),
                      DataColumn(label: Text(t.colCategory)),
                      const DataColumn(label: Text('')),
                    ],
                    rows: products.map((p) {
                      return DataRow(
                        cells: [
                          DataCell(
                            Row(
                              children: [
                                ProductThumb(imagePath: p.imagePath, colorHex: p.color, size: 36),
                                const SizedBox(width: 10),
                                Text(p.name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                          DataCell(Text(Money.format(p.sellingPrice, symbol: sym))),
                          DataCell(Text(Money.format(p.costPrice, symbol: sym))),
                          DataCell(
                            StatusBadge(
                              text: '${_fmtQty(p.stockOnHand, decimal: p.isDecimalUnit)} ${p.unit}',
                              color: p.isLowStock ? AppColors.amber : AppColors.green,
                            ),
                          ),
                          DataCell(
                            Text(
                              [p.sku, if (p.barcode != null && p.barcode!.isNotEmpty) p.barcode].join(' · '),
                              style: TextStyle(color: AppColors.muted, fontSize: 12),
                            ),
                          ),
                          DataCell(Text(p.categoryName ?? '—', style: TextStyle(color: AppColors.muted))),
                          DataCell(
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  onPressed: () => _openEditor(context, existing: p),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                                  onPressed: () => _delete(context, p),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
        ),
      ],
    );
  }
}

class _ProductEditorDialog extends StatefulWidget {
  final Product? existing;
  final List<Category> categories;

  const _ProductEditorDialog({this.existing, required this.categories});

  @override
  State<_ProductEditorDialog> createState() => _ProductEditorDialogState();
}

class _ProductEditorDialogState extends State<_ProductEditorDialog> {
  late final TextEditingController _name;
  late final TextEditingController _sku;
  late final TextEditingController _barcode;
  late final TextEditingController _price;
  late final TextEditingController _cost;
  late final TextEditingController _tax;
  late final TextEditingController _reorder;
  late final TextEditingController _stock;
  late String _unit;
  late String _color;
  int? _categoryId;
  String? _imagePath;
  String? _pickedSource;
  bool _clearImage = false;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _name = TextEditingController(text: e?.name ?? '');
    _sku = TextEditingController(text: e?.sku ?? '');
    _barcode = TextEditingController(text: e?.barcode ?? '');
    _price = TextEditingController(text: e != null ? e.sellingPrice.toString() : '');
    _cost = TextEditingController(text: e != null ? e.costPrice.toString() : '');
    _tax = TextEditingController(text: e != null ? e.taxRate.toString() : '0');
    _reorder = TextEditingController(text: e != null ? e.reorderLevel.toString() : '5');
    _stock = TextEditingController(text: e != null ? e.stockOnHand.toString() : '0');
    _unit = e?.unit ?? 'pcs';
    _color = e?.color ?? productColorPalette.first;
    _categoryId = e?.categoryId;
    _imagePath = e?.imagePath;
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _barcode.dispose();
    _price.dispose();
    _cost.dispose();
    _tax.dispose();
    _reorder.dispose();
    _stock.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    final files = await FilePicker.pickFiles(
      type: FileType.image,
      allowMultiple: false,
    );
    if (files.isEmpty) return;
    final path = files.first.path;
    if (path == null) return;
    setState(() {
      _pickedSource = path;
      _imagePath = path;
      _clearImage = false;
    });
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final sku = _sku.text.trim();
    if (name.isEmpty || sku.isEmpty || _saving) return;
    setState(() => _saving = true);
    try {
      String? imagePath = widget.existing?.imagePath;
      if (_clearImage) {
        await ProductImageStore.deleteIfExists(imagePath);
        imagePath = null;
      } else if (_pickedSource != null) {
        await ProductImageStore.deleteIfExists(widget.existing?.imagePath);
        imagePath = await ProductImageStore.saveFromPath(_pickedSource!, productKey: sku);
      }

      final product = Product(
        id: widget.existing?.id,
        name: name,
        sku: sku,
        barcode: _barcode.text.trim().isEmpty ? null : _barcode.text.trim(),
        categoryId: _categoryId,
        unit: _unit,
        color: _color,
        imagePath: imagePath,
        sellingPrice: double.tryParse(_price.text.trim()) ?? 0,
        costPrice: double.tryParse(_cost.text.trim()) ?? 0,
        taxRate: double.tryParse(_tax.text.trim()) ?? 0,
        reorderLevel: double.tryParse(_reorder.text.trim()) ?? 0,
        stockOnHand: double.tryParse(_stock.text.trim()) ?? 0,
        active: true,
      );
      if (!mounted) return;
      Navigator.pop(context, product);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_t(context).couldNotSaveImage.replaceAll('{error}', '$e')),
          backgroundColor: AppColors.red,
        ),
      );
      setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    final previewPath = _clearImage ? null : _imagePath;
    return AlertDialog(
      title: Text(widget.existing == null ? t.newProduct : t.editProduct),
      content: SizedBox(
        width: 460,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  ProductThumb(
                    imagePath: previewPath,
                    colorHex: _color,
                    size: 72,
                    radius: 12,
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(t.productImage, style: Theme.of(context).textTheme.titleMedium),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _saving ? null : _pickImage,
                              icon: const Icon(Icons.upload, size: 16),
                              label: Text(t.upload),
                            ),
                            if (previewPath != null)
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() {
                                          _clearImage = true;
                                          _pickedSource = null;
                                          _imagePath = null;
                                        }),
                                child: Text(t.remove),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              TextField(controller: _name, decoration: InputDecoration(labelText: t.colName)),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(child: TextField(controller: _sku, decoration: InputDecoration(labelText: t.sku))),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(controller: _barcode, decoration: InputDecoration(labelText: t.barcode)),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _unit,
                      decoration: InputDecoration(labelText: t.unitLabel),
                      items: productUnits
                          .map((u) => DropdownMenuItem(value: u, child: Text(u)))
                          .toList(),
                      onChanged: (v) => setState(() => _unit = v ?? 'pcs'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _categoryId,
                      decoration: InputDecoration(labelText: t.colCategory),
                      items: [
                        DropdownMenuItem<int?>(value: null, child: Text(t.none)),
                        ...widget.categories.map(
                          (c) => DropdownMenuItem<int?>(value: c.id, child: Text(c.name)),
                        ),
                      ],
                      onChanged: (v) => setState(() => _categoryId = v),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _price,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.sellingPrice),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _cost,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.costLabel),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _tax,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.taxPercent),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _reorder,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.reorderLevel),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _stock,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      decoration: InputDecoration(labelText: t.colStock),
                      enabled: widget.existing == null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(t.color, style: Theme.of(context).textTheme.titleMedium),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productColorPalette.map((hex) {
                  final selected = _color == hex;
                  return InkWell(
                    onTap: () => setState(() => _color = hex),
                    borderRadius: BorderRadius.circular(20),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: parseHexColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: selected ? Colors.white : Colors.transparent,
                          width: 2,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: _saving ? null : () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: _saving ? null : _save,
          child: _saving
              ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
              : Text(t.save),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Categories
// ─────────────────────────────────────────────────────────────────────────────

class CategoriesPage extends StatelessWidget {
  const CategoriesPage({super.key});

  Future<void> _edit(BuildContext context, {Category? existing}) async {
    final t = _t(context);
    final nameCtrl = TextEditingController(text: existing?.name ?? '');
    var color = existing?.color ?? productColorPalette.first;
    final result = await showDialog<(String, String)>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(existing == null ? t.newCategory : t.editCategory),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: nameCtrl, decoration: InputDecoration(labelText: t.colName)),
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: productColorPalette.map((hex) {
                  final selected = color == hex;
                  return InkWell(
                    onTap: () => setLocal(() => color = hex),
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: parseHexColor(hex),
                        shape: BoxShape.circle,
                        border: Border.all(color: selected ? Colors.white : Colors.transparent, width: 2),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: Text(t.cancel)),
            FilledButton(
              onPressed: () {
                final n = nameCtrl.text.trim();
                if (n.isEmpty) return;
                Navigator.pop(ctx, (n, color));
              },
              child: Text(t.save),
            ),
          ],
        ),
      ),
    );
    nameCtrl.dispose();
    if (result == null || !context.mounted) return;
    final store = context.read<RetailStore>();
    if (existing == null) {
      await store.addCategory(result.$1, color: result.$2);
    } else {
      await store.updateCategory(Category(id: existing.id, name: result.$1, color: result.$2));
    }
  }

  Future<void> _delete(BuildContext context, Category c) async {
    final t = _t(context);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.deleteCategory),
        content: Text(t.deleteCategoryConfirm.replaceAll('{name}', c.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.red),
            child: Text(t.delete),
          ),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;
    await context.read<RetailStore>().deleteCategory(c.id!);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(
          title: t.categories,
          subtitle: t.categoriesSubtitle.replaceAll('{count}', '${store.categories.length}'),
          actions: [
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.add, size: 18),
              label: Text(t.newCategory),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (store.categories.isEmpty)
          ShopPanel(
            child: Center(child: Text(t.noCategoriesYet, style: TextStyle(color: AppColors.muted))),
          )
        else
          ...store.categories.map((c) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShopPanel(
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: parseHexColor(c.color).withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Center(
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(color: parseHexColor(c.color), shape: BoxShape.circle),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(c.name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                          Text(
                            t.categoryProductCount.replaceAll('{count}', '${c.productCount}'),
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _edit(context, existing: c),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.red),
                      onPressed: () => _delete(context, c),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sales history
// ─────────────────────────────────────────────────────────────────────────────

class SalesHistoryPage extends StatefulWidget {
  const SalesHistoryPage({super.key});

  @override
  State<SalesHistoryPage> createState() => _SalesHistoryPageState();
}

class _SalesHistoryPageState extends State<SalesHistoryPage> {
  DateTime? _from;
  DateTime? _to;
  int? _employeeId;

  Future<void> _pickFrom() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _from ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() => _from = d);
  }

  Future<void> _pickTo() async {
    final d = await showDatePicker(
      context: context,
      initialDate: _to ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (d == null) return;
    setState(() => _to = DateTime(d.year, d.month, d.day, 23, 59, 59));
  }

  Future<void> _apply() async {
    await context.read<RetailStore>().filterSales(from: _from, to: _to, employeeId: _employeeId);
  }

  Future<void> _showDetail(Sale sale) async {
    if (sale.id == null) return;
    final store = context.read<RetailStore>();
    final t = _t(context);
    final detail = await store.saleDetail(sale.id!);
    if (detail == null || !mounted) return;
    final sym = store.currencySymbol;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(detail.sale.receiptNumber),
        content: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(_fmtDate(detail.sale.soldAt, t), style: TextStyle(color: AppColors.muted)),
                Text(
                  detail.sale.employeeName ?? t.staffFallback,
                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                ),
                const SizedBox(height: 12),
                ...detail.items.map((item) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${item.productName} × ${_fmtQty(item.quantity)}',
                            style: TextStyle(color: AppColors.text),
                          ),
                        ),
                        Text(Money.format(item.lineTotal, symbol: sym)),
                      ],
                    ),
                  );
                }),
                Divider(color: AppColors.line),
                Row(
                  children: [
                    Text(t.total, style: TextStyle(fontWeight: FontWeight.w700, color: AppColors.text)),
                    const Spacer(),
                    Text(
                      Money.format(detail.sale.total, symbol: sym),
                      style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.text),
                    ),
                  ],
                ),
                if (detail.payments.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  ...detail.payments.map(
                    (p) => Text(
                      '${t.paymentMethod(p.method)}: ${Money.format(p.amount, symbol: sym)}',
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
        actions: [
          if (detail.sale.status != 'refunded')
            TextButton(
              onPressed: () async {
                Navigator.pop(ctx);
                await _refund(detail);
              },
              child: Text(t.refund, style: const TextStyle(color: AppColors.red)),
            ),
          FilledButton(onPressed: () => Navigator.pop(ctx), child: Text(t.closeBtn)),
        ],
      ),
    );
  }

  Future<void> _refund(SaleDetail detail) async {
    final t = _t(context);
    final reason = await _promptText(context, title: t.refundReason, label: t.reason, required: true);
    if (reason == null || !mounted) return;
    final quantities = <int, double>{
      for (final item in detail.items) item.productId: item.quantity,
    };
    try {
      await context.read<RetailStore>().refundSale(
            saleId: detail.sale.id!,
            quantities: quantities,
            reason: reason,
          );
      if (mounted) await _snack(context, t.saleRefunded);
    } catch (e) {
      if (mounted) await _snack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final sym = store.currencySymbol;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(title: t.salesHistory, subtitle: t.salesHistorySubtitle),
        const SizedBox(height: 16),
        ShopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Wrap(
                spacing: 12,
                runSpacing: 12,
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  OutlinedButton.icon(
                    onPressed: _pickFrom,
                    icon: const Icon(Icons.calendar_today, size: 16),
                    label: Text(_from == null ? t.filterFrom : _fmtShortDate(_from!, t)),
                  ),
                  OutlinedButton.icon(
                    onPressed: _pickTo,
                    icon: const Icon(Icons.event, size: 16),
                    label: Text(_to == null ? t.filterTo : _fmtShortDate(_to!, t)),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<int?>(
                      value: _employeeId,
                      isExpanded: true,
                      decoration: InputDecoration(labelText: t.employee),
                      items: [
                        DropdownMenuItem<int?>(
                          value: null,
                          child: Text(t.allStaff, overflow: TextOverflow.ellipsis),
                        ),
                        ...store.employees.map(
                          (e) => DropdownMenuItem<int?>(
                            value: e.id,
                            child: Text(e.name, overflow: TextOverflow.ellipsis),
                          ),
                        ),
                      ],
                      onChanged: (v) => setState(() => _employeeId = v),
                    ),
                  ),
                  const SizedBox(width: 12),
                  FilledButton(onPressed: _apply, child: Text(t.apply)),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ShopPanel(
          padding: EdgeInsets.zero,
          child: store.filteredSales.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(t.noSalesInPeriod, style: TextStyle(color: AppColors.muted))),
                )
              : Column(
                  children: store.filteredSales.map((sale) {
                    return InkWell(
                      onTap: () => _showDetail(sale),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border(bottom: BorderSide(color: AppColors.line)),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    sale.receiptNumber,
                                    style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                                  ),
                                  Text(
                                    '${sale.employeeName ?? t.staffFallback} · ${_fmtDate(sale.soldAt, t)}',
                                    style: TextStyle(color: AppColors.muted, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              Money.format(sale.total, symbol: sym),
                              style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(width: 12),
                            StatusBadge(
                              text: t.saleStatus(sale.status),
                              color: sale.status == 'refunded' ? AppColors.red : AppColors.green,
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Inventory
// ─────────────────────────────────────────────────────────────────────────────

class InventoryPage extends StatelessWidget {
  const InventoryPage({super.key});

  Future<void> _adjust(BuildContext context, Product p) async {
    final t = _t(context);
    final deltaCtrl = TextEditingController();
    final reasonCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.adjustStockTitle.replaceAll('{name}', p.name)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              t.currentStock
                  .replaceAll('{qty}', _fmtQty(p.stockOnHand, decimal: p.isDecimalUnit))
                  .replaceAll('{unit}', p.unit),
              style: TextStyle(color: AppColors.muted),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: deltaCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true, signed: true),
              decoration: InputDecoration(labelText: t.quantityDelta),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: reasonCtrl,
              decoration: InputDecoration(labelText: t.reasonRequired),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.apply)),
        ],
      ),
    );
    final delta = double.tryParse(deltaCtrl.text.trim());
    final reason = reasonCtrl.text.trim();
    deltaCtrl.dispose();
    reasonCtrl.dispose();
    if (ok != true || delta == null || reason.isEmpty || !context.mounted) return;
    try {
      await context.read<RetailStore>().adjustStock(
            productId: p.id!,
            quantityDelta: delta,
            reason: reason,
          );
      if (context.mounted) await _snack(context, t.stockAdjusted);
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _receive(BuildContext context, {Product? product}) async {
    final store = context.read<RetailStore>();
    final t = _t(context);
    Product? selected = product;
    final qtyCtrl = TextEditingController(text: '1');
    final costCtrl = TextEditingController(text: product?.costPrice.toString() ?? '');
    final invoiceCtrl = TextEditingController();

    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: Text(t.receiveStock),
          content: SizedBox(
            width: 400,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                DropdownButtonFormField<Product>(
                  value: selected,
                  decoration: InputDecoration(labelText: t.productLabel),
                  items: store.productList
                      .where((p) => p.active)
                      .map((p) => DropdownMenuItem(value: p, child: Text(p.name)))
                      .toList(),
                  onChanged: (v) {
                    setLocal(() {
                      selected = v;
                      if (v != null) costCtrl.text = v.costPrice.toString();
                    });
                  },
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: qtyCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t.quantity),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: costCtrl,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  decoration: InputDecoration(labelText: t.unitCost),
                ),
                const SizedBox(height: 10),
                TextField(
                  controller: invoiceCtrl,
                  decoration: InputDecoration(labelText: t.invoiceOptional),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
            FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.receiveBtn)),
          ],
        ),
      ),
    );

    final qty = double.tryParse(qtyCtrl.text.trim());
    final cost = double.tryParse(costCtrl.text.trim());
    final invoice = invoiceCtrl.text.trim();
    qtyCtrl.dispose();
    costCtrl.dispose();
    invoiceCtrl.dispose();

    if (ok != true || selected?.id == null || qty == null || qty <= 0 || cost == null || !context.mounted) {
      return;
    }
    try {
      await store.receivePurchase(
        productId: selected!.id!,
        quantity: qty,
        unitCost: cost,
        invoiceNumber: invoice.isEmpty ? null : invoice,
      );
      if (context.mounted) await _snack(context, t.stockReceived);
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final products = store.productList.where((p) => p.active).toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(
          title: t.inventory,
          subtitle: t.inventorySubtitle,
          actions: [
            FilledButton.icon(
              onPressed: () => _receive(context),
              icon: const Icon(Icons.move_to_inbox, size: 18),
              label: Text(t.receiveStock),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (store.lowStockProducts.isNotEmpty) ...[
          ShopPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.lowStockAlerts, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: store.lowStockProducts.map((p) {
                    return SoftChip(
                      label: '${p.name} (${_fmtQty(p.stockOnHand, decimal: p.isDecimalUnit)})',
                      selected: false,
                      dot: AppColors.amber,
                      onTap: () => _adjust(context, p),
                    );
                  }).toList(),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        ShopPanel(
          padding: EdgeInsets.zero,
          child: products.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(32),
                  child: Center(child: Text(t.noProducts, style: TextStyle(color: AppColors.muted))),
                )
              : Column(
                  children: products.map((p) {
                    return Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: AppColors.line)),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 8,
                            height: 36,
                            decoration: BoxDecoration(
                              color: parseHexColor(p.color),
                              borderRadius: BorderRadius.circular(4),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(p.name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                                Text(
                                  t.reorderLine
                                      .replaceAll('{level}', '${p.reorderLevel}')
                                      .replaceAll('{sku}', p.sku),
                                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          StatusBadge(
                            text: '${_fmtQty(p.stockOnHand, decimal: p.isDecimalUnit)} ${p.unit}',
                            color: p.isLowStock ? AppColors.amber : AppColors.green,
                          ),
                          const SizedBox(width: 8),
                          OutlinedButton(
                            onPressed: () => _adjust(context, p),
                            child: Text(t.adjustBtn),
                          ),
                          const SizedBox(width: 6),
                          OutlinedButton(
                            onPressed: () => _receive(context, product: p),
                            child: Text(t.receiveBtn),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
        ),
        if (store.stockHistory.isNotEmpty) ...[
          const SizedBox(height: 20),
          ShopPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.recentMovements, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                ...store.stockHistory.take(12).map((m) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${m.productName ?? t.productFallback} · ${m.movementType}',
                            style: TextStyle(color: AppColors.text),
                          ),
                        ),
                        Text(
                          '${m.quantity > 0 ? '+' : ''}${_fmtQty(m.quantity)}',
                          style: TextStyle(
                            color: m.quantity >= 0 ? AppColors.green : AppColors.red,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          _fmtDate(m.createdAt, t),
                          style: TextStyle(color: AppColors.muted, fontSize: 11),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Staff
// ─────────────────────────────────────────────────────────────────────────────

class StaffPage extends StatelessWidget {
  const StaffPage({super.key});

  Future<void> _edit(BuildContext context, {Employee? existing}) async {
    final result = await showDialog<(Employee, String?)>(
      context: context,
      builder: (_) => _EmployeeEditorDialog(existing: existing),
    );
    if (result == null || !context.mounted) return;
    final store = context.read<RetailStore>();
    if (existing == null) {
      await store.addEmployee(result.$1, pin: result.$2);
    } else {
      await store.updateEmployee(result.$1, pin: result.$2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(
          title: t.staff,
          subtitle: t.staffSubtitle,
          actions: [
            FilledButton.icon(
              onPressed: () => _edit(context),
              icon: const Icon(Icons.person_add_alt, size: 18),
              label: Text(t.addEmployee),
            ),
          ],
        ),
        const SizedBox(height: 20),
        if (store.employees.isEmpty)
          ShopPanel(
            child: Center(child: Text(t.noEmployeesYet, style: TextStyle(color: AppColors.muted))),
          )
        else
          ...store.employees.map((e) {
            final isCurrent = store.currentEmployee?.id == e.id;
            return Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: ShopPanel(
                child: Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: AppColors.accent.withValues(alpha: 0.25),
                      child: Text(
                        e.name.isNotEmpty ? e.name.characters.first.toUpperCase() : '?',
                        style: TextStyle(color: AppColors.accent, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.name, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                          Text(
                            '${t.roleLabel(e.role)}${e.username != null ? ' · @${e.username}' : ''}',
                            style: TextStyle(color: AppColors.muted, fontSize: 12),
                          ),
                        ],
                      ),
                    ),
                    StatusBadge(
                      text: e.active ? t.active : t.inactive,
                      color: e.active ? AppColors.green : AppColors.muted,
                    ),
                    const SizedBox(width: 8),
                    if (isCurrent)
                      StatusBadge(text: t.badgeCurrent, color: AppColors.accent)
                    else
                      OutlinedButton(
                        onPressed: () => store.setCurrentEmployee(e),
                        child: Text(t.setCurrent),
                      ),
                    IconButton(
                      icon: const Icon(Icons.edit_outlined, size: 18),
                      onPressed: () => _edit(context, existing: e),
                    ),
                  ],
                ),
              ),
            );
          }),
      ],
    );
  }
}

class _EmployeeEditorDialog extends StatefulWidget {
  final Employee? existing;

  const _EmployeeEditorDialog({this.existing});

  @override
  State<_EmployeeEditorDialog> createState() => _EmployeeEditorDialogState();
}

class _EmployeeEditorDialogState extends State<_EmployeeEditorDialog> {
  late final TextEditingController _nameCtrl;
  late final TextEditingController _userCtrl;
  late final TextEditingController _pinCtrl;
  late String _role;
  late bool _active;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _nameCtrl = TextEditingController(text: e?.name ?? '');
    _userCtrl = TextEditingController(text: e?.username ?? '');
    _pinCtrl = TextEditingController();
    _role = e?.role ?? 'cashier';
    _active = e?.active ?? true;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _userCtrl.dispose();
    _pinCtrl.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameCtrl.text.trim();
    final username = _userCtrl.text.trim();
    final pin = _pinCtrl.text.trim();
    if (name.isEmpty) return;
    if (username.isNotEmpty && pin.isNotEmpty && pin.length < 4) return;
    if (widget.existing == null && username.isNotEmpty && pin.length < 4) return;
    Navigator.pop(
      context,
      (
        Employee(
          id: widget.existing?.id,
          name: name,
          username: username.isEmpty ? null : username,
          role: _role,
          active: _active,
        ),
        pin.isEmpty ? null : pin,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = _t(context);
    return AlertDialog(
      title: Text(widget.existing == null ? t.addEmployee : t.editEmployee),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: _nameCtrl, decoration: InputDecoration(labelText: t.colName)),
            const SizedBox(height: 10),
            TextField(controller: _userCtrl, decoration: InputDecoration(labelText: t.username)),
            const SizedBox(height: 10),
            TextField(
              controller: _pinCtrl,
              obscureText: true,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: t.pin,
                hintText: widget.existing == null ? t.pinHint : t.keepCurrentPin,
              ),
            ),
            const SizedBox(height: 10),
            DropdownButtonFormField<String>(
              value: _role,
              decoration: InputDecoration(labelText: t.role),
              items: staffRoles
                  .map((r) => DropdownMenuItem(value: r, child: Text(t.roleLabel(r))))
                  .toList(),
              onChanged: (v) => setState(() => _role = v ?? 'cashier'),
            ),
            Material(
              type: MaterialType.transparency,
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(t.active),
                value: _active,
                onChanged: (v) => setState(() => _active = v),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(onPressed: _save, child: Text(t.save)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Shifts
// ─────────────────────────────────────────────────────────────────────────────

class ShiftsPage extends StatelessWidget {
  const ShiftsPage({super.key});

  Future<void> _open(BuildContext context) async {
    final t = AppStrings.of(context.read<RetailStore>().language);
    final amount = await _promptAmount(context, title: t.openShiftBtn, label: t.openingCash);
    if (amount == null || !context.mounted) return;
    try {
      await context.read<RetailStore>().openShift(openingCash: amount);
      if (context.mounted) await _snack(context, t.shiftOpened);
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _close(BuildContext context) async {
    final t = AppStrings.of(context.read<RetailStore>().language);
    final amount = await _promptAmount(context, title: t.closeBtn, label: t.colClosing);
    if (amount == null || !context.mounted) return;
    try {
      await context.read<RetailStore>().closeShift(closingCash: amount);
      if (context.mounted) await _snack(context, t.shiftClosed);
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  Future<void> _cashMove(BuildContext context, {required bool isIn}) async {
    final t = AppStrings.of(context.read<RetailStore>().language);
    final amount = await _promptAmount(context, title: isIn ? t.cashInBtn : t.cashOutBtn);
    if (amount == null || amount <= 0 || !context.mounted) return;
    final note = await _promptText(context, title: t.noteOptional, label: t.note);
    if (!context.mounted) return;
    try {
      if (isIn) {
        await context.read<RetailStore>().cashIn(amount: amount, note: note);
      } else {
        await context.read<RetailStore>().cashOut(amount: amount, note: note);
      }
      if (context.mounted) await _snack(context, isIn ? t.cashInRecorded : t.cashOutRecorded);
    } catch (e) {
      if (context.mounted) await _snack(context, e.toString(), error: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final sym = store.currencySymbol;
    final shift = store.activeShift;
    final summary = store.activeShiftSummary;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(title: t.shifts, subtitle: t.shiftsSubtitle),
        const SizedBox(height: 16),
        ShopPanel(
          color: shift != null ? AppColors.accent.withValues(alpha: 0.12) : AppColors.panel,
          child: Row(
            children: [
              Icon(
                shift != null ? Icons.lock_open : Icons.lock_outline,
                color: shift != null ? AppColors.accent : AppColors.muted,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      shift != null ? t.shiftOpen : t.noActiveShift,
                      style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16),
                    ),
                    Text(
                      shift != null
                          ? '${shift.employeeName ?? store.currentEmployee?.name ?? t.staffFallback} · ${_fmtDate(shift.openedAt, t)}'
                          : t.openShiftHint,
                      style: TextStyle(color: AppColors.muted, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (shift == null)
                FilledButton(onPressed: () => _open(context), child: Text(t.openShiftBtn))
              else ...[
                OutlinedButton(onPressed: () => _cashMove(context, isIn: true), child: Text(t.cashInBtn)),
                const SizedBox(width: 8),
                OutlinedButton(onPressed: () => _cashMove(context, isIn: false), child: Text(t.cashOutBtn)),
                const SizedBox(width: 8),
                FilledButton(
                  onPressed: () => _close(context),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.red),
                  child: Text(t.closeBtn),
                ),
              ],
            ],
          ),
        ),
        if (summary != null) ...[
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              StatCard(
                label: t.openingCash,
                value: Money.format(summary.shift.openingCash, symbol: sym),
                color: AppColors.cyan,
                icon: Icons.savings_outlined,
              ),
              StatCard(
                label: t.cashSales,
                value: Money.format(summary.cashSales, symbol: sym),
                color: AppColors.green,
                icon: Icons.point_of_sale,
              ),
              StatCard(
                label: t.cashInOut,
                value: '${Money.format(summary.cashIn, symbol: sym)} / ${Money.format(summary.cashOut, symbol: sym)}',
                color: AppColors.amber,
                icon: Icons.swap_vert,
              ),
              StatCard(
                label: t.expectedCash,
                value: Money.format(summary.expectedCash, symbol: sym),
                color: AppColors.accent,
                icon: Icons.account_balance_wallet_outlined,
              ),
            ],
          ),
          const SizedBox(height: 16),
          ShopPanel(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(t.cashMovements, style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 10),
                if (summary.movements.isEmpty)
                  Text(t.noMovementsYet, style: TextStyle(color: AppColors.muted))
                else
                  ...summary.movements.map((m) {
                    final isIn = m.movementType == 'in';
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Icon(
                            isIn ? Icons.arrow_downward : Icons.arrow_upward,
                            size: 16,
                            color: isIn ? AppColors.green : AppColors.red,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${isIn ? t.movementIn : t.movementOut}${m.note != null && m.note!.isNotEmpty ? ' · ${m.note}' : ''}',
                              style: TextStyle(color: AppColors.text),
                            ),
                          ),
                          Text(
                            Money.format(m.amount, symbol: sym),
                            style: TextStyle(
                              color: isIn ? AppColors.green : AppColors.red,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Text(_fmtDate(m.createdAt, t), style: TextStyle(color: AppColors.muted, fontSize: 11)),
                        ],
                      ),
                    );
                  }),
              ],
            ),
          ),
        ],
        const SizedBox(height: 20),
        ShopPanel(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Text(t.shiftHistoryTitle, style: Theme.of(context).textTheme.titleLarge),
              ),
              if (store.shiftHistory.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(child: Text(t.noShiftsYet, style: TextStyle(color: AppColors.muted))),
                )
              else
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: DataTable(
                    columns: [
                      DataColumn(label: Text(t.colEmployee)),
                      DataColumn(label: Text(t.colOpened)),
                      DataColumn(label: Text(t.colClosed)),
                      DataColumn(label: Text(t.colOpening)),
                      DataColumn(label: Text(t.colClosing)),
                      DataColumn(label: Text(t.colExpected)),
                      DataColumn(label: Text(t.colDiff)),
                      DataColumn(label: Text(t.colStatus)),
                    ],
                    rows: store.shiftHistory.map((s) {
                      return DataRow(
                        cells: [
                          DataCell(Text(s.employeeName ?? '#${s.employeeId}')),
                          DataCell(Text(_fmtDate(s.openedAt, t))),
                          DataCell(Text(s.closedAt == null ? '—' : _fmtDate(s.closedAt, t))),
                          DataCell(Text(Money.format(s.openingCash, symbol: sym))),
                          DataCell(Text(s.closingCash == null ? '—' : Money.format(s.closingCash!, symbol: sym))),
                          DataCell(Text(s.expectedCash == null ? '—' : Money.format(s.expectedCash!, symbol: sym))),
                          DataCell(
                            Text(
                              s.difference == null ? '—' : Money.format(s.difference!, symbol: sym),
                              style: TextStyle(
                                color: (s.difference ?? 0) == 0
                                    ? AppColors.muted
                                    : (s.difference! > 0 ? AppColors.green : AppColors.red),
                              ),
                            ),
                          ),
                          DataCell(
                            StatusBadge(
                              text: t.shiftStatus(s.status),
                              color: s.status == 'open' ? AppColors.accent : AppColors.muted,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Reports
// ─────────────────────────────────────────────────────────────────────────────

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key});

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  String _period = 'monthly';

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _load(_period));
  }

  String _trendLabel(DateTime date) {
    if (_period == 'daily') return DateFormat('d MMM').format(date);
    if (_period == 'weekly') return DateFormat('EEE').format(date);
    return DateFormat('d').format(date);
  }

  Future<void> _load(String period) async {
    setState(() => _period = period);
    final now = DateTime.now();
    final DateTime from;
    if (period == 'daily') {
      from = DateTime(now.year, now.month, now.day);
    } else if (period == 'weekly') {
      final start = now.subtract(Duration(days: now.weekday - 1));
      from = DateTime(start.year, start.month, start.day);
    } else {
      from = DateTime(now.year, now.month, 1);
    }
    await context.read<RetailStore>().loadReport(from: from, to: now);
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final r = store.reportStats;
    final sym = store.currencySymbol;

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(title: t.reports, subtitle: t.reportsSubtitle),
        const SizedBox(height: 14),
        Row(
          children: [
            SoftChip(label: t.periodDaily, selected: _period == 'daily', onTap: () => _load('daily')),
            const SizedBox(width: 8),
            SoftChip(label: t.periodWeekly, selected: _period == 'weekly', onTap: () => _load('weekly')),
            const SizedBox(width: 8),
            SoftChip(label: t.periodMonthly, selected: _period == 'monthly', onTap: () => _load('monthly')),
          ],
        ),
        const SizedBox(height: 20),
        Wrap(
          spacing: 14,
          runSpacing: 14,
          children: [
            StatCard(
              label: t.revenue,
              value: Money.format(r.totalRevenue, symbol: sym),
              color: AppColors.accent,
              icon: Icons.payments_outlined,
            ),
            StatCard(
              label: t.estProfit,
              value: Money.format(r.estimatedProfit, symbol: sym),
              color: AppColors.green,
              icon: Icons.trending_up,
            ),
            StatCard(
              label: t.salesCount,
              value: '${r.numberOfSales}',
              color: AppColors.cyan,
              icon: Icons.receipt_long,
            ),
            StatCard(
              label: t.avgSale,
              value: Money.format(r.averageSale, symbol: sym),
              color: AppColors.amber,
              icon: Icons.analytics_outlined,
            ),
          ],
        ),
        const SizedBox(height: 20),
        ReportChartPanel(
          title: t.salesTrend,
          height: 220,
          child: SalesTrendChart(
            points: r.dailyTrend,
            formatLabel: _trendLabel,
            emptyLabel: t.noSalesInPeriod,
          ),
        ),
        const SizedBox(height: 16),
        ReportChartPanel(
          title: t.revenueVsProfit,
          height: 200,
          child: RevenueProfitChart(
            revenue: r.totalRevenue,
            profit: r.estimatedProfit,
            revenueLabel: t.revenue,
            profitLabel: t.estProfit,
            currencySymbol: sym,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ReportChartPanel(
                title: t.topProducts,
                height: 220,
                child: TopProductsBarChart(
                  products: r.topProducts,
                  emptyLabel: t.noSalesInPeriod,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: ReportChartPanel(
                title: t.paymentBreakdown,
                height: 220,
                child: PaymentDonutChart(
                  payments: r.payments,
                  methodLabel: t.paymentMethod,
                  currencySymbol: sym,
                  emptyLabel: t.noPaymentsYet,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
