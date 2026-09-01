#Requires -Version 5
# Локальная сборка релиза и инсталлятора RGB Control.
# Запуск из Windows PowerShell:  .\scripts\build_windows.ps1
# Требуется: Flutter (Windows), Visual Studio 2022 (Desktop C++), Inno Setup 6.

$ErrorActionPreference = 'Stop'
$root = Split-Path -Parent $PSScriptRoot
Push-Location $root
try {
    $verLine = Select-String -Path 'app/pubspec.yaml' -Pattern '^version:\s*([0-9]+\.[0-9]+\.[0-9]+)'
    $version = $verLine.Matches[0].Groups[1].Value
    Write-Host "==> RGB Control $version" -ForegroundColor Cyan

    Push-Location 'app'
    try {
        flutter pub get
        flutter config --enable-windows-desktop | Out-Null
        dart run flutter_launcher_icons
        flutter build windows --release
    }
    finally { Pop-Location }

    $iscc = (Get-Command iscc -ErrorAction SilentlyContinue).Source
    if (-not $iscc) { $iscc = Join-Path ${env:ProgramFiles(x86)} 'Inno Setup 6\ISCC.exe' }
    if (-not (Test-Path $iscc)) { throw "Inno Setup (ISCC.exe) не найден. Установите Inno Setup 6." }

    & $iscc "/DMyAppVersion=$version" 'installer\rgb-control.iss'
    Write-Host "==> Готово: dist\RGB-Control-Setup-x64.exe" -ForegroundColor Green
}
finally { Pop-Location }
