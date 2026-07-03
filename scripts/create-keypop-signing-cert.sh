#!/usr/bin/env bash
# Create a local self-signed code signing certificate for KeyPop.app.
# Stable across rebuilds so TCC grants persist (unlike ad-hoc signing).
#
# Usage: ./scripts/create-keypop-signing-cert.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
# shellcheck source=keypop-paths.sh
source "${SCRIPT_DIR}/keypop-paths.sh"

CERT_NAME="KeyPop Dev"
KEYCHAIN="${HOME}/Library/Keychains/login.keychain-db"

if security find-certificate -c "${CERT_NAME}" -a 2>/dev/null | grep -q "keychain:"; then
  echo "Certificate already exists: ${CERT_NAME}"
  if [[ -d "$KEYPOP_APP" ]]; then
    codesign -dv --verbose=2 "$KEYPOP_APP" 2>&1 | grep "Authority=${CERT_NAME}" && \
      echo "KeyPop.app is signed with ${CERT_NAME}" || true
  fi
  exit 0
fi

TMPDIR_CERT="$(mktemp -d)"
trap 'rm -rf "$TMPDIR_CERT"' EXIT

cat >"${TMPDIR_CERT}/keypop-dev.cnf" <<EOF
[ req ]
default_bits       = 2048
prompt             = no
default_md         = sha256
distinguished_name = dn
x509_extensions    = ext

[ dn ]
CN = ${CERT_NAME}

[ ext ]
basicConstraints = critical,CA:FALSE
keyUsage = critical,digitalSignature
extendedKeyUsage = critical,codeSigning
EOF

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout "${TMPDIR_CERT}/key.pem" \
  -out "${TMPDIR_CERT}/cert.pem" \
  -days 825 \
  -config "${TMPDIR_CERT}/keypop-dev.cnf" \
  -extensions ext 2>/dev/null

openssl pkcs12 -export -legacy \
  -out "${TMPDIR_CERT}/keypop-dev.p12" \
  -inkey "${TMPDIR_CERT}/key.pem" \
  -in "${TMPDIR_CERT}/cert.pem" \
  -passout pass:keypop \
  -name "${CERT_NAME}"

security import "${TMPDIR_CERT}/keypop-dev.p12" \
  -k "${KEYCHAIN}" \
  -P keypop \
  -T /usr/bin/codesign \
  -T /usr/bin/security \
  -A

echo "Created: ${CERT_NAME}"
echo ""
echo "Optional — trust for code signing in Keychain Access:"
echo "  Keychain Access → login → My Certificates → ${CERT_NAME}"
echo "  Trust → Code Signing → Always Trust"
echo ""
echo "Re-sign and re-grant TCC after first install:"
echo "  ./scripts/install.sh"
echo "  ./scripts/fix-keypop-tcc.sh"
