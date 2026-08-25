/**
 * MayleSoft retail — online license activation server.
 *
 * POST /api/activate  { "code", "machineId", "appVersion"? }
 * → { "license": { "payload", "sig" } }
 *
 * Env:
 *   MAYLESOFT_LICENSE_SEED  base64 Ed25519 seed (preferred in production)
 *   MAYLESOFT_CODES_PATH    path to codes.json (default ../secrets/codes.json)
 *   PORT                    default 8787
 */
import fs from 'node:fs';
import http from 'node:http';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

import { activateCode, defaultCodesPath, loadCodes, saveCodes } from './lib/codes.js';
import {
  buildPayload,
  loadSeedFromEnvOrFile,
  signLicense,
  todayUtcDate,
} from './lib/sign.js';

const __dirname = path.dirname(fileURLToPath(import.meta.url));
const rootDir = __dirname;
const seedPath = path.join(rootDir, '..', 'secrets', 'private_seed.b64');
const codesPath = defaultCodesPath(rootDir);
const port = Number(process.env.PORT || 8787);

let seedBytes;
try {
  seedBytes = loadSeedFromEnvOrFile(fs, path, seedPath);
} catch (e) {
  console.error(e.message);
  process.exit(1);
}

function sendJson(res, status, body) {
  const data = JSON.stringify(body);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'POST, OPTIONS',
    'Access-Control-Allow-Headers': 'Content-Type',
  });
  res.end(data);
}

async function readJson(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  const raw = Buffer.concat(chunks).toString('utf8');
  if (!raw.trim()) return {};
  return JSON.parse(raw);
}

async function handleActivate(body) {
  const store = loadCodes(codesPath);
  const { entry, code, reused } = activateCode(store, body.code, body.machineId);
  if (!reused) saveCodes(codesPath, store);

  const payload = buildPayload({
    customer: entry.customer,
    email: entry.email || undefined,
    issued: entry.issued || todayUtcDate(),
    expires: entry.expires || undefined,
    machineId: String(body.machineId).trim(),
    notes: entry.notes || `code:${code}`,
  });

  const license = signLicense(payload, seedBytes);
  return { license, reused: !!reused };
}

const server = http.createServer(async (req, res) => {
  if (req.method === 'OPTIONS') {
    sendJson(res, 204, {});
    return;
  }

  const url = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const isActivate =
    req.method === 'POST' &&
    (url.pathname === '/api/activate' || url.pathname === '/activate');

  if (!isActivate) {
    if (req.method === 'GET' && (url.pathname === '/health' || url.pathname === '/')) {
      sendJson(res, 200, { ok: true, service: 'maylesoft-license' });
      return;
    }
    sendJson(res, 404, { error: 'Not found' });
    return;
  }

  try {
    const body = await readJson(req);
    const result = await handleActivate(body);
    sendJson(res, 200, result);
  } catch (e) {
    const status = e.status || (e instanceof SyntaxError ? 400 : 500);
    const message = e.message || 'Activation failed';
    if (status >= 500) console.error(e);
    sendJson(res, status, { error: message });
  }
});

server.listen(port, '0.0.0.0', () => {
  console.log(`MayleSoft license server on 0.0.0.0:${port}`);
  console.log(`  POST /api/activate`);
  console.log(`  codes: ${codesPath}`);
});
