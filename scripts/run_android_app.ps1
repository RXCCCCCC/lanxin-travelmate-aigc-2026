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
  throw 'ANDROID_SDK_ROOT or ANDROID_HOME must be set before running the app.'
}

$repoRoot = Split-Path -Parent $PSScriptRoot
$mobileRoot = Join-Path $repoRoot 'apps\mobile'
$flutter = 'G:\develop\flutter\bin\flutter.bat'
$sqlite = 'G:\develop\sqlite'
$env:PATH = "$sqlite;$env:PATH"
$env:PUB_CACHE = if ($env:PUB_CACHE) { $env:PUB_CACHE } else { 'G:\develop\pub-cache' }
$env:GRADLE_USER_HOME = if ($env:GRADLE_USER_HOME) { $env:GRADLE_USER_HOME } else { 'G:\develop\.gradle' }

Push-Location $mobileRoot
try {
  & $flutter run --dart-define=API_BASE_URL=http://10.0.2.2:8000
}
finally {
  Pop-Location
}
