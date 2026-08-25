/**
 * Create / update an activation code in secrets/codes.json
 *
 * node create-code.js --code SHOP-9K2M --customer "Blue Nile" [--expires 2027-08-24] [--email a@b.c] [--max 1]
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { randomBytes } from 'node:crypto';

import { defaultCodesPath, loadCodes, normalizeCode, saveCodes } from './lib/codes.js';
import { todayUtcDate } from './lib/sign.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));

function arg(name, fallback) {
  const i = process.argv.indexOf(`--${name}`);
  if (i >= 0 && process.argv[i + 1]) return process.argv[i + 1];
  return fallback;
}

function genCode() {
  const alphabet = 'ABCDEFGHJKLMNPQRSTUVWXYZ23456789';
  const bytes = randomBytes(8);
  let out = 'SHOP-';
  for (let i = 0; i < 8; i++) {
    out += alphabet[bytes[i] % alphabet.length];
    if (i === 3) out += '-';
  }
  return out;
}

const codesPath = defaultCodesPath(__dirname);
const customer = arg('customer');
if (!customer) {
  console.error('Required: --customer "Shop Name"');
  process.exit(1);
}

const code = normalizeCode(arg('code') || genCode());
const expires = arg('expires') || undefined;
const email = arg('email') || undefined;
const maxActivations = Number(arg('max', '1'));
const notes = arg('notes') || undefined;

const store = fs.existsSync(codesPath) ? loadCodes(codesPath) : { codes: {} };
store.codes[code] = {
  customer,
  ...(email ? { email } : {}),
  ...(expires ? { expires } : {}),
  ...(notes ? { notes } : {}),
  issued: todayUtcDate(),
  maxActivations,
  activations: store.codes[code]?.activations || [],
  disabled: false,
};

saveCodes(codesPath, store);
console.log(`Saved code ${code} → ${codesPath}`);
console.log(`  customer: ${customer}`);
if (expires) console.log(`  expires:  ${expires}`);
console.log(`  maxActivations: ${maxActivations}`);
console.log(`\nGive the shop this code. They enter it in the app (Machine ID is automatic).`);
