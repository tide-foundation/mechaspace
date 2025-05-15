#!/bin/bash
set -e

CODESPACE_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
CODESPACE_URL_TC="https://${CODESPACE_NAME}-8080.app.github.dev"

# CODESPACE_URL=""
# if [[ -n "$CODESPACE_NAME" ]]; then
#   CODESPACE_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
# else
#   CODESPACE_URL="http://localhost:3000"
# fi
# TIDECLOAK_LOCAL_URL="https://staging.dauth.me"
# TIDE_THRESHOLD_T=3
# TIDE_THRESHOLD_N=5

echo "🔧 [0/4] Installing required dependencies (OpenSSL)..."
sudo apt-get update -y
sudo apt-get install -y libssl-dev

echo "🐳 [1/4] Pulling and starting Tidecloak container..."
docker pull docker.io/tideorg/tidecloak-dev:latest
docker run -d \
  --name tidecloak \
  -p 8080:8080 \
  -e KC_HOSTNAME=${CODESPACE_URL_TC} \
  -e KC_BOOTSTRAP_ADMIN_USERNAME=admin \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD=password \
  tideorg/tidecloak-dev:latest

echo ""
echo "✅ Tidecloak Setup complete."
echo ""

echo "🚀 [2/4] Cloning the MECHAPURSE..."

# Clean up old clones if they exist
[ -d mechapurse ] && rm -rf mechapurse
# [ -d tide-js ] && rm -rf tide-js
# [ -d tidecloak-js ] && rm -rf tidecloak-js
[ -d heimdall ] && rm -rf heimdall

# Clone the repositories
git clone https://github.com/tide-foundation/mechapurse.git

# TEMPORARY UNTIL WE HAVE STUFF TO PROD!!
git clone https://github.com/tide-foundation/heimdall.git
cd heimdall
git checkout origin/staging
cd ..

echo "📦 [3/4] Installing dependencies..."
cd mechapurse
npm install
cd ..


echo "✍️ [4/4] Writing environment variables to mechapurse/.env.local"
echo "TIDECLOAK_LOCAL_URL=$CODESPACE_URL_TC" > mechapurse/.env.local
echo "CODESPACE_URL=$CODESPACE_URL" >> mechapurse/.env.local

echo ""
echo "✅ Mechapurse Setup complete."
echo ""


