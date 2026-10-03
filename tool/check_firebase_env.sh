#!/usr/bin/env bash
# 確認 iOS／Android 原生設定檔指向指定環境；TestFlight 發布前由 CI 執行，
# 避免把 dev（test-o9g27r）設定打包進正式版本。
set -euo pipefail
case "${1:-}" in
  prod) expected=yellow-ribbon-growing-prod ;;
  dev) expected=test-o9g27r ;;
  *) echo "用法：bash tool/check_firebase_env.sh dev|prod" >&2; exit 64 ;;
esac
cd "$(git rev-parse --show-toplevel)"
ios=$(grep -A1 '<key>PROJECT_ID</key>' ios/Runner/GoogleService-Info.plist | sed -n 's:.*<string>\(.*\)</string>.*:\1:p')
android=$(sed -n 's/.*"project_id": *"\([^"]*\)".*/\1/p' android/app/google-services.json | head -1)
if [[ "$ios" != "$expected" || "$android" != "$expected" ]]; then
  echo "Firebase 環境不符：預期 ${expected}，iOS=${ios}，Android=${android}" >&2
  exit 1
fi
echo "Firebase 環境：${1}（${expected}）"
