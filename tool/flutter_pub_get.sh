#!/usr/bin/env bash
set -euo pipefail

# Workaround: Flutter/Xcode rsync may fail during `flutter pub get` if
# SPM SourcePackages directories do not exist (common after `flutter clean`).
mkdir -p build/ios/SourcePackages build/macos/SourcePackages

flutter pub get "$@"
