#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
action="${1:-list}"
case "$action" in list|start|install) ;; *) echo 'Usage: bash tools/windows-emulator.sh [list|start|install] [AVD name or device ID]' >&2; exit 2;; esac
ps_exe="${WINDOWS_POWERSHELL:-/mnt/c/Windows/System32/WindowsPowerShell/v1.0/powershell.exe}"
if [[ ! -f "$ps_exe" ]]; then
  echo 'Windows PowerShell interop is unavailable. WSL code/tests/APK builds still work.' >&2
  exit 1
fi
script_path="$(wslpath -w "$project_root/tools/windows-emulator.ps1")"
args=(-NoProfile -NonInteractive -File "$script_path" -Action "$action")
if [[ "$action" == start && -n "${2:-}" ]]; then args+=(-AvdName "$2"); fi
if [[ "$action" == install ]]; then
  apk="$project_root/app/build/app/outputs/flutter-apk/app-debug.apk"
  [[ -f "$apk" ]] || { echo 'Build the emulator APK first using the VS Code build task.' >&2; exit 1; }
  args+=(-ApkPath "$(wslpath -w "$apk")")
  if [[ -n "${2:-}" ]]; then args+=(-DeviceId "$2"); fi
fi
"$ps_exe" "${args[@]}"
