#!/usr/bin/env bash
set -euo pipefail
# Run after the signed IPA is built; this only installs the capture harness in a simulator.
device_id=$(xcrun simctl list devices available -j | python3 -c '
import json,sys
devices=[d for group in json.load(sys.stdin)["devices"].values() for d in group if "iPad Pro 13-inch" in d["name"]]
if not devices: raise SystemExit("No 13-inch iPad Pro simulator available")
print(devices[0]["udid"])
')
xcrun simctl boot "$device_id" || true
xcrun simctl bootstatus "$device_id" -b
xcrun simctl status_bar "$device_id" override --time 9:41 --batteryState charged --batteryLevel 100
flutter drive --driver=test_driver/store_screenshots.dart --target=integration_test/store_screenshots_test.dart -d "$device_id"
mkdir -p "${CM_EXPORT_DIR:-build/export}/store-screenshots"
cp build/store-screenshots/*.png "${CM_EXPORT_DIR:-build/export}/store-screenshots/"
python3 - <<'PY'
import pathlib,struct
for path in pathlib.Path('build/store-screenshots').glob('*.png'):
    width,height=struct.unpack('>II',path.read_bytes()[16:24])
    if width <= height: raise SystemExit(f'Expected landscape screenshot: {path} {width}x{height}')
    print(f'{path}: {width}x{height}')
PY
