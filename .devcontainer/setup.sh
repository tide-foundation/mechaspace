#!/bin/bash
set -e

echo "🔧 [0/11] Installing required dependencies (OpenSSL)..."
sudo apt-get update
sudo apt-get install -y libssl-dev

echo "🚀 [1/11] Cloning the MECHAPURSE..."
git clone https://github.com/tide-foundation/tide-wallet.git

# TEMPORARY UNTIL WE HAVE STUFF TO PROD!!
git clone https://github.com/tide-foundation/tide-js.git
cd tide-js
git checkout origin/staging
cd ..
git clone https://github.com/tide-foundation/tidecloak-js.git
cd tidecloak-js
git checkout origin/staging
cd ..

echo "🌐 [3/11] Building Codespace URLs..."
CODESPACE_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
TIDECLOAK_LOCAL_URL="https://staging.dauth.me"

# ✍️ [4/11] Writing TIDECLOAK_LOCAL_URL to tide-wallet/.env.local
echo "TIDECLOAK_LOCAL_URL=$TIDECLOAK_LOCAL_URL" > tide-wallet/.env.local
echo "CODESPACE_URL=$CODESPACE_URL" > tide-wallet/.env.local

