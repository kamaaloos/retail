# Windows code signing (MayleSoft retail)

Signing removes SmartScreen “Unknown publisher” warnings. The build script signs
**only when** certificate environment variables are set — unsigned local builds
still work.

## One-time setup

1. Buy an Authenticode / EV code-signing certificate (e.g. DigiCert, Sectigo, SSL.com).
2. Install it as a `.pfx` (or export from the Windows cert store).
3. Install [Windows SDK](https://developer.microsoft.com/windows/downloads/windows-sdk/) so `signtool.exe` is on PATH
   (or set `MAYLESOFT_SIGNTOOL` to the full path).

## Build a signed installer

In PowerShell (session only — do not commit secrets):

```powershell
$env:MAYLESOFT_SIGN_PFX = "C:\certs\maylesoft.pfx"
$env:MAYLESOFT_SIGN_PASSWORD = "<pfx-password>"
# Optional RFC3161 timestamp (recommended):
$env:MAYLESOFT_SIGN_TIMESTAMP = "http://timestamp.digicert.com"

.\tool\build_windows_installer.ps1
```

The script will:

1. Build Flutter Windows release
2. Sign `retail.exe` (and companion DLLs when present)
3. Build the Inno Setup installer
4. Sign `dist\MayleSoftRetail-Setup-*.exe`
5. Write `dist\latest.json` (version, build, downloadUrl, notes, sha256)

## Publish updates

Upload to `https://retail.maylesoft.com/`:

- `MayleSoftRetail-Setup-<version>.exe`
- `latest.json` (from `dist/` or via `.\tool\prepare_site.ps1`)

The app checks that URL from **Settings → About → Check for updates**.

## Without a certificate

Omit the env vars. Installers build normally but remain unsigned; Windows may
show a SmartScreen warning until you sign.
