# Gera o build de release otimizado (sem mudar funcionalidade nem aparência).
#
#   .\tool\build_release.ps1             # APKs por arquitetura (celular / amigos)
#   .\tool\build_release.ps1 -Universal  # 1 APK que serve em qualquer celular
#   .\tool\build_release.ps1 -Bundle     # App Bundle (.aab) para a Play Store
#
# Os símbolos de depuração (para ler stack traces do build obfuscado) ficam em
# symbols\<versão>\ — fora do app. Guarde essa pasta de cada versão publicada.
param([switch]$Bundle, [switch]$Universal)

$ErrorActionPreference = 'Stop'
Set-Location (Split-Path $PSScriptRoot -Parent)

$versao = (Select-String -Path pubspec.yaml -Pattern '^version:\s*(\S+)').Matches[0].Groups[1].Value
$simbolos = "symbols/$versao"
New-Item -ItemType Directory -Force $simbolos | Out-Null

if ($Universal) {
  flutter build apk --release --obfuscate "--split-debug-info=$simbolos"
  Write-Host 'APK: build\app\outputs\flutter-apk\app-release.apk'
} elseif ($Bundle) {
  flutter build appbundle --release --obfuscate "--split-debug-info=$simbolos"
  Write-Host 'AAB: build\app\outputs\bundle\release\app-release.aab'
} else {
  flutter build apk --release --split-per-abi --obfuscate "--split-debug-info=$simbolos"
  Write-Host 'APKs: build\app\outputs\flutter-apk\ (app-arm64-v8a-release.apk é o da maioria dos celulares)'
}
Write-Host "Símbolos: $simbolos"
