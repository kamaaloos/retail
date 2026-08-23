import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../providers/retail_store.dart';
import 'theme.dart';
import 'widgets.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  int _tab = 0;

  late final TextEditingController _storeName;
  late final TextEditingController _phone;
  late final TextEditingController _email;
  late final TextEditingController _address;
  late final TextEditingController _receiptHeader;
  late final TextEditingController _receiptFooter;
  late final TextEditingController _currencyCode;
  late final TextEditingController _currencySymbol;
  late final TextEditingController _taxName;
  late final TextEditingController _taxRate;

  String _taxType = 'exclusive';
  String _language = 'en_US';
  bool _darkMode = true;
  bool _ready = false;

  static const _tabs = [
    (Icons.tune, 'General'),
    (Icons.percent, 'Discounts'),
    (Icons.payments_outlined, 'Payment Methods'),
    (Icons.devices, 'POS Devices'),
    (Icons.print_outlined, 'Printers'),
    (Icons.backup_outlined, 'Backup & Restore'),
    (Icons.wifi, 'Network'),
  ];

  @override
  void initState() {
    super.initState();
    _storeName = TextEditingController();
    _phone = TextEditingController();
    _email = TextEditingController();
    _address = TextEditingController();
    _receiptHeader = TextEditingController();
    _receiptFooter = TextEditingController();
    _currencyCode = TextEditingController();
    _currencySymbol = TextEditingController();
    _taxName = TextEditingController();
    _taxRate = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _hydrate());
  }

  void _hydrate() {
    final store = context.read<RetailStore>();
    _storeName.text = store.storeName;
    _phone.text = store.phone;
    _email.text = store.email;
    _address.text = store.address;
    _receiptHeader.text = store.receiptHeader;
    _receiptFooter.text = store.receiptFooter;
    _currencyCode.text = store.currencyCode;
    _currencySymbol.text = store.currencySymbol;
    _taxName.text = store.taxName;
    _taxRate.text = store.taxRate.toString();
    _taxType = store.taxType;
    _language = store.language;
    _darkMode = store.darkMode;
    setState(() => _ready = true);
  }

  @override
  void dispose() {
    _storeName.dispose();
    _phone.dispose();
    _email.dispose();
    _address.dispose();
    _receiptHeader.dispose();
    _receiptFooter.dispose();
    _currencyCode.dispose();
    _currencySymbol.dispose();
    _taxName.dispose();
    _taxRate.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    try {
      await context.read<RetailStore>().saveSettings(
            storeName: _storeName.text.trim().isEmpty ? 'Shop X' : _storeName.text.trim(),
            phone: _phone.text.trim(),
            email: _email.text.trim(),
            address: _address.text.trim(),
            receiptHeader: _receiptHeader.text.trim(),
            receiptFooter: _receiptFooter.text.trim(),
            currencyCode: _currencyCode.text.trim().isEmpty ? 'USD' : _currencyCode.text.trim(),
            currencySymbol:
                _currencySymbol.text.trim().isEmpty ? '\$' : _currencySymbol.text.trim(),
            taxName: _taxName.text.trim().isEmpty ? 'Sales Tax' : _taxName.text.trim(),
            taxRate: double.tryParse(_taxRate.text.trim()) ?? 0,
            taxType: _taxType,
            language: _language,
            darkMode: _darkMode,
          );
      if (!mounted) return;
      final strings = AppStrings.of(context.read<RetailStore>().language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(strings.settingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Could not save: $e'), backgroundColor: AppColors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);
    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(28, 20, 28, 28),
      children: [
        PageTitle(title: strings.settings, subtitle: strings.settingsSubtitle),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (var i = 0; i < _tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _SettingsTab(
                  icon: _tabs[i].$1,
                  label: _tabs[i].$2,
                  selected: _tab == i,
                  onTap: () => setState(() => _tab = i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        if (_tab == 0) _buildGeneral(store) else _buildPlaceholder(_tabs[_tab].$2),
      ],
    );
  }

  Widget _buildGeneral(RetailStore store) {
    final strings = AppStrings.of(store.language);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: ShopPanel(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Business Information', style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _storeName,
                      decoration: const InputDecoration(labelText: 'Store Name'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            decoration: const InputDecoration(labelText: 'Phone'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _email,
                            decoration: const InputDecoration(labelText: 'Email'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: const InputDecoration(labelText: 'Address'),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _receiptHeader,
                            decoration: const InputDecoration(labelText: 'Receipt Header'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _receiptFooter,
                            decoration: const InputDecoration(labelText: 'Receipt Footer'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _currencyCode,
                            decoration: const InputDecoration(labelText: 'Currency Code'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _currencySymbol,
                            decoration: const InputDecoration(labelText: 'Currency Symbol'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _taxName,
                            decoration: const InputDecoration(labelText: 'Tax Name'),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _taxRate,
                            decoration: const InputDecoration(labelText: 'Tax Rate %'),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _taxType,
                            decoration: const InputDecoration(labelText: 'Tax Type'),
                            items: const [
                              DropdownMenuItem(value: 'exclusive', child: Text('Exclusive')),
                              DropdownMenuItem(value: 'inclusive', child: Text('Inclusive')),
                            ],
                            onChanged: (v) {
                              if (v != null) setState(() => _taxType = v);
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.card,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: AppColors.line),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 72,
                            height: 72,
                            decoration: BoxDecoration(
                              color: AppColors.panel,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.line),
                            ),
                            child: const Icon(Icons.storefront, color: AppColors.accent, size: 32),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Store Logo',
                                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Square logo recommended (e.g. 400×400). Used for receipts and branding.',
                                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(
                                        content: Text('Logo upload will be available in a later update'),
                                      ),
                                    );
                                  },
                                  icon: const Icon(Icons.upload, size: 16),
                                  label: const Text('Upload Logo'),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                children: [
                  ShopPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.appearance, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 8),
                        Material(
                          type: MaterialType.transparency,
                          child: SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: Text(strings.darkMode, style: TextStyle(color: AppColors.text)),
                            value: _darkMode,
                            activeThumbColor: Colors.white,
                            activeTrackColor: AppColors.accent,
                            onChanged: (v) async {
                              setState(() => _darkMode = v);
                              await context.read<RetailStore>().setDarkMode(v);
                            },
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShopPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.about, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        _aboutRow('Version', 'v${store.appVersion}'),
                        const SizedBox(height: 8),
                        _aboutRow('System name', store.systemName),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  ShopPanel(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(strings.language, style: Theme.of(context).textTheme.titleLarge),
                        const SizedBox(height: 12),
                        DropdownButtonFormField<String>(
                          value: _language,
                          decoration: InputDecoration(labelText: strings.language),
                          items: AppStrings.supported.entries
                              .map((e) => DropdownMenuItem(value: e.key, child: Text(e.value)))
                              .toList(),
                          onChanged: (v) async {
                            if (v == null) return;
                            setState(() => _language = v);
                            await context.read<RetailStore>().setLanguage(v);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 20),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton.icon(
            onPressed: _save,
            icon: const Icon(Icons.save_outlined),
            label: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Text(strings.saveSettings),
            ),
          ),
        ),
      ],
    );
  }

  Widget _aboutRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: TextStyle(color: AppColors.muted)),
        const Spacer(),
        Text(value, style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600)),
      ],
    );
  }

  Widget _buildPlaceholder(String title) {
    return ShopPanel(
      child: SizedBox(
        height: 220,
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.construction, color: AppColors.amber, size: 36),
              const SizedBox(height: 12),
              Text(
                '$title coming soon',
                style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                'This section is reserved for upcoming Shop X configuration options.',
                style: TextStyle(color: AppColors.muted),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SettingsTab extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _SettingsTab({
    required this.icon,
    required this.label,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppColors.accent.withValues(alpha: 0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border(
            bottom: BorderSide(
              color: selected ? AppColors.accent : Colors.transparent,
              width: 2,
            ),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: selected ? AppColors.accent : AppColors.muted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: selected ? AppColors.accent : AppColors.muted,
                fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
