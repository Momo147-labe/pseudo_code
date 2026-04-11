#!/bin/bash
# ============================================================
# Script de déploiement Pseudo Code (Backblaze B2 & Supabase)
# ============================================================

set -e

# Charger les variables depuis .env
if [ -f .env ]; then
    export $(grep -v '^#' .env | xargs)
fi

# Variables de mise à jour
IS_FORCED=false
RELEASE_NOTES="Mise à jour régulière"
PLATFORM=$1 # "android" ou "windows" ou "linux"

if [ "$PLATFORM" != "android" ] && [ "$PLATFORM" != "windows" ] && [ "$PLATFORM" != "linux" ]; then
    echo "Usage: ./scripts/deploy_update.sh [android|windows|linux]"
    exit 1
fi

# Version auto-détectée
PUBSPEC_VERSION=$(grep '^version:' pubspec.yaml | sed 's/version: //' | xargs)
VERSION_NAME=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f1)
VERSION_CODE=$(echo "$PUBSPEC_VERSION" | cut -d'+' -f2)

if [ "$PLATFORM" == "android" ]; then
    FILE_PATH="build/app/outputs/flutter-apk/app-release.apk"
    FILE_NAME="pseudo_code_v${VERSION_NAME}.apk"
    MIME_TYPE="application/vnd.android.package-archive"
elif [ "$PLATFORM" == "linux" ]; then
    # Chemin vers l'AppImage ou binaire Linux
    FILE_PATH="build/linux/x64/release/bundle/pseudo_code"
    FILE_NAME="pseudo_code_v${VERSION_NAME}_linux"
    MIME_TYPE="application/octet-stream"
else
    # Chemin vers l'installeur Windows généré par Inno Setup
    # On cherche le premier .exe dans le dossier Output
    POTENTIAL_FILE=$(ls Output/*.exe 2>/dev/null | head -n 1)
    if [ -n "$POTENTIAL_FILE" ]; then
        FILE_PATH="$POTENTIAL_FILE"
        FILE_NAME="pseudo_code_v${VERSION_NAME}_installer.exe"
    else
        FILE_PATH="build/windows/x64/runner/Release/pseudo_code_installer.exe"
        FILE_NAME="pseudo_code_v${VERSION_NAME}_installer.exe"
    fi
    MIME_TYPE="application/x-msdownload"
fi

if [ ! -f "$FILE_PATH" ]; then
    echo "❌ Fichier introuvable à $FILE_PATH. Veuillez builder l'application d'abord."
    exit 1
fi

echo "🚀 Déploiement $PLATFORM ($VERSION_NAME) vers Backblaze B2..."

# 1. Authentification Backblaze B2
AUTH_RESP=$(curl -s https://api.backblazeb2.com/b2api/v2/b2_authorize_account -u "${BACKBLAZE_keyID}:${BACKBLAZE_applicationKey}")
AUTH_TOKEN=$(echo "$AUTH_RESP" | jq -r '.authorizationToken')
API_URL=$(echo "$AUTH_RESP" | jq -r '.apiUrl')
DOWNLOAD_URL=$(echo "$AUTH_RESP" | jq -r '.downloadUrl')
ACCOUNT_ID=$(echo "$AUTH_RESP" | jq -r '.accountId')

BUCKET_NAME=$(curl -s "${API_URL}/b2api/v2/b2_list_buckets" -H "Authorization: ${AUTH_TOKEN}" -d "{\"accountId\": \"$ACCOUNT_ID\"}" | jq -r ".buckets[] | select(.bucketId == \"$BACKBLAZE_BUCKET_ID\") | .bucketName")

# 2. Upload
UPLOAD_RESP=$(curl -s "${API_URL}/b2api/v2/b2_get_upload_url" -H "Authorization: ${AUTH_TOKEN}" -d "{\"bucketId\": \"$BACKBLAZE_BUCKET_ID\"}")
UPLOAD_URL=$(echo "$UPLOAD_RESP" | jq -r '.uploadUrl')
UPLOAD_TOKEN=$(echo "$UPLOAD_RESP" | jq -r '.authorizationToken')

echo "📤 Upload de $FILE_NAME..."
SHA1=$(sha1sum "$FILE_PATH" | awk '{print $1}')

curl -s -X POST "$UPLOAD_URL" \
    -H "Authorization: ${UPLOAD_TOKEN}" \
    -H "X-B2-File-Name: ${FILE_NAME}" \
    -H "Content-Type: ${MIME_TYPE}" \
    -H "X-B2-Content-Sha1: ${SHA1}" \
    --data-binary "@${FILE_PATH}" > /dev/null

# 3. Supabase
echo "🗄️  Mise à jour Supabase (pseudo_code_app_versions)..."

# Удаляем старую версию для этой платформы (optionnel)
curl -s -X DELETE "${SUPABASE_URL}/rest/v1/pseudo_code_app_versions?platform=eq.${PLATFORM}" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
    -H "apikey: ${SUPABASE_SERVICE_KEY}"

curl -s -X POST "${SUPABASE_URL}/rest/v1/pseudo_code_app_versions" \
    -H "Authorization: Bearer ${SUPABASE_SERVICE_KEY}" \
    -H "apikey: ${SUPABASE_SERVICE_KEY}" \
    -H "Content-Type: application/json" \
    -d "{
        \"version_code\": ${VERSION_CODE},
        \"version_name\": \"${VERSION_NAME}\",
        \"platform\": \"${PLATFORM}\",
        \"file_url\": \"${FILE_NAME}\",
        \"is_forced\": ${IS_FORCED},
        \"release_notes\": \"${RELEASE_NOTES}\"
    }" > /dev/null

echo "✅ Déploiement terminé avec succès !"
