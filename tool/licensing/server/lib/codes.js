import fs from 'node:fs';
import path from 'node:path';

function normalizeCode(code) {
  return String(code || '')
    .trim()
    .toUpperCase()
    .replace(/\s+/g, '');
}

export function defaultCodesPath(rootDir) {
  return (
    process.env.MAYLESOFT_CODES_PATH ||
    path.join(rootDir, '..', 'secrets', 'codes.json')
  );
}

export function loadCodes(codesPath) {
  if (fs.existsSync(codesPath)) {
    const raw = JSON.parse(fs.readFileSync(codesPath, 'utf8'));
    if (!raw.codes || typeof raw.codes !== 'object') {
      throw new Error('codes.json must have a top-level "codes" object');
    }
    return raw;
  }

  // Bootstrap from env (Railway): write once to the volume path, then use the file.
  const fromEnv = process.env.MAYLESOFT_LICENSE_CODES?.trim();
  if (fromEnv) {
    const raw = JSON.parse(fromEnv);
    if (!raw.codes || typeof raw.codes !== 'object') {
      throw new Error('MAYLESOFT_LICENSE_CODES must be JSON with a "codes" object');
    }
    saveCodes(codesPath, raw);
    return raw;
  }

  return { codes: {} };
}

export function saveCodes(codesPath, data) {
  fs.mkdirSync(path.dirname(codesPath), { recursive: true });
  fs.writeFileSync(codesPath, `${JSON.stringify(data, null, 2)}\n`, 'utf8');
}

/**
 * Resolve activation: bind machineId, enforce maxActivations, persist.
 * @returns {{ entry: object, record: object }}
 */
export function activateCode(store, codeRaw, machineId) {
  const code = normalizeCode(codeRaw);
  if (!code) {
    const err = new Error('Activation code required');
    err.status = 400;
    throw err;
  }
  if (!machineId || !String(machineId).trim()) {
    const err = new Error('machineId required');
    err.status = 400;
    throw err;
  }
  const mid = String(machineId).trim();
  const entry = store.codes[code];
  if (!entry) {
    const err = new Error('Invalid or unknown activation code');
    err.status = 404;
    throw err;
  }
  if (entry.disabled) {
    const err = new Error('This activation code has been disabled');
    err.status = 403;
    throw err;
  }

  const max = Number(entry.maxActivations ?? 1);
  if (!Array.isArray(entry.activations)) entry.activations = [];

  const existing = entry.activations.find((a) => a.machineId === mid);
  if (existing) {
    return { entry, record: existing, code, reused: true };
  }

  if (entry.activations.length >= max) {
    const err = new Error(
      `This code is already used on ${entry.activations.length} machine(s) (max ${max})`,
    );
    err.status = 409;
    throw err;
  }

  const record = {
    machineId: mid,
    activatedAt: new Date().toISOString(),
  };
  entry.activations.push(record);
  return { entry, record, code, reused: false };
}

export { normalizeCode };
