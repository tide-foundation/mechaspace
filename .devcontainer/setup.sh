#!/bin/bash
set -e

CODESPACE_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
CODESPACE_URL_TC="https://${CODESPACE_NAME}-8080.app.github.dev"

echo "🔧 [0/4] Installing required dependencies (OpenSSL)..."
sudo apt-get update -y
sudo apt-get install -y libssl-dev

echo "🐳 [1/4] Pulling and starting Tidecloak container..."
docker pull docker.io/tideorg/tidecloak-dev:latest
docker run -d \
  --name tidecloak \
  -p 8080:8080 \
  -e KC_HOSTNAME="${CODESPACE_URL_TC}" \
  -e KC_BOOTSTRAP_ADMIN_USERNAME="admin" \
  -e KC_BOOTSTRAP_ADMIN_PASSWORD="password" \
  tideorg/tidecloak-dev:0.9.4

echo ""
echo "✅ Tidecloak Setup complete."
echo ""

echo "🚀 [2/4] Cloning the MECHAPURSE..."

# Clean up old clones if they exist
REPOS=("mechapurse" "heimdall")
for repo in "${REPOS[@]}"; do
  [ -d "$repo" ] && rm -rf "$repo"
done

# Clone the repositories
git clone https://github.com/tide-foundation/mechapurse.git

echo "📦 [3/4] Installing dependencies..."
cd mechapurse
npm install
cd ..

echo "🚧 [INFO] Cloning and setting up Heimdall (temporary)"
git clone https://github.com/tide-foundation/heimdall.git
cd heimdall
git checkout origin/staging
cd ..
cd mechapurse/tide-modules
mkdir -p modules
cp -r ../../heimdall/src/heimdall.js ./modules
tsc
cd ..
npm install
cd ..

echo "✍️ [4/4] Writing environment variables to mechapurse/.env.local"
cat <<EOF > mechapurse/.env.local
TIDECLOAK_LOCAL_URL=${CODESPACE_URL_TC}
CODESPACE_URL=${CODESPACE_URL}
EOF

echo ""
echo "✅ Mechapurse Setup complete."
echo ""
