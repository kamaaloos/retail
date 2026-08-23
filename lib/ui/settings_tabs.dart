import 'dart:io';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../models/product.dart';
import '../models/settings_config.dart';
import '../providers/retail_store.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsDiscountsTab extends StatelessWidget {
  const SettingsDiscountsTab({super.key});

  Future<void> _edit(BuildContext context, {DiscountRule? existing}) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final result = await showDialog<DiscountRule>(
      context: context,
      builder: (_) => _DiscountEditorDialog(
        existing: existing,
        strings: t,
        symbol: store.currencySymbol,
        products: store.productList.where((p) => p.active).toList(),
      ),
    );
    if (result == null || !context.mounted) return;
    if (existing?.id != null) {
      await store.updateDiscount(result);
    } else {
      await store.addDiscount(result);
    }
  }

  Future<void> _delete(BuildContext context, DiscountRule rule) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deleteDiscountConfirm.replaceAll('{name}', rule.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await store.deleteDiscount(rule.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabDiscounts, subtitle: t.discountsSubtitle),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(t.addDiscount),
          ),
        ),
        const SizedBox(height: 12),
        ShopPanel(
          child: store.discountRules.isEmpty
              ? _EmptyState(message: t.noDiscountsYet)
              : Column(
                  children: [
                    for (final rule in store.discountRules) ...[
                      _ConfigListTile(
                        title: rule.name,
                        subtitle: [
                          rule.discountType == 'fixed'
                              ? t.discountFixedSummary.replaceAll(
                                  '{value}',
                                  '${store.currencySymbol}${rule.value.toStringAsFixed(2)}',
                                )
                              : rule.summary(
                                  percentLabel: t.discountPercentSummary,
                                  fixedLabel: t.discountFixedSummary,
                                ),
                          rule.scopeLabel(
                            allProducts: t.discountScopeAll,
                            selectedProducts: t.discountScopeProducts,
                            productCount: t.discountProductCount,
                          ),
                          rule.periodLabel(
                            always: t.discountAlways,
                            fromTo: t.discountFromTo,
                            fromOnly: t.discountFromOnly,
                            untilOnly: t.discountUntilOnly,
                            formatDate: (d) => t.formatDate(d, pattern: 'd MMM yyyy'),
                          ),
                        ].join(' · '),
                        trailing: rule.active ? t.active : t.inactive,
                        onEdit: () => _edit(context, existing: rule),
                        onDelete: () => _delete(context, rule),
                      ),
                      if (rule != store.discountRules.last) Divider(height: 1, color: AppColors.line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class SettingsPaymentMethodsTab extends StatelessWidget {
  const SettingsPaymentMethodsTab({super.key});

  Future<void> _edit(BuildContext context, {PaymentMethodConfig? existing}) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final result = await showDialog<PaymentMethodConfig>(
      context: context,
      builder: (_) => _PaymentMethodEditorDialog(existing: existing, strings: t),
    );
    if (result == null || !context.mounted) return;
    if (existing?.id != null) {
      await store.updatePaymentMethod(result);
    } else {
      await store.addPaymentMethod(result);
    }
  }

  Future<void> _toggle(BuildContext context, PaymentMethodConfig method, bool enabled) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    if (!enabled && store.enabledPaymentMethods.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.atLeastOnePaymentMethod)),
      );
      return;
    }
    await store.updatePaymentMethod(method.copyWith(enabled: enabled));
  }

  Future<void> _delete(BuildContext context, PaymentMethodConfig method) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    if (store.paymentMethods.length <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.atLeastOnePaymentMethod)),
      );
      return;
    }
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deletePaymentMethodConfirm.replaceAll('{name}', method.label)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await store.deletePaymentMethod(method.id!);
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabPaymentMethods, subtitle: t.paymentMethodsSubtitle),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(t.addPaymentMethod),
          ),
        ),
        const SizedBox(height: 12),
        ShopPanel(
          child: store.paymentMethods.isEmpty
              ? _EmptyState(message: t.noPaymentMethodsYet)
              : Column(
                  children: [
                    for (final method in store.paymentMethods) ...[
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(method.label, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                                  const SizedBox(height: 4),
                                  Text(method.code, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                                ],
                              ),
                            ),
                            Material(
                              type: MaterialType.transparency,
                              child: Switch(
                                value: method.enabled,
                                activeThumbColor: Colors.white,
                                activeTrackColor: AppColors.accent,
                                onChanged: (v) => _toggle(context, method, v),
                              ),
                            ),
                            IconButton(
                              icon: Icon(Icons.edit_outlined, color: AppColors.muted, size: 20),
                              onPressed: () => _edit(context, existing: method),
                            ),
                            IconButton(
                              icon: Icon(Icons.delete_outline, color: AppColors.red, size: 20),
                              onPressed: () => _delete(context, method),
                            ),
                          ],
                        ),
                      ),
                      if (method != store.paymentMethods.last) Divider(height: 1, color: AppColors.line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class SettingsPosDevicesTab extends StatelessWidget {
  const SettingsPosDevicesTab({super.key});

  Future<void> _edit(BuildContext context, {PosDevice? existing}) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final result = await showDialog<PosDevice>(
      context: context,
      builder: (_) => _PosDeviceEditorDialog(existing: existing, strings: t),
    );
    if (result == null || !context.mounted) return;
    if (existing?.id != null) {
      await store.updatePosDevice(result);
    } else {
      await store.addPosDevice(result);
    }
  }

  Future<void> _delete(BuildContext context, PosDevice device) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deletePosDeviceConfirm.replaceAll('{name}', device.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await store.deletePosDevice(device.id!);
    }
  }

  String _deviceTypeLabel(AppStrings t, String type) {
    switch (type) {
      case 'tablet':
        return t.deviceTypeTablet;
      case 'scanner':
        return t.deviceTypeScanner;
      default:
        return t.deviceTypeTerminal;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabPosDevices, subtitle: t.posDevicesSubtitle),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(t.addPosDevice),
          ),
        ),
        const SizedBox(height: 12),
        ShopPanel(
          child: store.posDevices.isEmpty
              ? _EmptyState(message: t.noPosDevicesYet)
              : Column(
                  children: [
                    for (final device in store.posDevices) ...[
                      _ConfigListTile(
                        title: device.name,
                        subtitle: [
                          _deviceTypeLabel(t, device.deviceType),
                          if (device.identifier.isNotEmpty) device.identifier,
                        ].join(' · '),
                        trailing: device.active ? t.active : t.inactive,
                        onEdit: () => _edit(context, existing: device),
                        onDelete: () => _delete(context, device),
                      ),
                      if (device != store.posDevices.last) Divider(height: 1, color: AppColors.line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class SettingsPrintersTab extends StatelessWidget {
  const SettingsPrintersTab({super.key});

  Future<void> _edit(BuildContext context, {PrinterConfig? existing}) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final result = await showDialog<PrinterConfig>(
      context: context,
      builder: (_) => _PrinterEditorDialog(existing: existing, strings: t),
    );
    if (result == null || !context.mounted) return;
    if (existing?.id != null) {
      await store.updatePrinter(result);
    } else {
      await store.addPrinter(result);
    }
  }

  Future<void> _delete(BuildContext context, PrinterConfig printer) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.delete),
        content: Text(t.deletePrinterConfirm.replaceAll('{name}', printer.name)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.delete)),
        ],
      ),
    );
    if (ok == true && context.mounted) {
      await store.deletePrinter(printer.id!);
    }
  }

  String _printerTypeLabel(AppStrings t, String type) =>
      type == 'label' ? t.printerTypeLabel : t.printerTypeReceipt;

  String _connectionLabel(AppStrings t, String connection) {
    switch (connection) {
      case 'network':
        return t.connectionNetwork;
      case 'bluetooth':
        return t.connectionBluetooth;
      default:
        return t.connectionUsb;
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabPrinters, subtitle: t.printersSubtitle),
        const SizedBox(height: 16),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: () => _edit(context),
            icon: const Icon(Icons.add),
            label: Text(t.addPrinter),
          ),
        ),
        const SizedBox(height: 12),
        ShopPanel(
          child: store.printers.isEmpty
              ? _EmptyState(message: t.noPrintersYet)
              : Column(
                  children: [
                    for (final printer in store.printers) ...[
                      _ConfigListTile(
                        title: printer.name,
                        subtitle: [
                          _printerTypeLabel(t, printer.printerType),
                          _connectionLabel(t, printer.connection),
                          if (printer.address.isNotEmpty) printer.address,
                          '${printer.paperWidth}mm',
                        ].join(' · '),
                        trailing: printer.isDefault ? t.defaultPrinter : (printer.active ? t.active : t.inactive),
                        onEdit: () => _edit(context, existing: printer),
                        onDelete: () => _delete(context, printer),
                      ),
                      if (printer != store.printers.last) Divider(height: 1, color: AppColors.line),
                    ],
                  ],
                ),
        ),
      ],
    );
  }
}

class SettingsBackupTab extends StatelessWidget {
  const SettingsBackupTab({super.key});

  Future<void> _export(BuildContext context) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    try {
      final bytes = await File(store.databasePath).readAsBytes();
      final uri = await FilePicker.saveFile(
        dialogTitle: t.exportBackup,
        fileName: store.suggestedBackupName(),
        bytes: Uint8List.fromList(bytes),
        type: FileType.custom,
        allowedExtensions: ['db'],
      );
      if (uri == null || !context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.backupExported.replaceAll('{path}', uri.path))),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.couldNotSave.replaceAll('{error}', '$e')), backgroundColor: AppColors.red),
      );
    }
  }

  Future<void> _import(BuildContext context) async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(t.backupRestoreConfirm),
        content: Text(t.backupRestoreWarning),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(t.cancel)),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(t.importBackup)),
        ],
      ),
    );
    if (ok != true || !context.mounted) return;

    final picked = await FilePicker.pickFile(
      type: FileType.custom,
      allowedExtensions: ['db'],
      dialogTitle: t.importBackup,
    );
    if (picked?.path == null || !context.mounted) return;

    try {
      await store.restoreBackup(picked!.path!);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.backupRestored)),
      );
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.couldNotSave.replaceAll('{error}', '$e')), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabBackup, subtitle: t.backupSubtitle),
        const SizedBox(height: 16),
        ShopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                t.backupLocation.replaceAll('{path}', store.databaseDirectory),
                style: TextStyle(color: AppColors.muted, fontSize: 13),
              ),
              Text(
                t.backupRestoreWarning,
                style: TextStyle(color: AppColors.muted, fontSize: 13, height: 1.4),
              ),
              const SizedBox(height: 20),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  FilledButton.icon(
                    onPressed: () => _export(context),
                    icon: const Icon(Icons.upload_outlined),
                    label: Text(t.exportBackup),
                  ),
                  OutlinedButton.icon(
                    onPressed: () => _import(context),
                    icon: const Icon(Icons.download_outlined),
                    label: Text(t.importBackup),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class SettingsNetworkTab extends StatefulWidget {
  const SettingsNetworkTab({super.key});

  @override
  State<SettingsNetworkTab> createState() => _SettingsNetworkTabState();
}

class _SettingsNetworkTabState extends State<SettingsNetworkTab> {
  late bool _enabled;
  late final TextEditingController _serverUrl;
  late final TextEditingController _terminalName;
  late final TextEditingController _syncInterval;
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    _serverUrl = TextEditingController();
    _terminalName = TextEditingController();
    _syncInterval = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    final settings = context.read<RetailStore>().networkSettings;
    _enabled = settings.enabled;
    _serverUrl.text = settings.serverUrl;
    _terminalName.text = settings.terminalName;
    _syncInterval.text = settings.syncIntervalMinutes.toString();
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _serverUrl.dispose();
    _terminalName.dispose();
    _syncInterval.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final store = context.read<RetailStore>();
    final t = AppStrings.of(store.language);
    final url = _serverUrl.text.trim();
    if (_enabled && url.isNotEmpty && !url.startsWith('http://') && !url.startsWith('https://')) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(t.invalidUrl), backgroundColor: AppColors.red),
      );
      return;
    }
    await store.saveNetworkSettings(
      NetworkSettings(
        enabled: _enabled,
        serverUrl: url,
        terminalName: _terminalName.text.trim(),
        syncIntervalMinutes: int.tryParse(_syncInterval.text.trim()) ?? 60,
      ),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(t.networkSaved)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final t = AppStrings.of(context.watch<RetailStore>().language);
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        PageTitle(title: t.tabNetwork, subtitle: t.networkSubtitle),
        const SizedBox(height: 16),
        ShopPanel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.networkEnabled, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  subtitle: Text(t.networkEnabledHint, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  value: _enabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accent,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _serverUrl,
                decoration: InputDecoration(labelText: t.serverUrl),
                enabled: _enabled,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _terminalName,
                decoration: InputDecoration(labelText: t.terminalName),
                enabled: _enabled,
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _syncInterval,
                decoration: InputDecoration(
                  labelText: t.syncInterval,
                  helperText: t.syncIntervalHint,
                  suffixText: t.minutes,
                ),
                keyboardType: TextInputType.number,
                enabled: _enabled,
              ),
              const SizedBox(height: 20),
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: _save,
                  icon: const Icon(Icons.save_outlined),
                  label: Text(t.saveSettings),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _EmptyState extends StatelessWidget {
  final String message;

  const _EmptyState({required this.message});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: Center(
        child: Text(message, style: TextStyle(color: AppColors.muted)),
      ),
    );
  }
}

class _ConfigListTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final String trailing;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _ConfigListTile({
    required this.title,
    required this.subtitle,
    required this.trailing,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700)),
                const SizedBox(height: 4),
                Text(subtitle, style: TextStyle(color: AppColors.muted, fontSize: 12)),
              ],
            ),
          ),
          Text(trailing, style: TextStyle(color: AppColors.muted, fontSize: 12)),
          IconButton(
            icon: Icon(Icons.edit_outlined, color: AppColors.muted, size: 20),
            onPressed: onEdit,
          ),
          IconButton(
            icon: Icon(Icons.delete_outline, color: AppColors.red, size: 20),
            onPressed: onDelete,
          ),
        ],
      ),
    );
  }
}

extension on PaymentMethodConfig {
  PaymentMethodConfig copyWith({bool? enabled}) => PaymentMethodConfig(
        id: id,
        code: code,
        label: label,
        enabled: enabled ?? this.enabled,
        sortOrder: sortOrder,
      );
}

class _DiscountEditorDialog extends StatefulWidget {
  final DiscountRule? existing;
  final AppStrings strings;
  final String symbol;
  final List<Product> products;

  const _DiscountEditorDialog({
    this.existing,
    required this.strings,
    required this.symbol,
    required this.products,
  });

  @override
  State<_DiscountEditorDialog> createState() => _DiscountEditorDialogState();
}

class _DiscountEditorDialogState extends State<_DiscountEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _value;
  late final TextEditingController _minPurchase;
  late String _type;
  late String _scope;
  late bool _active;
  late Set<int> _selectedProductIds;
  DateTime? _startDate;
  DateTime? _endDate;
  String? _productError;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _value = TextEditingController(text: (widget.existing?.value ?? 0).toString());
    _minPurchase = TextEditingController(text: (widget.existing?.minPurchase ?? 0).toString());
    _type = widget.existing?.discountType ?? 'percent';
    _scope = widget.existing?.scope ?? 'all';
    _active = widget.existing?.active ?? true;
    _selectedProductIds = {...?widget.existing?.productIds};
    _startDate = widget.existing?.startDate;
    _endDate = widget.existing?.endDate;
  }

  @override
  void dispose() {
    _name.dispose();
    _value.dispose();
    _minPurchase.dispose();
    super.dispose();
  }

  Future<void> _pickDate({required bool start}) async {
    final initial = start ? (_startDate ?? DateTime.now()) : (_endDate ?? _startDate ?? DateTime.now());
    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked == null) return;
    setState(() {
      if (start) {
        _startDate = picked;
        if (_endDate != null && _endDate!.isBefore(picked)) _endDate = picked;
      } else {
        _endDate = picked;
        if (_startDate != null && _startDate!.isAfter(picked)) _startDate = picked;
      }
    });
  }

  String _fmtDate(DateTime? date) {
    if (date == null) return widget.strings.none;
    return widget.strings.formatDate(date, pattern: 'd MMM yyyy');
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return AlertDialog(
      title: Text(widget.existing == null ? t.addDiscount : t.editDiscount),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 480,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: t.discountName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.nameRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(labelText: t.discountType),
                  items: [
                    DropdownMenuItem(value: 'percent', child: Text(t.discountPercent)),
                    DropdownMenuItem(value: 'fixed', child: Text(t.discountFixed)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'percent'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _value,
                  decoration: InputDecoration(
                    labelText: t.discountValue,
                    suffixText: _type == 'percent' ? '%' : widget.symbol,
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _minPurchase,
                  decoration: InputDecoration(labelText: t.minPurchase, suffixText: widget.symbol),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _scope,
                  decoration: InputDecoration(labelText: t.discountScope),
                  items: [
                    DropdownMenuItem(value: 'all', child: Text(t.discountScopeAll)),
                    DropdownMenuItem(value: 'products', child: Text(t.discountScopeProducts)),
                  ],
                  onChanged: (v) => setState(() => _scope = v ?? 'all'),
                ),
                if (_scope == 'products') ...[
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: Text(t.discountSelectProducts, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
                  ),
                  const SizedBox(height: 8),
                  if (widget.products.isEmpty)
                    Text(t.noProductsYet, style: TextStyle(color: AppColors.muted, fontSize: 12))
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: widget.products.map((product) {
                        final id = product.id;
                        if (id == null) return const SizedBox.shrink();
                        final selected = _selectedProductIds.contains(id);
                        return FilterChip(
                          label: Text(product.name),
                          selected: selected,
                          onSelected: (v) {
                            setState(() {
                              _productError = null;
                              if (v) {
                                _selectedProductIds.add(id);
                              } else {
                                _selectedProductIds.remove(id);
                              }
                            });
                          },
                        );
                      }).toList(),
                    ),
                  if (_productError != null) ...[
                    const SizedBox(height: 6),
                    Text(_productError!, style: TextStyle(color: AppColors.red, fontSize: 12)),
                  ],
                ],
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(start: true),
                        child: Text('${t.discountStartDate}: ${_fmtDate(_startDate)}'),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: () => _pickDate(start: false),
                        child: Text('${t.discountEndDate}: ${_fmtDate(_endDate)}'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => setState(() {
                      _startDate = null;
                      _endDate = null;
                    }),
                    child: Text(t.discountAlways),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.active),
                    value: _active,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accent,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            if (_scope == 'products' && _selectedProductIds.isEmpty) {
              setState(() => _productError = t.discountProductsRequired);
              return;
            }
            Navigator.pop(
              context,
              DiscountRule(
                id: widget.existing?.id,
                name: _name.text.trim(),
                discountType: _type,
                value: double.tryParse(_value.text.trim()) ?? 0,
                minPurchase: double.tryParse(_minPurchase.text.trim()) ?? 0,
                active: _active,
                scope: _scope,
                startDate: _startDate,
                endDate: _endDate,
                productIds: _selectedProductIds.toList()..sort(),
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}

class _PaymentMethodEditorDialog extends StatefulWidget {
  final PaymentMethodConfig? existing;
  final AppStrings strings;

  const _PaymentMethodEditorDialog({this.existing, required this.strings});

  @override
  State<_PaymentMethodEditorDialog> createState() => _PaymentMethodEditorDialogState();
}

class _PaymentMethodEditorDialogState extends State<_PaymentMethodEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _code;
  late final TextEditingController _label;
  late bool _enabled;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.existing?.code ?? '');
    _label = TextEditingController(text: widget.existing?.label ?? '');
    _enabled = widget.existing?.enabled ?? true;
  }

  @override
  void dispose() {
    _code.dispose();
    _label.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return AlertDialog(
      title: Text(widget.existing == null ? t.addPaymentMethod : t.editPaymentMethod),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 380,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _code,
                decoration: InputDecoration(labelText: t.methodCode),
                enabled: widget.existing == null,
                validator: (v) => (v == null || v.trim().isEmpty) ? t.nameRequired : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _label,
                decoration: InputDecoration(labelText: t.methodLabel),
                validator: (v) => (v == null || v.trim().isEmpty) ? t.nameRequired : null,
              ),
              const SizedBox(height: 8),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.enabled),
                  value: _enabled,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accent,
                  onChanged: (v) => setState(() => _enabled = v),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              PaymentMethodConfig(
                id: widget.existing?.id,
                code: _code.text.trim().toLowerCase(),
                label: _label.text.trim(),
                enabled: _enabled,
                sortOrder: widget.existing?.sortOrder ?? 99,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}

class _PosDeviceEditorDialog extends StatefulWidget {
  final PosDevice? existing;
  final AppStrings strings;

  const _PosDeviceEditorDialog({this.existing, required this.strings});

  @override
  State<_PosDeviceEditorDialog> createState() => _PosDeviceEditorDialogState();
}

class _PosDeviceEditorDialogState extends State<_PosDeviceEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _identifier;
  late final TextEditingController _notes;
  late String _type;
  late bool _active;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _identifier = TextEditingController(text: widget.existing?.identifier ?? '');
    _notes = TextEditingController(text: widget.existing?.notes ?? '');
    _type = widget.existing?.deviceType ?? 'terminal';
    _active = widget.existing?.active ?? true;
  }

  @override
  void dispose() {
    _name.dispose();
    _identifier.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return AlertDialog(
      title: Text(widget.existing == null ? t.addPosDevice : t.editPosDevice),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _name,
                decoration: InputDecoration(labelText: t.deviceName),
                validator: (v) => (v == null || v.trim().isEmpty) ? t.nameRequired : null,
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                value: _type,
                decoration: InputDecoration(labelText: t.deviceType),
                items: [
                  DropdownMenuItem(value: 'terminal', child: Text(t.deviceTypeTerminal)),
                  DropdownMenuItem(value: 'tablet', child: Text(t.deviceTypeTablet)),
                  DropdownMenuItem(value: 'scanner', child: Text(t.deviceTypeScanner)),
                ],
                onChanged: (v) => setState(() => _type = v ?? 'terminal'),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _identifier,
                decoration: InputDecoration(labelText: t.deviceIdentifier),
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _notes,
                decoration: InputDecoration(labelText: t.deviceNotes),
                maxLines: 2,
              ),
              const SizedBox(height: 8),
              Material(
                type: MaterialType.transparency,
                child: SwitchListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(t.active),
                  value: _active,
                  activeThumbColor: Colors.white,
                  activeTrackColor: AppColors.accent,
                  onChanged: (v) => setState(() => _active = v),
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              PosDevice(
                id: widget.existing?.id,
                name: _name.text.trim(),
                deviceType: _type,
                identifier: _identifier.text.trim(),
                notes: _notes.text.trim(),
                active: _active,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}

class _PrinterEditorDialog extends StatefulWidget {
  final PrinterConfig? existing;
  final AppStrings strings;

  const _PrinterEditorDialog({this.existing, required this.strings});

  @override
  State<_PrinterEditorDialog> createState() => _PrinterEditorDialogState();
}

class _PrinterEditorDialogState extends State<_PrinterEditorDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _address;
  late final TextEditingController _paperWidth;
  late String _type;
  late String _connection;
  late bool _active;
  late bool _isDefault;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController(text: widget.existing?.name ?? '');
    _address = TextEditingController(text: widget.existing?.address ?? '');
    _paperWidth = TextEditingController(text: (widget.existing?.paperWidth ?? 80).toString());
    _type = widget.existing?.printerType ?? 'receipt';
    _connection = widget.existing?.connection ?? 'usb';
    _active = widget.existing?.active ?? true;
    _isDefault = widget.existing?.isDefault ?? false;
  }

  @override
  void dispose() {
    _name.dispose();
    _address.dispose();
    _paperWidth.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = widget.strings;
    return AlertDialog(
      title: Text(widget.existing == null ? t.addPrinter : t.editPrinter),
      content: Form(
        key: _formKey,
        child: SizedBox(
          width: 420,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _name,
                  decoration: InputDecoration(labelText: t.printerName),
                  validator: (v) => (v == null || v.trim().isEmpty) ? t.nameRequired : null,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _type,
                  decoration: InputDecoration(labelText: t.printerType),
                  items: [
                    DropdownMenuItem(value: 'receipt', child: Text(t.printerTypeReceipt)),
                    DropdownMenuItem(value: 'label', child: Text(t.printerTypeLabel)),
                  ],
                  onChanged: (v) => setState(() => _type = v ?? 'receipt'),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _connection,
                  decoration: InputDecoration(labelText: t.printerConnection),
                  items: [
                    DropdownMenuItem(value: 'usb', child: Text(t.connectionUsb)),
                    DropdownMenuItem(value: 'network', child: Text(t.connectionNetwork)),
                    DropdownMenuItem(value: 'bluetooth', child: Text(t.connectionBluetooth)),
                  ],
                  onChanged: (v) => setState(() => _connection = v ?? 'usb'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _address,
                  decoration: InputDecoration(labelText: t.printerAddress),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _paperWidth,
                  decoration: InputDecoration(labelText: t.paperWidth),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 8),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.defaultPrinter),
                    value: _isDefault,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accent,
                    onChanged: (v) => setState(() => _isDefault = v),
                  ),
                ),
                Material(
                  type: MaterialType.transparency,
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text(t.active),
                    value: _active,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accent,
                    onChanged: (v) => setState(() => _active = v),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(onPressed: () => Navigator.pop(context), child: Text(t.cancel)),
        FilledButton(
          onPressed: () {
            if (!_formKey.currentState!.validate()) return;
            Navigator.pop(
              context,
              PrinterConfig(
                id: widget.existing?.id,
                name: _name.text.trim(),
                printerType: _type,
                connection: _connection,
                address: _address.text.trim(),
                paperWidth: int.tryParse(_paperWidth.text.trim()) ?? 80,
                isDefault: _isDefault,
                active: _active,
              ),
            );
          },
          child: Text(t.save),
        ),
      ],
    );
  }
}
