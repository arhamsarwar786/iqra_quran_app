# Android Release Keystore Setup Guide

## Step 1: Generate Keystore

Run this command in your terminal:

```bash
keytool -genkey -v -keystore ~/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
```

You'll be prompted for:
- **Keystore password**: Choose a strong password (remember this!)
- **Key password**: Can be the same as keystore password
- **Name**: Your name or organization name
- **Organizational unit**: Your team/department (can press Enter to skip)
- **Organization**: Your company/organization name
- **City**: Your city
- **State**: Your state/province
- **Country code**: Two-letter country code (e.g., US, UK, PK)

## Step 2: Move Keystore to Project

```bash
mv ~/upload-keystore.jks /Users/as-macbook/Documents/GitHub/iqra_quran_app/android/app/upload-keystore.jks
```

## Step 3: Create key.properties File

Create a file at `/Users/as-macbook/Documents/GitHub/iqra_quran_app/android/key.properties` with:

```properties
storePassword=<your-keystore-password>
keyPassword=<your-key-password>
keyAlias=upload
storeFile=app/upload-keystore.jks
```

Replace `<your-keystore-password>` and `<your-key-password>` with the actual passwords you set.

## Step 4: After Completing Above Steps

Once you've:
1. ✅ Generated the keystore
2. ✅ Moved it to `android/app/upload-keystore.jks`
3. ✅ Created `android/key.properties` with your passwords

Let me know and I'll update your `build.gradle` file to use the keystore for release builds.

## Security Notes

⚠️ **IMPORTANT**: 
- Never commit `key.properties` or your keystore file to Git
- Keep backups of your keystore in a secure location
- If you lose your keystore, you cannot update your app on Play Store
- Store passwords in a password manager

## Alternative: Let Me Set It Up

If you prefer, provide me with:
1. Confirmation that you've created the keystore
2. The keystore file location
3. The alias name you used (if different from "upload")

And I'll configure everything automatically!
