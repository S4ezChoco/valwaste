# Firebase Setup Guide - Fix Registration Issue

## 🚨 Current Issue
Users are being created in Firebase Auth but NOT in Firestore, causing login failures.

## 🔧 Quick Fix Steps

### Step 1: Check Firebase Console
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Select your project: `valwaste-89930`
3. Go to **Firestore Database** in the left sidebar

### Step 2: Enable Firestore Database
1. If you see "Create database", click it
2. Choose **"Start in test mode"** (for development)
3. Select a location (choose closest to your region)
4. Click **"Done"**

### Step 3: Set Firestore Security Rules
1. In Firestore Database, go to **"Rules"** tab
2. Replace the rules with this:

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Allow users to read/write their own data
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Allow all operations for testing (remove this in production)
    match /{document=**} {
      allow read, write: if true;
    }
  }
}
```

3. Click **"Publish"**

### Step 4: Test the App
1. Run the app again
2. Click **"Test Firebase Connection"** button
3. Click **"Create Test User in Firestore"** button
4. Try to register a new account

## 🔍 Debug Steps

### If Test User Creation Fails:
1. Check Firebase Console → Firestore Database
2. Make sure database is created and in test mode
3. Check the Rules tab - should allow all operations

### If Registration Still Fails:
1. Check the console logs for specific error messages
2. Make sure you have internet connection
3. Try the debug buttons in the app

## 📱 Alternative: Manual User Creation

If registration still doesn't work, you can manually create a user:

1. **Create user in Firebase Auth:**
   - Go to Firebase Console → Authentication → Users
   - Click "Add user"
   - Enter email and password

2. **Create user in Firestore:**
   - Go to Firebase Console → Firestore Database
   - Click "Start collection" → "users"
   - Document ID: (use the UID from Auth)
   - Add fields:
     ```
     name: "Test User"
     email: "test@example.com"
     phone: "1234567890"
     address: "Test Address"
     barangay: "Valenzuela City"
     createdAt: (current timestamp)
     updatedAt: (current timestamp)
     ```

## ✅ Verification

After setup, you should be able to:
- ✅ Create test users in Firestore
- ✅ Register new accounts (saved to both Auth and Firestore)
- ✅ Login with registered accounts
- ✅ See user data in both Firebase Auth and Firestore

## 🆘 Still Having Issues?

1. **Check Console Logs:** Look for specific error messages
2. **Test Firestore Connection:** Use the debug buttons
3. **Verify Firebase Project:** Make sure you're using the correct project
4. **Check Internet:** Ensure stable internet connection

## 📞 Quick Support

If you're still having issues, please share:
1. The console logs when trying to register
2. Screenshot of your Firestore Database page
3. Screenshot of your Firestore Rules page


