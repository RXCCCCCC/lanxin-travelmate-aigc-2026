$ErrorActionPreference = 'Stop'

if (-not $env:ANDROID_SDK_ROOT -and -not $env:ANDROID_HOME -and (Test-Path 'G:\develop\Android\Sdk')) {
  $env:ANDROID_SDK_ROOT = 'G:\develop\Android\Sdk'
  $env:ANDROID_HOME = 'G:\develop\Android\Sdk'
}
if (-not $env:ANDROID_SDK_ROOT -and $env:ANDROID_HOME) {
  $env:ANDROID_SDK_ROOT = $env:ANDROID_HOME
}
if (-not $env:ANDROID_HOME -and $env:ANDROID_SDK_ROOT) {
  $env:ANDROID_HOME = $env:ANDROID_SDK_ROOT
}

if (-not $env:ANDROID_SDK_ROOT) {
  throw 'ANDROID_SDK_ROOT or ANDROID_HOME must be set before starting the emulator.'
}

$sdkRoot = $env:ANDROID_SDK_ROOT
$avdName = 'Lanxin_API35'
$systemImage = 'system-images;android-35;google_apis;x86_64'
$deviceProfile = 'pixel_7'
$avdManager = Join-Path $sdkRoot 'cmdline-tools\latest\bin\avdmanager.bat'
$emulatorExe = Join-Path $sdkRoot 'emulator\emulator.exe'
$systemImageDir = Join-Path $sdkRoot 'system-images\android-35\google_apis\x86_64'
$sourceProps = Join-Path $systemImageDir 'source.properties'
$avdDir = Join-Path $env:USERPROFILE ".android\avd\$avdName.avd"

if (-not (Test-Path $sourceProps)) {
  Write-Host "System image is not installed yet: $systemImage"
  Write-Host "Install it first with:"
  Write-Host "  $sdkRoot\cmdline-tools\latest\bin\sdkmanager.bat `"$systemImage`""
  exit 1
}

if (-not (Test-Path $avdDir)) {
  & $avdManager create avd -n $avdName -k $systemImage -d $deviceProfile | Out-Host
}

Start-Process -FilePath $emulatorExe -ArgumentList "-avd $avdName" -WindowStyle Normal
Write-Host "Emulator launch requested for AVD: $avdName"
