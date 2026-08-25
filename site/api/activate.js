/**
 * Vercel serverless: POST /api/activate
 *
 * Env:
 *   MAYLESOFT_LICENSE_SEED   base64 Ed25519 private seed (required)
 *   MAYLESOFT_LICENSE_CODES  JSON string of { "codes": { ... } }
 *
 * Prefer tool/licensing/server (file-backed codes.json) for production
 * activation tracking; env codes cannot persist new machine bindings.
 */
import crypto from 'node:crypto';

function privateKeyFromSeed(seedBytes) {
  const seed = Buffer.isBuffer(seedBytes) ? seedBytes : Buffer.from(seedBytes);
  if (seed.length !== 32) throw new Error('Ed25519 seed must be 32 bytes');
  const pkcs8 = Buffer.concat([
    Buffer.from('302e020100300506032b657004220420', 'hex'),
    seed,
  ]);
  return crypto.createPrivateKey({ key: pkcs8, format: 'der', type: 'pkcs8' });
}

function buildPayload({ customer, email, issued, expires, machineId, notes, version = 1 }) {
  const payload = { v: version, customer };
  if (email) payload.email = email;
  payload.issued = issued;
  if (expires) payload.expires = expires;
  if (machineId) payload.machineId = machineId;
  if (notes) payload.notes = notes;
  return payload;
}

function todayUtcDate() {
  return new Date().toISOString().slice(0, 10);
}

function normalizeCode(code) {
  return String(code || '')
    .trim()
    .toUpperCase()
    .replace(/\s+/g, '');
}

function signLicense(payload, seedBytes) {
  const key = privateKeyFromSeed(seedBytes);
  const msg = Buffer.from(JSON.stringify(payload), 'utf8');
  const sig = crypto.sign(null, msg, key);
  return { payload, sig: sig.toString('base64') };
}

function loadCodes() {
  const raw = process.env.MAYLESOFT_LICENSE_CODES;
  if (!raw) {
    const err = new Error('MAYLESOFT_LICENSE_CODES not configured');
    err.status = 500;
    throw err;
  }
  const data = JSON.parse(raw);
  if (!data.codes) {
    const err = new Error('Invalid codes config');
    err.status = 500;
    throw err;
  }
  return data;
}

export default function handler(req, res) {
  res.setHeader('Access-Control-Allow-Origin', '*');
  res.setHeader('Access-Control-Allow-Methods', 'POST, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type');

  if (req.method === 'OPTIONS') {
    res.status(204).end();
    return;
  }
  if (req.method !== 'POST') {
    res.status(405).json({ error: 'POST only' });
    return;
  }

  try {
    const seedB64 = process.env.MAYLESOFT_LICENSE_SEED?.trim();
    if (!seedB64) {
      res.status(500).json({ error: 'MAYLESOFT_LICENSE_SEED not configured' });
      return;
    }
    const seed = Buffer.from(seedB64, 'base64');
    if (seed.length !== 32) {
      res.status(500).json({ error: 'Invalid seed length' });
      return;
    }

    const body = typeof req.body === 'string' ? JSON.parse(req.body || '{}') : req.body || {};
    const code = normalizeCode(body.code);
    const machineId = String(body.machineId || '').trim();
    if (!code || !machineId) {
      res.status(400).json({ error: 'code and machineId required' });
      return;
    }

    const store = loadCodes();
    const entry = store.codes[code];
    if (!entry || entry.disabled) {
      res.status(404).json({ error: 'Invalid or unknown activation code' });
      return;
    }

    const max = Number(entry.maxActivations ?? 1);
    const activations = Array.isArray(entry.activations) ? entry.activations : [];
    const already = activations.some((a) => a.machineId === machineId);
    if (!already && activations.length >= max) {
      res.status(409).json({
        error: `This code is already used on ${activations.length} machine(s) (max ${max})`,
      });
      return;
    }

    const payload = buildPayload({
      customer: entry.customer,
      email: entry.email || undefined,
      issued: entry.issued || todayUtcDate(),
      expires: entry.expires || undefined,
      machineId,
      notes: entry.notes || `code:${code}`,
    });

    const license = signLicense(payload, seed);
    res.status(200).json({ license, reused: already });
  } catch (e) {
    const status = e.status || 500;
    res.status(status).json({ error: e.message || 'Activation failed' });
  }
}
