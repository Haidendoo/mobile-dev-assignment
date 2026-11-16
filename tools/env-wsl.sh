#!/usr/bin/env bash
# Source this file: source tools/env-wsl.sh
forest_project_root="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export FLUTTER_ROOT="$forest_project_root/.toolchains/flutter"
export JAVA_HOME="$forest_project_root/.toolchains/jdk21"
export ANDROID_HOME="$forest_project_root/.toolchains/android-sdk"
export ANDROID_SDK_ROOT="$ANDROID_HOME"
export ANDROID_USER_HOME="$forest_project_root/.toolchains/android-user"
export PUB_CACHE="$forest_project_root/.pub-cache"
export GRADLE_USER_HOME="$forest_project_root/.toolchains/gradle"
export XDG_CONFIG_HOME="$forest_project_root/.toolchains/config"
export FLUTTER_SUPPRESS_ANALYTICS=true
export PATH="$FLUTTER_ROOT/bin:$JAVA_HOME/bin:$ANDROID_HOME/platform-tools:$PATH"
unset forest_project_root
