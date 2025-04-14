#!/bin/bash
set -e

CODESPACE_URL="https://${CODESPACE_NAME}-3000.app.github.dev"
TIDECLOAK_LOCAL_URL="https://staging.dauth.me"
TIDE_THRESHOLD_T=3
TIDE_THRESHOLD_N=5

echo "🔧 [0/11] Installing required dependencies (OpenSSL)..."
sudo apt-get update -y
sudo apt-get install -y libssl-dev

echo "🚀 [1/11] Cloning the MECHAPURSE..."

# Clean up old clones if they exist
[ -d mechapurse ] && rm -rf mechapurse
[ -d tide-js ] && rm -rf tide-js
[ -d tidecloak-js ] && rm -rf tidecloak-js
[ -d heimdall ] && rm -rf heimdall

# Clone the repositories
git clone https://github.com/tide-foundation/mechapurse.git

# TEMPORARY UNTIL WE HAVE STUFF TO PROD!!
git clone https://github.com/tide-foundation/tide-js.git
cd tide-js
git checkout origin/staging
cd ..

git clone https://github.com/tide-foundation/tidecloak-js.git
cd tidecloak-js
git checkout origin/staging
cd ..

git clone https://github.com/tide-foundation/heimdall.git
cd heimdall
git checkout origin/staging
cd ..

echo "📦 [2/11] Installing dependencies..."
cd mechapurse/tide-modules
mkdir -p modules
cp -r ../../heimdall/src/heimdall.js ./modules
tsc
cd ..
npm install
cd ..

# Update threshold values in tide-js
sed -i "s/\(export const Threshold = \)[0-9]\+;/\1${TIDE_THRESHOLD_T};/" ./tide-js/Tools/Utils.js
sed -i "s/\(export const Max = \)[0-9]\+;/\1${TIDE_THRESHOLD_N};/" ./tide-js/Tools/Utils.js

# Copy modules to tidecloak-js and mechapurse
cp -r tide-js ./tidecloak-js/modules/.
cp -r tidecloak-js ./mechapurse/node_modules/.

# ✍️ [3/3] Writing environment variables to mechapurse/.env.local
echo "TIDECLOAK_LOCAL_URL=$TIDECLOAK_LOCAL_URL" > mechapurse/.env.local
echo "CODESPACE_URL=$CODESPACE_URL" >> mechapurse/.env.local
