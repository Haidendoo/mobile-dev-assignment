param(
    [switch]$InstallFlutter,
    [string]$FlutterDirectory = "$env:LOCALAPPDATA\ForestSokoban\flutter"
)

$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'
$FlutterVersion = '3.50.0'

if ($InstallFlutter -and !(Test-Path "$FlutterDirectory\bin\flutter.bat")) {
    if (Test-Path $FlutterDirectory) {
        throw "Directory already exists: $FlutterDirectory. Choose an empty location."
    }
    if ((Split-Path $FlutterDirectory -Leaf) -ne 'flutter') {
        throw 'FlutterDirectory must end with a folder named flutter.'
    }
    $ReleaseIndex = Invoke-RestMethod 'https://storage.googleapis.com/flutter_infra_release/releases/releases_windows.json'
    $Release = $ReleaseIndex.releases | Where-Object {
        $_.version -eq $FlutterVersion -and $_.channel -eq 'stable'
    } | Select-Object -First 1
    if (!$Release) { throw "Flutter $FlutterVersion is absent from the official release index." }
    $Archive = Join-Path $env:TEMP "forest-flutter-$FlutterVersion.zip"
    $ArchiveVerified = (Test-Path $Archive) -and (
        (Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant() -eq $Release.sha256
    )
    if (!$ArchiveVerified) {
        if (!(Get-Command curl.exe -ErrorAction SilentlyContinue)) {
            throw 'curl.exe is required for resumable SDK downloads. The existing archive is preserved.'
        }
        if (Test-Path $Archive) {
            $ExistingMB = [Math]::Round((Get-Item $Archive).Length / 1MB, 1)
            Write-Host "Resuming Flutter $FlutterVersion download from $ExistingMB MiB..."
        } else {
            Write-Host "Downloading Flutter $FlutterVersion from the official archive..."
        }
        # Use the executable explicitly: Windows PowerShell aliases curl to
        # Invoke-WebRequest. Keep the partial archive so Ctrl+C/retries can resume.
        & curl.exe --fail --location --retry 3 --connect-timeout 30 --continue-at - --output $Archive "$($ReleaseIndex.base_url)/$($Release.archive)"
        if ($LASTEXITCODE -ne 0) {
            throw 'Download interrupted. The partial ZIP is preserved; rerun this command to resume.'
        }
    } else {
        Write-Host 'Using the existing checksum-verified Flutter archive.'
    }
    Write-Host 'Verifying SDK checksum...'
    if ((Get-FileHash $Archive -Algorithm SHA256).Hash.ToLowerInvariant() -ne $Release.sha256) {
        throw 'SDK checksum mismatch. Installation stopped; archive preserved for inspection.'
    }
    $Parent = Split-Path $FlutterDirectory -Parent
    New-Item -ItemType Directory -Force $Parent | Out-Null
    Write-Host "Extracting Flutter to $FlutterDirectory. This can take several minutes..."
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
if (Test-Path "$FlutterDirectory\bin\cache\dart-sdk\bin\dart.exe") {
    Write-Host 'Checking whether Windows permits the installed Dart SDK to run...'
    try {
        & "$FlutterDirectory\bin\cache\dart-sdk\bin\dart.exe" --version
        if ($LASTEXITCODE -ne 0) {
            throw "Dart exited with code $LASTEXITCODE."
        }
    } catch {
        throw "Dart could not start: $($_.Exception.Message) SDK files are already installed at $FlutterDirectory; do not download them again. If Windows reports Device Guard or Application Control, ask the device administrator to review and approve this SDK. Setup has stopped."
    }
}
flutter --version
if ($LASTEXITCODE -ne 0) {
    throw "Flutter startup failed with code $LASTEXITCODE. Do not download the SDK again. Resolve the startup error above before continuing."
}
flutter doctor -v
if ($LASTEXITCODE -ne 0) {
    throw 'Flutter doctor reported environment problems. Resolve the checks listed above; the SDK does not need to be downloaded again.'
}
Write-Host ''
Write-Host 'Next: install Android Studio on Windows and complete its Setup Wizard.'
Write-Host 'In SDK Manager install Android API 36, Build-Tools, Platform-Tools, Command-line Tools, and Android Emulator.'
Write-Host 'Run flutter doctor --android-licenses, create an AVD in Device Manager, then flutter devices.'
Write-Host 'Open a new PowerShell after installation so the updated PATH is available.'
