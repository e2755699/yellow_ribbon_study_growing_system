#!/usr/bin/env bash
# 切換 iOS／Android 原生 Firebase 設定檔。預設提交的是 prod；本機要連舊專案
# test-o9g27r（dev）時執行 `bash tool/use_firebase_env.sh dev`，結束後切回 prod，
# 不要把 dev 設定檔提交到 ios/Runner 或 android/app。
# Web 另以 --dart-define=YR_FIREBASE_ENV=dev 切換。
set -euo pipefail
env="${1:-}"
case "$env" in
  prod) expected=yellow-ribbon-growing-prod ;;
  dev) expected=test-o9g27r ;;
  *) echo "用法：bash tool/use_firebase_env.sh dev|prod" >&2; exit 64 ;;
esac
cd "$(git rev-parse --show-toplevel)"
cp "config/firebase/$env/GoogleService-Info.plist" ios/Runner/GoogleService-Info.plist
cp "config/firebase/$env/google-services.json" android/app/google-services.json
bash tool/check_firebase_env.sh "$env"
echo "已切換為 $env（$expected）"
