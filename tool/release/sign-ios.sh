#!/usr/bin/env bash
set -euo pipefail
set +x

: "${APP_STORE_CONNECT_ISSUER_ID:?Missing Apple issuer ID}"
: "${APP_STORE_CONNECT_KEY_IDENTIFIER:?Missing Apple API key ID}"
: "${APP_STORE_CONNECT_PRIVATE_KEY:?Missing Apple API private key}"
: "${CERTIFICATE_PRIVATE_KEY:?Missing persistent signing private key}"

keychain initialize
app-store-connect fetch-signing-files yellowribbon.studygrowingsystem.app \
  --type IOS_APP_STORE --strict-match-identifier --create \
  --api-unauthorized-retries 0 --api-server-error-retries 2
keychain add-certificates
xcode-project use-profiles
