param(
    [switch]$InstallFlutter,
    [string]$FlutterDirectory = "$env:LOCALAPPDATA\ForestSokoban\flutter"
)

$ErrorActionPreference = 'Stop'
$FlutterVersion = '3.50.0'

if ($InstallFlutter -and !(Test-Path "$FlutterDirectory\bin\flutter.bat")) {
    if (Test-Path $FlutterDirectory) {
        throw "Directory already exists: $FlutterDirectory. Choose an empty location."
    }
    $ReleaseIndex = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $Release = $ReleaseIndex.releases | Where-Object {
        $_.version -eq $FlutterVersion -and $_.channel -eq 'stable'
    } | Select-Object -First 1
    if (!$Release) { throw "Flutter $FlutterVersion is absent from the official release index." }
    $Archive = Join-Path $env:TEMP "forest-flutter-$FlutterVersion.zip"
    Write-Host "Downloading Flutter $FlutterVersion from the official archive..."
    Invoke-WebRequest "$($ReleaseIndex.base_url)/$($Release.archive)" -OutFile $Archive
    if ((Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Release.sha256) {
        throw 'SDK checksum mismatch. Installation stopped.'
    }
    $Parent = Split-Path $FlutterDirectory -Parent
    New-Item -ItemType Directory -Force $Parent | Out-Null
    if ((Split-Path $FlutterDirectory -Leaf) -ne 'flutter') {
        throw 'FlutterDirectory must end with a folder named flutter.'
    }
    Expand-Archive -Path $Archive -DestinationPath $Parent
    Remove-Item $Archive
}

if (Test-Path "$FlutterDirectory\bin\flutter.bat") {
    $FlutterBin = "$FlutterDirectory\bin"
    $env:Path = "$FlutterBin;$env:Path"
    if ($InstallFlutter) {
        $UserPath = [Environment]::GetEnvironmentVariable('Path', 'User')
        if ($FlutterBin -notin ($UserPath -split ';')) {
            [Environment]::SetEnvironmentVariable('Path', "$FlutterBin;$UserPath", 'User')
        }
    }
}

if (!(Get-Command flutter -ErrorAction SilentlyContinue)) {
    throw 'Flutter not found. Run this script with -InstallFlutter, or add your Flutter SDK bin folder to PATH.'
}
flutter --version
flutter doctor -v
Write-Host ''
Write-Host 'Next: install Android Studio on Windows and complete its Setup Wizard.'
Write-Host 'In SDK Manager install Android API 36, Build-Tools, Platform-Tools, Command-line Tools, and Android Emulator.'
Write-Host 'Run flutter doctor --android-licenses, create an AVD in Device Manager, then flutter devices.'
Write-Host 'Open a new PowerShell after installation so the updated PATH is available.'
