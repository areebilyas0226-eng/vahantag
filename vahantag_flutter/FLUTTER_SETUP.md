# VahanTag Flutter — Complete Setup Guide

## Step 1: Install Flutter (Windows)
1. Download: https://docs.flutter.dev/get-started/install/windows
2. Extract to C:\flutter
3. Add to PATH: C:\flutter\bin
4. Install Android Studio: https://developer.android.com/studio
5. Run: flutter doctor

## Step 2: Open Each App in VS Code

### User App
cd "E:\Vahan Tag\vahantag_flutter\user_app"
flutter pub get
flutter run

### Agent App
cd "E:\Vahan Tag\vahantag_flutter\agent_app"
flutter pub get
flutter run

### Admin App
cd "E:\Vahan Tag\vahantag_flutter\admin_app"
flutter pub get
flutter run

## Step 3: Update API URL
In each app's lib/core/constants/app_constants.dart:
Change: https://vahantag-production.up.railway.app/api
To your actual Railway URL if different

## Step 4: Update Razorpay Key
In user_app/lib/core/constants/app_constants.dart:
Change razorpayKey to your actual live key

## Step 5: Build APK for Testing
flutter build apk --debug

## Step 6: Build for Play Store
flutter build appbundle --release

## App Package Names
User App:   com.vahantag.user
Agent App:  com.vahantag.agent
Admin App:  com.vahantag.admin

## Backend URL
https://vahantag-production.up.railway.app

## All 3 Apps Use Same Backend
Same Railway URL — no changes needed to backend

## Flutter Version Required
Flutter 3.16+ (Dart 3.0+)
