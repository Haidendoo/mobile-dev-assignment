#!/usr/bin/env bash
set -euo pipefail
project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
for executable in .toolchains/flutter/bin/flutter .toolchains/flutter/bin/cache/dart-sdk/bin/dart .toolchains/jdk21/bin/javac .toolchains/android-sdk/platform-tools/adb; do
  if [[ ! -x "$project_root/$executable" ]]; then
    echo "Required local tool is missing: $executable. No download was started." >&2
    exit 1
  fi
done
source "$project_root/tools/env-wsl.sh"
if [[ $# -gt 0 ]]; then
  if [[ $# -ne 2 || "$1" != --windows-debug-key || ! -f "$2" ]]; then
    echo 'Usage: bash tools/setup-wsl.sh [--windows-debug-key /mnt/c/Users/NAME/.android/debug.keystore]' >&2
    exit 2
  fi
  debug_key="$ANDROID_USER_HOME/debug.keystore"
  mkdir -p "$ANDROID_USER_HOME"
  if [[ ! -f "$debug_key" ]] || ! cmp -s "$2" "$debug_key"; then
    if [[ -f "$debug_key" ]]; then
      backup="$debug_key.before-windows-sync"
      if [[ -e "$backup" ]]; then
        echo "A debug-key backup already exists at $backup; inspect it before changing signing keys again." >&2
        exit 1
      fi
      cp -p "$debug_key" "$backup"
    fi
    cp "$2" "$debug_key"
    chmod 600 "$debug_key"
  fi
  echo 'Using the existing Windows development signing key. No keystore is tracked by Git.'
fi
python3 - "$project_root" <<'PY'
import json, os, pathlib, sys
root = pathlib.Path(sys.argv[1])
file = root / '.vscode/settings.json'
settings = {}
if file.exists():
    try:
        settings = json.loads(file.read_text())
    except json.JSONDecodeError:
        raise SystemExit('Existing .vscode/settings.json contains comments or invalid JSON. Preserved unchanged; merge SDK settings manually.')
env_keys = ['FLUTTER_ROOT', 'JAVA_HOME', 'ANDROID_HOME', 'ANDROID_SDK_ROOT',
            'ANDROID_USER_HOME', 'PUB_CACHE', 'GRADLE_USER_HOME', 'XDG_CONFIG_HOME',
            'FLUTTER_SUPPRESS_ANALYTICS', 'PATH']
env = {key: os.environ[key] for key in env_keys}
settings.update({
    'dart.flutterSdkPath': str(root / '.toolchains/flutter'),
    'dart.sdkPath': str(root / '.toolchains/flutter/bin/cache/dart-sdk'),
    'dart.openDevTools': 'never',
    'dart.projectSearchDepth': 3,
})
for key in ['dart.env', 'terminal.integrated.env.linux']:
    settings[key] = {**settings.get(key, {}), **env}
settings['[dart]'] = {**settings.get('[dart]', {}),
    'editor.defaultFormatter': 'Dart-Code.dart-code', 'editor.formatOnSave': True}
for key in ['files.watcherExclude', 'search.exclude']:
    settings[key] = {**settings.get(key, {}),
        '**/.toolchains/**': True, '**/.pub-cache/**': True,
        '**/build/**': True, '**/.dart_tool/**': True}
file.parent.mkdir(exist_ok=True)
file.write_text(json.dumps(settings, indent=2) + '\n')
print('Configured VS Code Linux SDK, Java, terminal PATH and caches.')
print('Machine-specific .vscode/settings.json is ignored by Git.')
PY
flutter --no-version-check --version
javac -version
echo 'Open this repository root in VS Code using WSL. Reload the window and open a new terminal.'
