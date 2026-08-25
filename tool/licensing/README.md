# MayleSoft offline licenses

## One-time: create signing keys

```powershell
cd c:\Users\kamaa\dev\retail\retail
dart run tool/licensing/generate_keypair.dart
```

- Updates `lib/licensing/license_public_key.dart` (commit this)
- Writes `tool/licensing/secrets/private_seed.b64` (**never commit**)

## Online activation (recommended for shops)

Shop enters an **activation code** in the app. The app sends **code + Machine ID** to:

`https://retail.maylesoft.com/api/activate`

The server signs a **machine-bound** `.lic` and the app installs it. No copy-paste of Machine ID for normal sales.

### 1. Create a code (MayleSoft)

```powershell
cd tool\licensing\server
node create-code.js --customer "Blue Nile Mart" --email "owner@example.com" --expires 2027-08-24
# or pick the code:
node create-code.js --code SHOP-9K2M-BLUE --customer "Blue Nile Mart" --expires 2027-08-24 --max 1
```

Writes `tool/licensing/secrets/codes.json` (gitignored). Email the **code** to the shop.

### 2. Deploy on Railway (recommended)

The app already posts to `https://retail.maylesoft.com/api/activate`. Point that URL at Railway (proxy), **or** temporarily set `AppInfo.licenseActivateUrl` to your Railway public URL.

#### A. New Railway service (simplest)

1. In Railway → **New Project** / **New Service** → deploy from this GitHub repo.
2. Set **Root Directory** to `tool/licensing/server`.
3. Start command is already `node server.js` (`railway.toml`). Railway sets `PORT` for you.
4. Add a **Volume** mounted at `/data` (so activations survive restarts).
5. Variables → add:

| Variable | Value |
|----------|--------|
| `MAYLESOFT_LICENSE_SEED` | full contents of `tool/licensing/secrets/private_seed.b64` (one line, no quotes) |
| `MAYLESOFT_CODES_PATH` | `/data/codes.json` |
| `MAYLESOFT_LICENSE_CODES` | *(optional bootstrap)* paste entire `codes.json` once; server writes it to the volume on first start |

6. **Settings → Networking → Generate domain** (e.g. `https://maylesoft-license-production.up.railway.app`).
7. Smoke test:

```powershell
Invoke-RestMethod -Method Post `
  -Uri "https://YOUR-RAILWAY-DOMAIN/api/activate" `
  -ContentType "application/json" `
  -Body '{"code":"SHOP-XXXX","machineId":"test-machine-1"}'
```

8. Wire the public site:
   - **Option 1:** Cloudflare / reverse proxy: `retail.maylesoft.com/api/activate` → Railway URL (no app rebuild).
   - **Option 2:** Change `lib/app_info.dart` `licenseActivateUrl` to the Railway URL and ship a new Windows build.

Create more codes locally, then either update `/data/codes.json` on the volume (Railway shell / SFTP) or re-set `MAYLESOFT_LICENSE_CODES` only when the volume file is empty (bootstrap is first-run only).

```powershell
cd tool\licensing\server
node create-code.js --customer "Blue Nile Mart" --expires 2027-08-24
# copy the new entry into /data/codes.json on Railway
```

#### B. Existing Railway backend

If you already run an API on Railway:

1. Either **add a second service** as in (A) — keep license signing isolated (recommended), **or**
2. Mount/copy `tool/licensing/server` routes into that app:
   - `POST /api/activate` with the same JSON body/response
   - same env vars + volume for `codes.json`
3. Do **not** commit `private_seed.b64`; only put it in Railway Variables.

Local run (unchanged):

```powershell
cd tool\licensing\server
# optional: $env:MAYLESOFT_LICENSE_SEED = (Get-Content ..\secrets\private_seed.b64 -Raw).Trim()
node server.js
# listens on http://127.0.0.1:8787  POST /api/activate
```

Vercel `site/api/activate.js` is a fallback without durable activation tracking — prefer Railway + volume.

### 3. Shop flow

1. Open Activation (after trial or from Settings)
2. Enter the code → **Activate with code**
3. Done (Machine ID is sent automatically)

File / paste `.lic` remains available under “Use license file / paste instead”.

---

## Offline issue (manual `.lic` file)

Ask the shop for the **Machine ID** shown on the Activation screen (optional but recommended).

```powershell
dart run tool/licensing/issue_license.dart `
  --customer "Blue Nile Mart" `
  --email "owner@example.com" `
  --expires 2027-08-24 `
  --machine "abc123..." `
  --out "tool/licensing/out/blue_nile.lic"
```

### `--machine` (optional)

| You pass… | Meaning |
|-----------|---------|
| `--machine "<id>"` | **Bound license** — works only on that PC’s Machine ID. |
| *(omit)* | **Portable license** — any computer can activate it. |

**Recommended for sales:** online activation (auto-bind) or offline with `--machine`.

### `--expires` (optional)

| You pass… | Meaning |
|-----------|---------|
| `--expires 2027-08-24` | Valid through that calendar day (inclusive). |
| *(omit)* | Perpetual — never expires. |

Date format is `YYYY-MM-DD` only.

## Cross-check Node vs Dart signatures

```powershell
cd tool\licensing\server
node verify-sign.js > ..\out\node_signed.lic
# then verify with Dart (see test/license_crypto_test.dart) or issue_license tooling
```

## Trial

New installs get **14 days** of full use without a license. After that, selling is blocked until a valid license is installed (online code or `.lic` file).
