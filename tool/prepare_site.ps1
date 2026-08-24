# Prepares the retail.maylesoft.com landing site for upload.
# Output: site/dist/

$ErrorActionPreference = "Stop"

$repoRoot = Split-Path -Parent (Split-Path -Parent $MyInvocation.MyCommand.Path)
$siteRoot = Join-Path $repoRoot "site"
$dist = Join-Path $siteRoot "dist"
$assetsSrc = Join-Path $repoRoot "assets\branding"
$distAssets = Join-Path $dist "assets"

if (Test-Path $dist) {
    Remove-Item $dist -Recurse -Force
}
New-Item -ItemType Directory -Force -Path $distAssets | Out-Null

Copy-Item (Join-Path $siteRoot "index.html") $dist
Copy-Item (Join-Path $siteRoot "css") (Join-Path $dist "css") -Recurse
Copy-Item (Join-Path $siteRoot "js") (Join-Path $dist "js") -Recurse

$brandFiles = @("maylesoft_logo.png", "app_icon_48.png", "app_icon_256.png")
foreach ($file in $brandFiles) {
    $src = Join-Path $assetsSrc $file
    if (Test-Path $src) {
        Copy-Item $src (Join-Path $distAssets $file)
    }
}

$latestJson = Join-Path $repoRoot "dist\latest.json"
if (Test-Path $latestJson) {
    Copy-Item $latestJson (Join-Path $dist "latest.json")
} elseif (Test-Path (Join-Path $siteRoot "latest.json.example")) {
    Copy-Item (Join-Path $siteRoot "latest.json.example") (Join-Path $dist "latest.json")
}

$setup = Get-ChildItem (Join-Path $repoRoot "dist") -Filter "MayleSoftRetail-Setup-*.exe" -ErrorAction SilentlyContinue |
    Sort-Object LastWriteTime -Descending |
    Select-Object -First 1
if ($setup) {
    Copy-Item $setup.FullName (Join-Path $dist $setup.Name)
}

Write-Host "Landing site ready:" -ForegroundColor Green
Write-Host "  $dist" -ForegroundColor Green
