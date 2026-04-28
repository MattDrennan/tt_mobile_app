#!/usr/bin/env bash
# Usage: scripts/take_screenshots.sh [device-id]
#
# Runs the integration-test screenshot suite via flutter drive and saves PNGs
# to screenshots/ in the project root.
#
# Tips:
#   List available devices:   flutter devices
#   iOS simulator:            scripts/take_screenshots.sh "iPhone 16 Pro"
#   Android emulator:         scripts/take_screenshots.sh emulator-5554
#   Omit device-id to use the first available device.
#
# Note: the first run may show a notification-permission dialog on iOS.
# Grant it once and re-run to get clean screenshots.

set -euo pipefail
cd "$(dirname "$0")/.."

mkdir -p screenshots

DEVICE="${1:-}"

echo "==> Running screenshot capture..."
flutter drive \
  ${DEVICE:+-d "$DEVICE"} \
  --driver  integration_test/driver.dart \
  --target  integration_test/screenshots_test.dart

echo ""
echo "==> Done. Screenshots saved to: $(pwd)/screenshots/"
ls -1 screenshots/*.png 2>/dev/null || echo "    (no .png files found — check the output above for errors)"
