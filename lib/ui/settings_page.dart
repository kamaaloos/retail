import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_info.dart';
import '../l10n/app_strings.dart';
import '../licensing/license_document.dart';
import '../providers/retail_store.dart';
import '../services/app_update.dart';
import 'activation_page.dart';
import 'theme.dart';
import 'widgets.dart';
import 'settings_tabs.dart';

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
  String? _storeLogoPath;
  String? _pickedLogoSource;
  bool _clearLogo = false;
  bool _savingLogo = false;
  bool _checkingUpdate = false;

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
    _storeLogoPath = store.storeLogoPath.isEmpty ? null : store.storeLogoPath;
    _pickedLogoSource = null;
    _clearLogo = false;
    setState(() => _ready = true);
  }

  String? get _effectiveLogoPath {
    if (_clearLogo) return null;
    return _pickedLogoSource ?? _storeLogoPath;
  }

  Future<void> _pickLogo() async {
    if (_savingLogo) return;
    final file = await FilePicker.pickFile(type: FileType.image);
    if (file?.path == null || !mounted) return;
    setState(() {
      _pickedLogoSource = file!.path;
      _clearLogo = false;
    });
  }

  void _removeLogo() {
    setState(() {
      _clearLogo = true;
      _pickedLogoSource = null;
    });
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
    final strings = AppStrings.of(context.read<RetailStore>().language);
    setState(() => _savingLogo = true);
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
            pickedStoreLogoSource: _pickedLogoSource,
            clearStoreLogo: _clearLogo,
          );
      if (!mounted) return;
      final store = context.read<RetailStore>();
      setState(() {
        _storeLogoPath = store.storeLogoPath.isEmpty ? null : store.storeLogoPath;
        _pickedLogoSource = null;
        _clearLogo = false;
        _savingLogo = false;
      });
      final saved = AppStrings.of(store.language);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(saved.settingsSaved)),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() => _savingLogo = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(strings.couldNotSave.replaceAll('{error}', '$e')),
          backgroundColor: AppColors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final strings = AppStrings.of(store.language);
    final tabs = strings.settingsTabs;

    if (!_ready) {
      return const Center(child: CircularProgressIndicator(color: AppColors.accent));
    }

    // Keep local language toggle in sync when changed elsewhere.
    if (_language != store.language) {
      _language = store.language;
    }
    if (_darkMode != store.darkMode) {
      _darkMode = store.darkMode;
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
              for (var i = 0; i < tabs.length; i++) ...[
                if (i > 0) const SizedBox(width: 8),
                _SettingsTab(
                  icon: tabs[i].$1,
                  label: tabs[i].$2,
                  selected: _tab == i,
                  onTap: () => setState(() => _tab = i),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 20),
        switch (_tab) {
          0 => _buildGeneral(store, strings),
          1 => const SettingsDiscountsTab(),
          2 => const SettingsPaymentMethodsTab(),
          3 => const SettingsPosDevicesTab(),
          4 => const SettingsPrintersTab(),
          5 => const SettingsBackupTab(),
          6 => const SettingsNetworkTab(),
          _ => _buildPlaceholder(tabs[_tab].$2, strings),
        },
      ],
    );
  }

  Widget _buildGeneral(RetailStore store, AppStrings strings) {
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
                    Text(strings.businessInfo, style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _storeName,
                      decoration: InputDecoration(labelText: strings.storeName),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            decoration: InputDecoration(labelText: strings.phone),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _email,
                            decoration: InputDecoration(labelText: strings.email),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _address,
                      decoration: InputDecoration(labelText: strings.address),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _receiptHeader,
                            decoration: InputDecoration(labelText: strings.receiptHeader),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _receiptFooter,
                            decoration: InputDecoration(labelText: strings.receiptFooter),
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
                            decoration: InputDecoration(labelText: strings.currencyCode),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _currencySymbol,
                            decoration: InputDecoration(labelText: strings.currencySymbol),
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
                            decoration: InputDecoration(labelText: strings.taxName),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _taxRate,
                            decoration: InputDecoration(labelText: strings.taxRate),
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            initialValue: _taxType,
                            decoration: InputDecoration(labelText: strings.taxType),
                            items: [
                              DropdownMenuItem(value: 'exclusive', child: Text(strings.taxExclusive)),
                              DropdownMenuItem(value: 'inclusive', child: Text(strings.taxInclusive)),
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
                          StoreLogoPreview(
                            imagePath: _effectiveLogoPath,
                            size: 72,
                            radius: 12,
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  strings.storeLogo,
                                  style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  strings.storeLogoHint,
                                  style: TextStyle(color: AppColors.muted, fontSize: 12),
                                ),
                                const SizedBox(height: 10),
                                Wrap(
                                  spacing: 8,
                                  runSpacing: 8,
                                  children: [
                                    OutlinedButton.icon(
                                      onPressed: _savingLogo ? null : _pickLogo,
                                      icon: const Icon(Icons.upload, size: 16),
                                      label: Text(strings.uploadLogo),
                                    ),
                                    if (_effectiveLogoPath != null)
                                      TextButton(
                                        onPressed: _savingLogo ? null : _removeLogo,
                                        child: Text(strings.remove),
                                      ),
                                  ],
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
                        _aboutRow(strings.version, AppInfo.versionLabel),
                        const SizedBox(height: 8),
                        _aboutRow(strings.systemName, store.systemName),
                        const SizedBox(height: 8),
                        _aboutRow(strings.licenseStatusLabel, _licenseStatusLabel(store, strings)),
                        if (store.machineId != null) ...[
                          const SizedBox(height: 8),
                          _aboutRow(strings.machineIdLabel, store.machineId!),
                        ],
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute<void>(
                                  builder: (_) => const ActivationPage(allowSkipToShell: true),
                                ),
                              );
                            },
                            icon: const Icon(Icons.vpn_key_outlined, size: 18),
                            label: Text(strings.activateLicenseBtn),
                          ),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: _checkingUpdate ? null : _checkForUpdates,
                            icon: _checkingUpdate
                                ? const SizedBox(
                                    width: 16,
                                    height: 16,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  )
                                : const Icon(Icons.system_update_alt, size: 18),
                            label: Text(strings.checkForUpdates),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          strings.copyrightNotice,
                          style: TextStyle(color: AppColors.muted, fontSize: 12, height: 1.4),
                        ),
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
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.end,
            style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  String _licenseStatusLabel(RetailStore store, AppStrings strings) {
    final s = store.licenseStatus;
    switch (s.kind) {
      case LicenseAccessKind.licensed:
        final name = s.document?.customer;
        final exp = s.document?.expires;
        if (exp != null && exp.isNotEmpty) {
          return strings.licenseLicensedUntil
              .replaceAll('{customer}', name ?? '')
              .replaceAll('{date}', exp);
        }
        return strings.licenseLicensed.replaceAll('{customer}', name ?? '');
      case LicenseAccessKind.trial:
        return strings.licenseTrialDays.replaceAll('{days}', '${s.trialDaysLeft ?? 0}');
      case LicenseAccessKind.blocked:
        return strings.licenseBlocked;
    }
  }

  Future<void> _checkForUpdates() async {
    final strings = AppStrings.of(context.read<RetailStore>().language);
    setState(() => _checkingUpdate = true);
    final result = await AppUpdateService.check();
    if (!mounted) return;
    setState(() => _checkingUpdate = false);

    switch (result.status) {
      case UpdateCheckStatus.upToDate:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(strings.updateUpToDate)),
        );
      case UpdateCheckStatus.unreachable:
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              strings.updateCheckFailed.replaceAll('{error}', result.error ?? ''),
            ),
            backgroundColor: AppColors.red,
          ),
        );
      case UpdateCheckStatus.updateAvailable:
        final remote = result.remote!;
        final download = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            title: Text(strings.updateAvailableTitle),
            content: Text(
              strings.updateAvailableBody
                  .replaceAll('{version}', remote.version)
                  .replaceAll('{build}', '${remote.build}')
                  .replaceAll('{notes}', remote.notes?.trim().isNotEmpty == true ? remote.notes! : '—'),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(strings.cancel)),
              FilledButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.downloadUpdate),
              ),
            ],
          ),
        );
        if (download == true) {
          try {
            await AppUpdateService.openDownload(remote.downloadUrl);
          } catch (e) {
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(strings.updateCheckFailed.replaceAll('{error}', '$e')),
                backgroundColor: AppColors.red,
              ),
            );
          }
        }
    }
  }

  Widget _buildPlaceholder(String title, AppStrings strings) {
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
                strings.comingSoon.replaceAll('{title}', title),
                style: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700, fontSize: 16),
              ),
              const SizedBox(height: 6),
              Text(
                strings.comingSoonBody,
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
