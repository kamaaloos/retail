/**
 * Ed25519 signing matching Dart `LicenseCrypto` / `LicenseDocument.canonicalBytes`.
 * Private seed: 32-byte base64 (same as tool/licensing/secrets/private_seed.b64).
 */
import crypto from 'node:crypto';

/** PKCS8 DER wrapping a raw 32-byte Ed25519 seed (RFC 8410). */
export function privateKeyFromSeed(seedBytes) {
  if (seedBytes.length !== 32) {
    throw new Error('Ed25519 seed must be 32 bytes');
  }
  const seed = Buffer.isBuffer(seedBytes) ? seedBytes : Buffer.from(seedBytes);
  const pkcs8 = Buffer.concat([
    Buffer.from('302e020100300506032b657004220420', 'hex'),
    seed,
  ]);
  return crypto.createPrivateKey({ key: pkcs8, format: 'der', type: 'pkcs8' });
}

/** Build payload map with stable key order matching Dart. */
export function buildPayload({
  customer,
  email,
  issued,
  expires,
  machineId,
  notes,
  version = 1,
}) {
  const payload = { v: version, customer };
  if (email) payload.email = email;
  payload.issued = issued;
  if (expires) payload.expires = expires;
  if (machineId) payload.machineId = machineId;
  if (notes) payload.notes = notes;
  return payload;
}

/** UTF-8 bytes of compact JSON (Dart jsonEncode). */
export function canonicalBytes(payload) {
  return Buffer.from(JSON.stringify(payload), 'utf8');
}

export function todayUtcDate() {
  return new Date().toISOString().slice(0, 10);
}

/**
 * @param {object} payload
 * @param {Buffer|Uint8Array} seedBytes 32-byte Ed25519 seed
 * @returns {{ payload: object, sig: string }}
 */
export function signLicense(payload, seedBytes) {
  const key = privateKeyFromSeed(seedBytes);
  const msg = canonicalBytes(payload);
  const sig = crypto.sign(null, msg, key);
  return {
    payload,
    sig: sig.toString('base64'),
  };
}

export function loadSeedFromEnvOrFile(fs, _path, seedPath) {
  const env = process.env.MAYLESOFT_LICENSE_SEED?.trim();
  if (env) return Buffer.from(env, 'base64');
  if (seedPath && fs.existsSync(seedPath)) {
    return Buffer.from(fs.readFileSync(seedPath, 'utf8').trim(), 'base64');
  }
  throw new Error(
    'Set MAYLESOFT_LICENSE_SEED (base64) or provide private_seed.b64',
  );
}
