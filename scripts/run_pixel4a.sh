#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
FLUTTER_BIN="$(command -v flutter)"
ANDROID_HOME="${ANDROID_HOME:-${ANDROID_SDK_ROOT:-$HOME/Library/Android/sdk}}"
export ANDROID_HOME ANDROID_SDK_ROOT="$ANDROID_HOME"

# Android Studio ships the JDK required by the Android Gradle plugin.
if [[ -z "${JAVA_HOME:-}" && -d "/Applications/Android Studio.app/Contents/jbr/Contents/Home" ]]; then
  export JAVA_HOME="/Applications/Android Studio.app/Contents/jbr/Contents/Home"
  export PATH="$JAVA_HOME/bin:$PATH"
fi

cd "$ROOT"
"$FLUTTER_BIN" pub get
if ! "$ANDROID_HOME/emulator/emulator" -list-avds | grep -Fxq 'Pixel_4a'; then
  echo "No existe el AVD Pixel_4a. Créalo en Android Studio > Device Manager (API 24+)." >&2
  exit 1
fi
if ! "$ANDROID_HOME/platform-tools/adb" devices | grep -q 'emulator-.*device$'; then
  "$ANDROID_HOME/emulator/emulator" -avd Pixel_4a -no-snapshot-load >/dev/null 2>&1 &
  "$ANDROID_HOME/platform-tools/adb" wait-for-device
  until [[ "$("$ANDROID_HOME/platform-tools/adb" shell 'getprop sys.boot_completed; getprop dev.bootcomplete' 2>/dev/null | tr -d '\r' | grep -E '1' | head -1)" == "1" ]]; do sleep 2; done
fi
DEVICE_ID="$("$ANDROID_HOME/platform-tools/adb" devices | awk '/^emulator-[0-9]+[[:space:]]+device$/ {print $1; exit}')"
if [[ -z "$DEVICE_ID" ]]; then echo "No se detectó el emulador Pixel 4a." >&2; exit 1; fi
"$FLUTTER_BIN" run -d "$DEVICE_ID"
