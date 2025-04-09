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

echo "📦 [2/11] Installing dependencies..."
cd tide-wallet
npm install
cd ..
cp -r tide-js ./tidecloak-js/modules/.
cp -r tidecloak-js ./tide-wallet

echo "🌐 [3/11] Building Codespace URLs..."
CODESPACE_URL_NEXT="https://${CODESPACE_NAME}-3000.app.github.dev"

echo "🔄 [4/11] Updating test-realm.json with Codespace URL..."
cp .devcontainer/test-realm.json tide-wallet/test-realm.json
sed -i "s|http://localhost:3000|${CODESPACE_URL_NEXT}|g" tide-wallet/test-realm.json

# Generate a new unique realm name (e.g., "nextjs-c6d2e5b7-...") and update all instances of "nextjs-test"
NEW_REALM="nextjs-$(uuidgen | tr '[:upper:]' '[:lower:]')"
sed -i "s/nextjs-test/${NEW_REALM}/g" tide-wallet/test-realm.json
echo "New realm name set to: ${NEW_REALM}"

echo "🔍 [5/11] Checking existence and non-emptiness of tide-wallet/tidecloak.json..."
if [[ ! -s tide-wallet/tidecloak.json ]]; then
    echo "❗ tide-wallet/tidecloak.json does not exist or is empty."
    echo "❓ If you have an existing realm name or client adapter configuration for tide-wallet, please paste it now."
    echo "    Otherwise, press Enter to continue without updating."
    read -r EXISTING_REALM_OR_ADAPTER
    if [ -n "$EXISTING_REALM_OR_ADAPTER" ]; then
        echo "$EXISTING_REALM_OR_ADAPTER" > tide-wallet/tidecloak.json
        echo "✅ tide-wallet/tidecloak.json updated with the provided configuration."
        exit 0
    else
        echo "ℹ️ No existing configuration provided for tide-wallet/tidecloak.json."
    fi
else
    echo "✅ tide-wallet/tidecloak.json exists and is not empty."
fi

echo "🔐 [6/11] Fetching admin token..."
RESULT=$(curl -s --data "username=admin&password=password&grant_type=password&client_id=admin-cli" \
  "${TIDECLOAK_LOCAL_URL}/realms/master/protocol/openid-connect/token")
TOKEN=$(echo "$RESULT" | sed 's/.*access_token":"//g' | sed 's/".*//g')

echo "🌍 [7/11] Creating realm using Admin API..."
curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  --data-binary @tide-wallet/test-realm.json

echo "🛠️ [8/11] Creating Tide IDP, licensing, and enabling IGA..."
curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/vendorResources/setUpTideRealm" \
  -H "Authorization: Bearer $TOKEN" \
  -d "email=email@tide.org"

curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/tideAdminResources/toggle-iga" \
  -H "Authorization: Bearer $TOKEN" \
  -d "isIGAEnabled=true"

# New step: Update the CustomAdminUIDomain for Tide IDP settings before linking tide account
echo "🔄 [8.5/11] Updating CustomAdminUIDomain via Admin API..."
curl -s -X GET "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/identity-provider/instances/tide" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
| jq '.config.CustomAdminUIDomain = "'"${CODESPACE_URL_NEXT}"'"' \
| curl -s -X PUT "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/identity-provider/instances/tide" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer ${TOKEN}" \
  -d @-

echo "✅ [9/11] Approving and committing all client default user context..."
CLIENTREQUESTS=$(curl -s -X GET "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/tide-admin/change-set/clients/requests" \
  -H "Authorization: Bearer $TOKEN")

echo "$CLIENTREQUESTS"

if ! echo "$CLIENTREQUESTS" | jq empty; then
  echo "❌ Error: The GET response is not valid JSON."
  exit 1
fi

echo "$CLIENTREQUESTS" | jq -c '.[]' | while IFS= read -r record; do
  changeSetId=$(echo "$record" | jq -r '.draftRecordId')
  changeSetType=$(echo "$record" | jq -r '.changeSetType')
  actionType=$(echo "$record" | jq -r '.actionType')

  payload=$(jq -n --arg id "$changeSetId" --arg type "$changeSetType" --arg action "$actionType" \
    '{changeSetId: $id, changeSetType: $type, actionType: $action}')

  echo "📝 Payload: $payload"

  sign_response=$(curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/tide-admin/change-set/sign" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")

  echo "🔏 Sign Response: $sign_response"

  commit_response=$(curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/tide-admin/change-set/commit" \
    -H "Authorization: Bearer $TOKEN" \
    -H "Content-Type: application/json" \
    -d "$payload")

  echo "✅ Commit Response: $commit_response"
done

echo "👤 [10/11] Creating test user..."
response=$(curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/users" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "attributes": {
      "locale": ""
    },
    "requiredActions": [],
    "emailVerified": false,
    "username": "admin",
    "email": "admin@tidecloak.com",
    "firstName": "admin",
    "lastName": "user",
    "groups": [],
    "enabled": true
  }')

userresponse=$(curl -s -X GET "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/users?username=admin" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json")

userId=$(echo "$userresponse" | jq -r '.[0].id')
echo "$userId"

# Provide different lifespan if needed
invitelink=$(curl -s -X POST "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/tideAdminResources/get-required-action-link?userId=$userId&lifespan=43200" \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '["link-tide-account-action"]')

echo "$invitelink"

echo "📥 [11/11] Fetching adapter config and writing to tidecloak.json..."
CLIENT_RESULT=$(curl -s -X GET \
  "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/clients?clientId=myclient" \
  -H "Authorization: Bearer $TOKEN")
CLIENT_UID=$(echo "$CLIENT_RESULT" | jq -r '.[0].id')

ADAPTER_RESULT=$(curl -s -X GET \
  "${TIDECLOAK_LOCAL_URL}/admin/realms/${NEW_REALM}/vendorResources/get-installations-provider?clientId=$CLIENT_UID&providerId=keycloak-oidc-keycloak-json" \
  -H "Authorization: Bearer $TOKEN")

echo "$ADAPTER_RESULT" > tide-wallet/tidecloak.json

echo "🎉 [12/11] Setup complete! Next.js app is ready with the dynamic Tidecloak config."

echo ""
echo "✅ Setup complete. You can close this terminal or continue below."
echo ""
