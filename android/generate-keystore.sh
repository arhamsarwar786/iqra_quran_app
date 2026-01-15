#!/bin/bash

# Keystore Generation Script for IQRA Quran App
# This script will generate a production keystore for your Android app

echo "=========================================="
echo "IQRA Quran App - Keystore Generator"
echo "=========================================="
echo ""

# Set keystore details
KEYSTORE_NAME="iqra-release-key.jks"
KEYSTORE_PATH="/Users/as-macbook/Documents/GitHub/iqra_quran_app/android/app/$KEYSTORE_NAME"
KEY_ALIAS="iqra-key-alias"
VALIDITY_DAYS=10000

echo "This script will generate a keystore for production releases."
echo "Location: $KEYSTORE_PATH"
echo "Alias: $KEY_ALIAS"
echo ""
echo "You will be asked to provide:"
echo "  - Keystore password (remember this!)"
echo "  - Key password (can be same as keystore password)"
echo "  - Your name or organization name"
echo "  - Organization details (optional - can press Enter to skip)"
echo ""
read -p "Press Enter to continue or Ctrl+C to cancel..."
echo ""

# Generate the keystore
keytool -genkey -v -keystore "$KEYSTORE_PATH" \
  -storetype JKS \
  -keyalg RSA \
  -keysize 2048 \
  -validity $VALIDITY_DAYS \
  -alias "$KEY_ALIAS"

# Check if keystore was created successfully
if [ -f "$KEYSTORE_PATH" ]; then
    echo ""
    echo "=========================================="
    echo "✅ Keystore created successfully!"
    echo "=========================================="
    echo ""
    echo "Location: $KEYSTORE_PATH"
    echo "Alias: $KEY_ALIAS"
    echo ""
    echo "⚠️  IMPORTANT: Keep this information safe!"
    echo ""
    echo "Next steps:"
    echo "1. Note down your keystore password and key password"
    echo "2. The key.properties file will be created automatically"
    echo "3. Never commit the keystore or key.properties to Git"
    echo ""
    echo "To build release APK:"
    echo "  flutter build apk --release"
    echo ""
    echo "To build release App Bundle:"
    echo "  flutter build appbundle --release"
    echo ""
else
    echo ""
    echo "❌ Failed to create keystore"
    echo "Please check the error messages above"
    exit 1
fi
