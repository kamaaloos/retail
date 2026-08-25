import 'dart:convert';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../l10n/app_strings.dart';
import '../licensing/license_store.dart';
import '../providers/retail_store.dart';
import 'theme.dart';

/// Shown when trial is over (and optionally reachable from Settings).
class ActivationPage extends StatefulWidget {
  final bool allowSkipToShell;

  const ActivationPage({super.key, this.allowSkipToShell = false});

  @override
  State<ActivationPage> createState() => _ActivationPageState();
}

class _ActivationPageState extends State<ActivationPage> {
  final _codeCtrl = TextEditingController();
  final _pasteCtrl = TextEditingController();
  bool _busy = false;
  bool _showAdvanced = false;
  String? _error;

  @override
  void dispose() {
    _codeCtrl.dispose();
    _pasteCtrl.dispose();
    super.dispose();
  }

  Future<void> _activateBytes(List<int> bytes) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<RetailStore>().activateLicenseBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context.read<RetailStore>().language).licenseActivated)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _activateOnline() async {
    final code = _codeCtrl.text.trim();
    if (code.isEmpty) {
      setState(() => _error = 'Enter an activation code');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<RetailStore>().activateWithCode(code);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context.read<RetailStore>().language).licenseActivated)),
      );
    } catch (e) {
      if (mounted) setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _pickFile() async {
    final files = await FilePicker.pickFiles(
      type: FileType.custom,
      allowedExtensions: const ['lic', 'json', 'txt'],
    );
    if (files.isEmpty) return;
    final file = files.first;
    final bytes = await file.readAsBytes();
    if (bytes.isEmpty) {
      setState(() => _error = 'Could not read license file');
      return;
    }
    await _activateBytes(bytes);
  }

  Future<void> _activatePaste() async {
    final text = _pasteCtrl.text.trim();
    if (text.isEmpty) {
      setState(() => _error = 'Paste the license JSON first');
      return;
    }
    await _activateBytes(utf8.encode(text));
  }

  @override
  Widget build(BuildContext context) {
    final store = context.watch<RetailStore>();
    final t = AppStrings.of(store.language);
    final status = store.licenseStatus;
    final machineId = store.machineId ?? '—';

    return Scaffold(
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(t.activateLicenseTitle, style: Theme.of(context).textTheme.headlineSmall),
                const SizedBox(height: 8),
                Text(
                  t.activateLicenseBody.replaceAll('{days}', '${LicenseStore.trialDays}'),
                  style: TextStyle(color: AppColors.muted, height: 1.4),
                ),
                const SizedBox(height: 18),
                Text(t.activationCodeLabel, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                const SizedBox(height: 8),
                TextField(
                  controller: _codeCtrl,
                  enabled: !_busy,
                  textCapitalization: TextCapitalization.characters,
                  decoration: InputDecoration(
                    hintText: t.activationCodeHint,
                    border: const OutlineInputBorder(),
                  ),
                  onSubmitted: (_) {
                    if (!_busy) _activateOnline();
                  },
                ),
                if (_error != null) ...[
                  const SizedBox(height: 10),
                  Text(_error!, style: TextStyle(color: AppColors.red, fontSize: 13)),
                ],
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: _busy ? null : _activateOnline,
                  child: _busy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(t.activateOnlineBtn),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.card,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: AppColors.line),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(t.machineIdLabel, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Expanded(
                            child: SelectableText(
                              machineId,
                              style: TextStyle(
                                color: AppColors.text,
                                fontWeight: FontWeight.w700,
                                fontFamily: 'Consolas',
                              ),
                            ),
                          ),
                          IconButton(
                            tooltip: t.copyMachineId,
                            onPressed: () async {
                              await Clipboard.setData(ClipboardData(text: machineId));
                              if (!context.mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(t.machineIdCopied)),
                              );
                            },
                            icon: const Icon(Icons.copy, size: 18),
                          ),
                        ],
                      ),
                      Text(
                        t.machineIdAutoHint,
                        style: TextStyle(color: AppColors.muted, fontSize: 11, height: 1.3),
                      ),
                      if (status.message != null) ...[
                        const SizedBox(height: 8),
                        Text(status.message!, style: TextStyle(color: AppColors.amber, fontSize: 12)),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                TextButton(
                  onPressed: _busy
                      ? null
                      : () => setState(() => _showAdvanced = !_showAdvanced),
                  child: Text(_showAdvanced ? t.hideFileActivate : t.showFileActivate),
                ),
                if (_showAdvanced) ...[
                  OutlinedButton.icon(
                    onPressed: _busy ? null : _pickFile,
                    icon: const Icon(Icons.upload_file, size: 18),
                    label: Text(t.chooseLicenseFile),
                  ),
                  const SizedBox(height: 12),
                  Text(t.orPasteLicense, style: TextStyle(color: AppColors.muted, fontSize: 12)),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _pasteCtrl,
                    minLines: 4,
                    maxLines: 8,
                    decoration: InputDecoration(
                      hintText: '{"payload":...,"sig":...}',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton(
                    onPressed: _busy ? null : _activatePaste,
                    child: Text(t.activateLicenseBtn),
                  ),
                ],
                if (widget.allowSkipToShell) ...[
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    child: Text(t.cancel),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
