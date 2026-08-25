/**
 * Sign a sample payload and print envelope (for cross-check with Dart).
 * Usage: node verify-sign.js
 */
import fs from 'node:fs';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import {
  buildPayload,
  loadSeedFromEnvOrFile,
  signLicense,
  todayUtcDate,
} from './lib/sign.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const seedPath = path.join(__dirname, '..', 'secrets', 'private_seed.b64');
const seed = loadSeedFromEnvOrFile(fs, path, seedPath);

const payload = buildPayload({
  customer: 'SignCheck',
  issued: todayUtcDate(),
  machineId: 'test-machine-id-001',
  notes: 'verify-sign',
});

const license = signLicense(payload, seed);
console.log(JSON.stringify(license, null, 2));
