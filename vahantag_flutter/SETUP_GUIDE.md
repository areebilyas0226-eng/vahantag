# VahanTag Flutter — Setup Guide

## Step 1: Install Flutter
1. Download: https://docs.flutter.dev/get-started/install/windows
2. Extract to C:\flutter
3. Add to PATH: C:\flutter\bin
4. Run: flutter doctor

## Step 2: Install Android Studio
1. Download: https://developer.android.com/studio
2. Install Android SDK
3. Run: flutter doctor --android-licenses

## Step 3: Setup Each App
For EACH app (user_app, agent_app, admin_app):

```
cd user_app
flutter pub get
flutter run
```

## Step 4: Build APK for Testing
```
flutter build apk --debug
```

## Step 5: Build for Play Store
```
flutter build appbundle --release
```

## App API URL
All apps connect to: https://vahantag-production.up.railway.app/api

## Package Names
- User App: com.vahantag.user
- Agent App: com.vahantag.agent
- Admin App: com.vahantag.admin

## Android Permissions needed
Add to AndroidManifest.xml:
<uses-permission android:name="android.permission.INTERNET"/>
<uses-permission android:name="android.permission.CAMERA"/>
<uses-permission android:name="android.permission.CALL_PHONE"/>

## Razorpay Setup
In user_app/android/app/build.gradle add:
implementation 'com.razorpay:checkout:1.6.26'
