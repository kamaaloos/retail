/// Ed25519 public key embedded in the app (safe to ship).
///
/// Private seed lives only in `tool/licensing/secrets/` (gitignored).
/// Regenerate with: `dart run tool/licensing/generate_keypair.dart`
abstract final class LicensePublicKey {
  static const String ed25519PublicKeyBase64 =
      'oRlXdLEwg1HuDW4Y++8tKZqzbEtjJ98sjqLJ63uTYQA=';
}
