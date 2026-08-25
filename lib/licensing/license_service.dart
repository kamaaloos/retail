import 'license_document.dart';
import 'license_store.dart';
import 'machine_id.dart';

/// Offline trial + signed-license evaluation.
class LicenseService {
  LicenseService._();
  static final LicenseService instance = LicenseService._();

  LicenseStatus? _cached;
  String? machineId;

  LicenseStatus? get cached => _cached;

  Future<LicenseStatus> refresh({DateTime? now}) async {
    final when = now ?? DateTime.now();
    machineId = await MachineId.getOrCreate();
    final trialStart = await LicenseStore.ensureTrialStarted(now: when);
    final trialEnd = trialStart.add(const Duration(days: LicenseStore.trialDays));
    final trialEndDay = DateTime(trialEnd.year, trialEnd.month, trialEnd.day);
    final today = DateTime(when.year, when.month, when.day);
    final daysLeftRaw = trialEndDay.difference(today).inDays;
    final daysLeft = daysLeftRaw < 0 ? 0 : daysLeftRaw;
    final trialActive = !today.isAfter(trialEndDay);

    LicenseDocument? doc;
    String? licenseError;
    try {
      doc = await LicenseStore.loadInstalledLicense();
    } catch (e) {
      licenseError = '$e';
    }

    if (doc != null) {
      if (doc.isExpiredOn(when)) {
        _cached = _fallback(
          trialActive: trialActive,
          trialEndDay: trialEndDay,
          daysLeft: daysLeft,
          document: doc,
          message: 'License expired on ${doc.expires}',
        );
        return _cached!;
      }
      final bound = doc.machineId;
      if (bound != null && bound.isNotEmpty && bound != machineId) {
        _cached = _fallback(
          trialActive: trialActive,
          trialEndDay: trialEndDay,
          daysLeft: daysLeft,
          document: doc,
          message: 'License is bound to another computer',
        );
        return _cached!;
      }
      _cached = LicenseStatus(
        kind: LicenseAccessKind.licensed,
        document: doc,
        trialEndsAt: trialEndDay,
        trialDaysLeft: daysLeft,
      );
      return _cached!;
    }

    _cached = _fallback(
      trialActive: trialActive,
      trialEndDay: trialEndDay,
      daysLeft: daysLeft,
      message: licenseError != null
          ? 'Installed license is invalid: $licenseError'
          : (trialActive
              ? null
              : 'Trial ended. Activate a license to continue selling.'),
    );
    return _cached!;
  }

  LicenseStatus _fallback({
    required bool trialActive,
    required DateTime trialEndDay,
    required int daysLeft,
    LicenseDocument? document,
    String? message,
  }) {
    if (trialActive) {
      return LicenseStatus(
        kind: LicenseAccessKind.trial,
        document: document,
        trialEndsAt: trialEndDay,
        trialDaysLeft: daysLeft,
        message: message,
      );
    }
    return LicenseStatus(
      kind: LicenseAccessKind.blocked,
      document: document,
      trialEndsAt: trialEndDay,
      trialDaysLeft: 0,
      message: message ?? 'Trial ended. Activate a license to continue selling.',
    );
  }

  Future<LicenseStatus> installLicenseBytes(List<int> bytes, {DateTime? now}) async {
    await LicenseStore.installLicenseBytes(bytes);
    return refresh(now: now);
  }
}
