param(
    [ValidateSet('list', 'start', 'install')][string]$Action = 'list',
    [string]$AvdName,
    [string]$DeviceId,
    [string]$ApkPath
)
$ErrorActionPreference = 'Stop'
$Sdk = $env:ANDROID_HOME
if (!$Sdk -or !(Test-Path "$Sdk\platform-tools\adb.exe")) {
    $Sdk = "$env:LOCALAPPDATA\Android\Sdk"
}
$Adb = "$Sdk\platform-tools\adb.exe"
$Emulator = "$Sdk\emulator\emulator.exe"
if (!(Test-Path $Adb)) { throw 'Existing Windows Android platform-tools not found. No install/download was attempted.' }

if ($Action -eq 'list') {
    & $Adb devices
    if ($LASTEXITCODE -ne 0) { throw 'Windows ADB could not list devices.' }
    if (Test-Path $Emulator) { & $Emulator -list-avds }
    exit 0
}
if ($Action -eq 'start') {
    if (!(Test-Path $Emulator)) { throw 'Existing Windows Android Emulator not found.' }
    $Avds = @(& $Emulator -list-avds | Where-Object { $_.Trim() } | ForEach-Object { $_.Trim() })
    if ($LASTEXITCODE -ne 0) { throw 'Could not list existing virtual devices.' }
    if (!$AvdName) {
        if ($Avds.Count -ne 1) { throw "Specify an AVD name. Available: $($Avds -join ', ')" }
        $AvdName = $Avds[0]
    }
    if ($AvdName -notin $Avds) { throw "Unknown AVD: $AvdName" }
    $Devices = @(& $Adb devices)
    if ($LASTEXITCODE -ne 0) { throw 'Windows ADB is unavailable.' }
    if ($Devices | Where-Object { $_ -match '^emulator-\d+\s+device$' }) {
        Write-Host 'A Windows emulator is already connected. Keeping it running.'
        exit 0
    }
    Start-Process -FilePath $Emulator -ArgumentList @('-avd', $AvdName)
    Write-Host 'Emulator process started. Wait for its Android Home screen before installing.'
    exit 0
}

if (!$ApkPath -or !(Test-Path $ApkPath)) { throw 'Built APK not found.' }
$DeviceLines = @(& $Adb devices)
if ($LASTEXITCODE -ne 0) { throw 'Could not read Windows emulator state.' }
$Ids = @($DeviceLines | Where-Object { $_ -match '^emulator-\d+\s+device$' } |
    ForEach-Object { ($_ -split '\s+')[0] })
if (!$DeviceId) {
    if ($Ids.Count -ne 1) { throw "Expected one running Windows emulator. Found $($Ids.Count). Start one or specify its ID." }
    $DeviceId = $Ids[0]
}
if ($DeviceId -notin $Ids) { throw 'Selected emulator is not connected in device state.' }
$Boot = (& $Adb -s $DeviceId shell getprop sys.boot_completed | Out-String).Trim()
if ($LASTEXITCODE -ne 0 -or $Boot -ne '1') { throw 'Android is still booting. Wait for Home, then retry install.' }
& $Adb -s $DeviceId install -r -t $ApkPath
if ($LASTEXITCODE -ne 0) { throw 'APK installation failed. Existing app data was not intentionally cleared.' }
& $Adb -s $DeviceId shell am start -n 'edu.hcmut.forest_sokoban/.MainActivity'
if ($LASTEXITCODE -ne 0) { throw 'The game activity could not be launched.' }
