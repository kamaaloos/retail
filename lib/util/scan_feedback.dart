import 'package:flutter/services.dart';

/// POS barcode / scan feedback (system beep — no asset pack needed).
abstract final class ScanFeedback {
  static Future<void> success() async {
    await SystemSound.play(SystemSoundType.click);
  }

  static Future<void> error() async {
    await SystemSound.play(SystemSoundType.alert);
  }
}
