# Builds MayleSoft retail for Windows and packages a web-downloadable installer.
# Requires Inno Setup 6 or 7: https://jrsoftware.org/isdl.php
#
# Optional code signing (see tool/CODE_SIGNING.md):
#   $env:MAYLESOFT_SIGN_PFX = "C:\certs\maylesoft.pfx"
#   $env:MAYLESOFT_SIGN_PASSWORD = "..."
#   $env:MAYLESOFT_SIGN_TIMESTAMP = "http://timestamp.digicert.com"  # optional
#   $env:MAYLESOFT_SIGNTOOL = "C:\Path\to\signtool.exe"              # optional

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$flutter = Join-Path (Split-Path -Parent $repoRoot) "flutter\bin\flutter.bat"
if (-not (Test-Path $flutter)) {
    $flutter = "flutter"
}

function Get-PubspecVersion {
    param([string]$PubspecPath)
    $content = Get-Content $PubspecPath -Raw
    if ($content -match 'version:\s*([0-9.]+)\+(\d+)') {
        return @{
            Version = $Matches[1]
            Build = [int]$Matches[2]
        }
    }
    throw "Could not parse version from pubspec.yaml"
}

function Find-SignTool {
    if ($env:MAYLESOFT_SIGNTOOL -and (Test-Path $env:MAYLESOFT_SIGNTOOL)) {
        return $env:MAYLESOFT_SIGNTOOL
    }
    $cmd = Get-Command signtool.exe -ErrorAction SilentlyContinue
    if ($cmd) { return $cmd.Source }

    $sdkRoots = @(
        "${env:ProgramFiles(x86)}\Windows Kits\10\bin",
        "$env:ProgramFiles\Windows Kits\10\bin"
    )
    foreach ($root in $sdkRoots) {
        if (-not (Test-Path $root)) { continue }
        $hit = Get-ChildItem $root -Recurse -Filter signtool.exe -ErrorAction SilentlyContinue |
            Where-Object { $_.FullName -match '\\x64\\' } |
            Sort-Object FullName -Descending |
            Select-Object -First 1
        if ($hit) { return $hit.FullName }
    }
    return $null
}

function Invoke-CodeSign {
    param(
        [Parameter(Mandatory = $true)][string]$Path,
        [string]$Label = $Path
    )
    $pfx = $env:MAYLESOFT_SIGN_PFX
    if (-not $pfx) { return $false }
    if (-not (Test-Path $pfx)) {
        throw "MAYLESOFT_SIGN_PFX not found: $pfx"
    }
    if (-not (Test-Path $Path)) {
        throw "File to sign not found: $Path"
    }

    $signtool = Find-SignTool
    if (-not $signtool) {
        throw "signtool.exe not found. Install Windows SDK or set MAYLESOFT_SIGNTOOL."
    }

    $pass = $env:MAYLESOFT_SIGN_PASSWORD
    $timestamp = if ($env:MAYLESOFT_SIGN_TIMESTAMP) {
        $env:MAYLESOFT_SIGN_TIMESTAMP
    } else {
        "http://timestamp.digicert.com"
    }

    Write-Host "Signing $Label ..." -ForegroundColor Cyan
    $args = @(
        "sign",
        "/f", $pfx,
        "/fd", "SHA256",
        "/td", "SHA256",
        "/tr", $timestamp,
        "/d", "MayleSoft retail",
        "/du", "https://retail.maylesoft.com"
    )
    if ($pass) {
        $args += @("/p", $pass)
    }
    $args += $Path

    & $signtool @args
    if ($LASTEXITCODE -ne 0) {
        throw "SignTool failed for $Path (exit $LASTEXITCODE)."
    }
    return $true
}

function Get-FileSha256 {
    param([string]$Path)
    return (Get-FileHash -Path $Path -Algorithm SHA256).Hash.ToLowerInvariant()
}

Push-Location $repoRoot
try {
    $versionInfo = Get-PubspecVersion (Join-Path $repoRoot "pubspec.yaml")
    $appVersion = $versionInfo.Version
    $appBuild = $versionInfo.Build
    $willSign = [bool]$env:MAYLESOFT_SIGN_PFX

    Write-Host "Building Windows release v$appVersion+$appBuild..." -ForegroundColor Cyan
    if ($willSign) {
        Write-Host "Code signing is ENABLED (MAYLESOFT_SIGN_PFX set)." -ForegroundColor Green
    } else {
        Write-Host "Code signing skipped (set MAYLESOFT_SIGN_PFX to sign). See tool\CODE_SIGNING.md" -ForegroundColor DarkYellow
    }

    & $flutter pub get
    if ($LASTEXITCODE -ne 0) { throw "flutter pub get failed." }
    & $flutter build windows --release
    if ($LASTEXITCODE -ne 0) { throw "Flutter build failed." }

    $releaseDir = Join-Path $repoRoot "build\windows\x64\runner\Release"
    $exe = Join-Path $releaseDir "retail.exe"
    if (-not (Test-Path $exe)) {
        throw "Expected $exe was not found."
    }

    if ($willSign) {
        Invoke-CodeSign -Path $exe -Label "retail.exe" | Out-Null
        Get-ChildItem $releaseDir -Filter "*.dll" | ForEach-Object {
            # Sign Flutter/engine DLLs that ship beside the exe (skip if already catalog-signed).
            try {
                Invoke-CodeSign -Path $_.FullName -Label $_.Name | Out-Null
            } catch {
                Write-Host "  (optional) could not sign $($_.Name): $_" -ForegroundColor DarkYellow
            }
        }
    }

    $dist = Join-Path $repoRoot "dist"
    New-Item -ItemType Directory -Force -Path $dist | Out-Null
    $setupName = "MayleSoftRetail-Setup-$appVersion.exe"
    $downloadUrl = "https://retail.maylesoft.com/$setupName"

    $isccCandidates = @(
        "${env:ProgramFiles(x86)}\Inno Setup 7\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 7\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 7\ISCC.exe",
        "${env:ProgramFiles(x86)}\Inno Setup 6\ISCC.exe",
        "$env:ProgramFiles\Inno Setup 6\ISCC.exe",
        "$env:LOCALAPPDATA\Programs\Inno Setup 6\ISCC.exe"
    )
    $iscc = $isccCandidates | Where-Object { Test-Path $_ } | Select-Object -First 1
    if (-not $iscc) {
        Write-Host ""
        Write-Host "Inno Setup is not installed." -ForegroundColor Yellow
        Write-Host "1. Download: https://jrsoftware.org/isdl.php" -ForegroundColor Yellow
        Write-Host "2. Install Inno Setup 6 or 7" -ForegroundColor Yellow
        Write-Host "3. Re-run: .\tool\build_windows_installer.ps1" -ForegroundColor Yellow
        Write-Host ""
        Write-Host "Release files are ready at:" -ForegroundColor Green
        Write-Host "  $releaseDir" -ForegroundColor Green
        exit 1
    }

    $iss = Join-Path $repoRoot "tool\installer\maylesoft_retail.iss"
    Write-Host "Creating installer with Inno Setup..." -ForegroundColor Cyan
    Write-Host "Using: $iscc" -ForegroundColor DarkGray
    & $iscc "/DMyAppVersion=$appVersion" "/DMyAppBuild=$appBuild" $iss
    if ($LASTEXITCODE -ne 0) { throw "Installer build failed." }

    $setup = Get-ChildItem $dist -Filter "MayleSoftRetail-Setup-*.exe" | Sort-Object LastWriteTime -Descending | Select-Object -First 1
    if (-not $setup) { throw "Installer exe not found in dist/." }

    $signed = $false
    if ($willSign) {
        $signed = Invoke-CodeSign -Path $setup.FullName -Label $setup.Name
    }

    $sha = Get-FileSha256 -Path $setup.FullName
    $manifest = [ordered]@{
        version = $appVersion
        build = $appBuild
        releaseDate = (Get-Date -Format "yyyy-MM-dd")
        downloadUrl = $downloadUrl
        fileName = $setup.Name
        platform = "windows"
        sha256 = $sha
        signed = [bool]$signed
        notes = "MayleSoft retail release $appVersion"
    }
    $manifestPath = Join-Path $dist "latest.json"
    $manifest | ConvertTo-Json -Depth 4 | Set-Content -Path $manifestPath -Encoding UTF8

    Write-Host ""
    Write-Host "Installer ready:" -ForegroundColor Green
    Write-Host "  $($setup.FullName)" -ForegroundColor Green
    Write-Host "Update manifest ready:" -ForegroundColor Green
    Write-Host "  $manifestPath" -ForegroundColor Green
    Write-Host "  sha256: $sha" -ForegroundColor DarkGray
    if ($signed) {
        Write-Host "Signed: yes" -ForegroundColor Green
    } else {
        Write-Host "Signed: no (set MAYLESOFT_SIGN_PFX - see tool\CODE_SIGNING.md)" -ForegroundColor DarkYellow
    }
}
finally {
    Pop-Location
}
