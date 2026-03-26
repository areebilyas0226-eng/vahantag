# VahanTag v2 — Complete Setup Guide

## System Overview
- **Backend**: Node.js + PostgreSQL (Neon) + Redis (Upstash)
- **User App**: React Native (Expo) — Play Store
- **Agent App**: React Native (Expo) — Play Store
- **Admin App**: React Native (Expo) — Play Store (or internal)

---

## Step 1: Database Setup (Neon)
1. Create project at neon.tech
2. Copy connection string

## Step 2: Redis Setup (Upstash)
1. Create Redis at upstash.com
2. Copy Redis URL

## Step 3: Backend Setup
```bash
cd backend
cp .env.example .env   # Fill all values
npm install
npm run migrate        # Creates all tables
npm run seed           # Seeds asset categories
npm start
```

## Step 4: Create Admin User
```sql
INSERT INTO admin_users (name, phone) VALUES ('Your Name', '9876543210');
```
Or run via Node:
```bash
node -e "require('dotenv').config(); const {Pool}=require('pg'); const p=new Pool({connectionString:process.env.DATABASE_URL,ssl:{rejectUnauthorized:false}}); p.query(\"INSERT INTO admin_users (name,phone) VALUES ('Admin','YOUR_PHONE') ON CONFLICT DO NOTHING\").then(()=>{console.log('Admin created');process.exit()})"
```

## Step 5: Build Apps

### User App
```bash
cd user-app
cp .env.example .env   # Set EXPO_PUBLIC_API_URL
npm install
npx expo start         # Test locally
eas build --platform android  # Build for Play Store
```

### Agent App
```bash
cd agent-app
npm install
eas build --platform android
```

### Admin App
```bash
cd admin-app
npm install
eas build --platform android
```

---

## App IDs
| App | Package ID | Play Store Listing |
|---|---|---|
| User App | com.vahantag.user | "VahanTag — Smart Asset Protection" |
| Agent App | com.vahantag.agent | "VahanTag Agent" (Internal) |
| Admin App | com.vahantag.admin | Not published (internal only) |

---

## Pricing Structure
| Asset | Activation | Renewal |
|---|---|---|
| Vehicle | ₹499/yr | ₹299/yr |
| Pet | ₹299/yr | ₹199/yr |
| Bag/Electronics/Keys | ₹199/yr | ₹99/yr |

Admin can update prices anytime from Categories screen.

---

## Agent Flow
1. Admin generates QR tag codes: Admin App → Tags → Generate
2. Admin assigns tags to agent: Admin panel assign feature
3. Agent sells sticker + records sale in Agent App
4. Customer activates in User App using tag code
5. Payment collected from customer at activation

---

## Emergency Page URL Format
```
https://vahantag.com/e/VT-XXXX-XXXX
```
Set QR_BASE_URL in backend .env to your domain.
