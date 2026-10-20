# 🚀 Next User — Production Auth & Backend Integration Guide
**Node.js (Express) + MySQL + Firebase Authentication + Flutter Client**

---

## 0. The Big Picture

```
One Person = One Firebase UID = One Backend User
```

Every user must end with: **Full Name + Email + Verified Phone + A Way to Log In (Email/Password or Google OAuth)**.

### Strict Non-Negotiable Rules:
1. **Backend Key is `firebase_uid`**: Never rely on email or phone as primary identity keys.
2. **Verified Token Extraction**: Email and phone must be read from the cryptographically verified Firebase ID token (`req.decoded`), never trusted from the client request body.
3. **Fresh Token on Link**: After linking any credential (phone or email), the Flutter client must immediately call `await getIdToken(true)` so subsequent API requests carry the refreshed claims.
4. **No Unverified Merges**: Never merge backend accounts based on an unverified email.
5. **Strict Profile Gate**: If `is_profile_complete == false`, the client is gated and can only navigate to the Complete Profile screen.

### Matrix: Signup Method $\rightarrow$ Missing Fields $\rightarrow$ Linking Call:
| Signup Method | Complete Profile Must Collect | Firebase Link Method |
| :--- | :--- | :--- |
| **Phone OTP** | Full Name, Email, Password | `AuthService.instance.linkEmailPassword(email, password)` |
| **Email + Password** | Full Name, Phone + SMS OTP | `AuthService.instance.linkPhone(verificationId, code)` |
| **Google OAuth** | Phone + SMS OTP, Password (optional) | `AuthService.instance.linkPhone(verificationId, code)` |

**Unified One-Line Lifecycle Flow:**
$$\text{Login / Signup} \longrightarrow \text{Firebase User} \longrightarrow \text{POST /auth/sync} \longrightarrow \text{missing[]} \longrightarrow \text{Complete Profile (if needed)} \longrightarrow \text{Home}$$

---

## Part A — Firebase Console & Android Setup

### A1. Sign-In Providers
Go to **Firebase Console $\rightarrow$ Authentication $\rightarrow$ Sign-in method**:
* Enable **Email/Password** (Email link optional).
* Enable **Phone**.
* Enable **Google** (Configure support email).
* Keep **Apple** disabled for Android-first launch.

### A2. Android SHA Fingerprints
Run in your terminal from the project root:
```bash
cd android
./gradlew signingReport
```
*(On Windows PowerShell: `.\gradlew.bat signingReport`)*

1. Copy both **SHA-1** and **SHA-256** fingerprints for the `debug` and `release` variants.
2. Paste them into **Firebase Console $\rightarrow$ Project Settings $\rightarrow$ Your Android App $\rightarrow$ Add Fingerprint**.
3. Download the updated `google-services.json` and place it in `android/app/google-services.json`.

### A3. SMS Region Policy
In **Authentication $\rightarrow$ Settings $\rightarrow$ SMS region policy**:
* Allow **Pakistan (+92)** and **United Kingdom (+44)**.

### A4. Phone Numbers for Testing
In **Authentication $\rightarrow$ Sign-in method $\rightarrow$ Phone $\rightarrow$ Phone numbers for testing**:
* Add test numbers with fixed 6-digit verification codes (e.g., `+923001234567` with code `123456`).
* These bypass telecom SMS gateways, saving SMS costs and avoiding daily limits during QA.

### A5. Account Linking Policy
In **Authentication $\rightarrow$ Settings**:
* Ensure **"Link accounts that use the same email"** is selected.

### A6. Firebase Billing Plan
* Upgrade to the **Blaze (Pay-as-you-go) Plan** before client production launch. (The free Spark plan caps SMS at 10 per day).

### A7. Android Manifest Configuration
In `android/app/src/main/AndroidManifest.xml`, ensure on the `<application>` tag:
```xml
android:enableOnBackInvokedCallback="true"
```

---

## Part B — Backend Implementation (Node.js + Express + MySQL)

### B1. Installation & Initialization
```bash
npm install express firebase-admin mysql2 dotenv
```

#### `firebase.js`
```javascript
const admin = require('firebase-admin');

admin.initializeApp({
  credential: admin.credential.cert(require(process.env.FIREBASE_KEY_PATH)),
});

module.exports = admin;
```

---

### B2. MySQL Database Schema
MySQL allows multiple `NULL` values in a `UNIQUE` column, allowing email and phone to remain null until collected and verified.

```sql
CREATE TABLE users (
  id INT AUTO_INCREMENT PRIMARY KEY,
  firebase_uid VARCHAR(128) NOT NULL UNIQUE,
  name VARCHAR(100) NULL,
  email VARCHAR(255) NULL UNIQUE,
  phone VARCHAR(20) NULL UNIQUE,
  fcm_token VARCHAR(255) NULL,
  email_verified TINYINT(1) NOT NULL DEFAULT 0,
  role VARCHAR(20) NOT NULL DEFAULT 'client',
  is_profile_complete TINYINT(1) NOT NULL DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  INDEX idx_firebase_uid (firebase_uid),
  INDEX idx_phone (phone),
  INDEX idx_email (email)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
```

---

### B3. Token Verification Middleware (`auth.middleware.js`)
Reads the Firebase ID token from the standard `Authorization: Bearer <token>` header:

```javascript
const admin = require('./firebase');

exports.verifyToken = async (req, res, next) => {
  const match = (req.headers.authorization || '').match(/^Bearer (.+)$/);
  if (!match) return res.status(401).json({ code: 'NO_TOKEN' });

  try {
    req.decoded = await admin.auth().verifyIdToken(match[1]);
    next();
  } catch (e) {
    return res.status(401).json({ code: 'BAD_TOKEN' });
  }
};
```

---

### B4. Database Repository (`users.repo.js`)

```javascript
const mysql = require('mysql2/promise');

const pool = mysql.createPool({
  host: process.env.DB_HOST,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
  database: process.env.DB_NAME,
  waitForConnections: true,
  connectionLimit: 10,
});

const one = async (sql, params) => (await pool.query(sql, params))[0][0] || null;

exports.findByUid = (uid) => 
  one('SELECT * FROM users WHERE firebase_uid = ?', [uid]);

exports.findByEmail = (email) => 
  one('SELECT * FROM users WHERE email = ?', [email]);

exports.findByPhone = (phone) => 
  one('SELECT * FROM users WHERE phone = ?', [phone]);

exports.create = async ({ uid, name, email, phone, emailVerified }) => {
  await pool.query(
    'INSERT INTO users (firebase_uid, name, email, phone, email_verified, role) VALUES (?, ?, ?, ?, ?, ?)',
    [uid, name || null, email || null, phone || null, emailVerified ? 1 : 0, 'client']
  );
};

// Keep database synchronized with verified claims from token (never overwrite with NULL)
exports.syncFromToken = (uid, { email, phone, emailVerified }) =>
  pool.query(
    'UPDATE users SET email = COALESCE(?, email), phone = COALESCE(?, phone), email_verified = ? WHERE firebase_uid = ?',
    [email || null, phone || null, emailVerified ? 1 : 0, uid]
  );

exports.setName = (uid, name) =>
  pool.query('UPDATE users SET name = ? WHERE firebase_uid = ?', [name, uid]);

exports.setComplete = (uid, complete) =>
  pool.query('UPDATE users SET is_profile_complete = ? WHERE firebase_uid = ?', [complete ? 1 : 0, uid]);

exports.deleteByUid = (uid) =>
  pool.query('DELETE FROM users WHERE firebase_uid = ?', [uid]);

exports.setFcmToken = (uid, token) =>
  pool.query('UPDATE users SET fcm_token = ? WHERE firebase_uid = ?', [token, uid]);
```

---

### B5. Express API Routes (`auth.routes.js`)

```javascript
const router = require('express').Router();
const admin = require('./firebase');
const repo = require('./users.repo');
const { verifyToken } = require('./auth.middleware');

const providersOf = async (uid) =>
  (await admin.auth().getUser(uid)).providerData.map((p) => p.providerId);

function statusOf(user, providers) {
  const missing = [];
  if (!user.name || user.name.trim().length < 2) missing.push('name');
  if (!user.email) missing.push('email');
  if (!user.phone) missing.push('phone');

  const hasLogin = providers.includes('password') || providers.includes('google.com');
  if (!hasLogin) missing.push('password');

  return { missing, is_profile_complete: missing.length === 0 };
}

const fromToken = (decoded) => ({
  email: decoded.email || null,
  phone: decoded.phone_number || null,
  emailVerified: !!decoded.email_verified,
});

async function respond(res, uid) {
  const user = await repo.findByUid(uid);
  const providers = await providersOf(uid);
  const st = statusOf(user, providers);

  await repo.setComplete(uid, st.is_profile_complete);

  return res.json({
    user: {
      id: user.id,
      name: user.name,
      email: user.email,
      phone: user.phone,
      email_verified: !!user.email_verified,
      role: user.role,
    },
    providers,
    ...st,
  });
}

function dbError(e, res) {
  if (e.code === 'ER_DUP_ENTRY') {
    const code = String(e.sqlMessage).includes('phone') ? 'PHONE_EXISTS' : 'EMAIL_EXISTS';
    return res.status(409).json({ code });
  }
  console.error('[Database Error]', e);
  return res.status(500).json({ code: 'SERVER_ERROR' });
}

// ---------------------------------------------------------------------------
// 1) POST /auth/sync (Called after every login and on app boot)
// ---------------------------------------------------------------------------
router.post('/auth/sync', verifyToken, async (req, res) => {
  const d = req.decoded;
  try {
    const existing = await repo.findByUid(d.uid);
    if (existing) {
      await repo.syncFromToken(d.uid, fromToken(d));
    } else {
      if (d.phone_number && (await repo.findByPhone(d.phone_number))) {
        return res.status(409).json({ code: 'PHONE_EXISTS' });
      }
      if (d.email && d.email_verified && (await repo.findByEmail(d.email))) {
        return res.status(409).json({ code: 'EMAIL_EXISTS' });
      }
      await repo.create({ uid: d.uid, name: d.name, ...fromToken(d) });
    }
    if (req.body.fcm_token) {
      await repo.setFcmToken(d.uid, req.body.fcm_token);
    }
    return await respond(res, d.uid);
  } catch (e) {
    return dbError(e, res);
  }
});

// ---------------------------------------------------------------------------
// 2) PUT /users/me (Complete Profile submission)
// ---------------------------------------------------------------------------
router.put('/users/me', verifyToken, async (req, res) => {
  const d = req.decoded;
  const name = String(req.body.name || '').trim();
  if (name.length < 2) return res.status(400).json({ code: 'NAME_REQUIRED' });

  try {
    if (!(await repo.findByUid(d.uid))) {
      return res.status(404).json({ code: 'USER_NOT_FOUND' });
    }
    await repo.syncFromToken(d.uid, fromToken(d));
    await repo.setName(d.uid, name);
    return await respond(res, d.uid);
  } catch (e) {
    return dbError(e, res);
  }
});

// ---------------------------------------------------------------------------
// 3) DELETE /users/me (Account Deletion — Play Store Rule)
// ---------------------------------------------------------------------------
router.delete('/users/me', verifyToken, async (req, res) => {
  const d = req.decoded;
  // Strict check: User must have re-authenticated within the last 5 minutes (300 seconds)
  if (Date.now() / 1000 - d.auth_time > 300) {
    return res.status(401).json({ code: 'REAUTH_REQUIRED' });
  }

  try {
    await repo.deleteByUid(d.uid);
    try {
      await admin.auth().deleteUser(d.uid);
    } catch (e) {
      if (e.code !== 'auth/user-not-found') throw e;
    }
    return res.json({ ok: true });
  } catch (e) {
    console.error('[Account Deletion Error]', e);
    return res.status(500).json({ code: 'SERVER_ERROR' });
  }
});

// ---------------------------------------------------------------------------
// 4) POST /user/fcm-token (Store / Update device push notification token)
// ---------------------------------------------------------------------------
router.post('/user/fcm-token', verifyToken, async (req, res) => {
  const d = req.decoded;
  const fcmToken = String(req.body.fcm_token || '').trim();
  if (!fcmToken) return res.status(400).json({ code: 'FCM_TOKEN_REQUIRED' });

  try {
    await repo.setFcmToken(d.uid, fcmToken);
    return res.json({ ok: true });
  } catch (e) {
    return dbError(e, res);
  }
});

// ---------------------------------------------------------------------------
// 5) DELETE /user/fcm-token (Called on Sign Out to revoke push alerts)
// ---------------------------------------------------------------------------
router.delete('/user/fcm-token', verifyToken, async (req, res) => {
  const d = req.decoded;
  try {
    await repo.setFcmToken(d.uid, null);
    return res.json({ ok: true });
  } catch (e) {
    return dbError(e, res);
  }
});

module.exports = router;
```

#### Mounting in `server.js`:
```javascript
const express = require('express');
const app = express();

app.use(express.json());
app.use(require('./auth.routes'));

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => console.log(`Auth Server running on port ${PORT}`));
```

---

### B6. Backend HTTP Responses Reference Table

| Case | HTTP Status | Response Body |
| :--- | :--- | :--- |
| Missing or invalid Authorization header | `401 Unauthorized` | `{ "code": "NO_TOKEN" }` or `{ "code": "BAD_TOKEN" }` |
| New user, phone already belongs to another user in DB | `409 Conflict` | `{ "code": "PHONE_EXISTS" }` |
| New user, verified email already belongs to another user | `409 Conflict` | `{ "code": "EMAIL_EXISTS" }` |
| Name shorter than 2 characters on PUT `/users/me` | `400 Bad Request` | `{ "code": "NAME_REQUIRED" }` |
| Missing token on POST `/user/fcm-token` | `400 Bad Request` | `{ "code": "FCM_TOKEN_REQUIRED" }` |
| DELETE `/users/me` with login older than 5 minutes | `401 Unauthorized` | `{ "code": "REAUTH_REQUIRED" }` |
| Successful sync, profile update, or FCM update | `200 OK` | `{ "user": {...}, "providers": [...], "missing": [...], "is_profile_complete": bool }` or `{ "ok": true }` |

---

### B7. Verification with cURL
Print your ID token in debug mode from Flutter, then test your endpoint:
```bash
curl -X POST http://localhost:3000/auth/sync \
  -H "Authorization: Bearer YOUR_FIREBASE_ID_TOKEN"
```

---

## Part C — Flutter Client Architecture

The Flutter client contains dedicated, modular services designed to match this architecture:

### 1. `lib/services/api_client.dart`
* Manages all HTTP traffic via `Dio`.
* Implements `_AuthInterceptor` that automatically injects `Authorization: Bearer <id_token>`.
* On any `401 Unauthorized`, automatically requests `await user.getIdToken(true)` and replays the original failed request once.

### 2. `lib/services/auth_service.dart`
* **Email:** `signInWithEmail`, `signUpWithEmail`, `sendPasswordReset`, `sendEmailVerification`.
* **Phone OTP:** `verifyPhone({linking: false/true, onCodeSent, onAutoDone, onError})`, `verifyOtpAndSignIn`, `linkPhone`.
* **Google OAuth:** `signInWithGoogle()`, catching `account-exists-with-different-credential`, storing `pendingCredential`, and calling `linkPendingIfAny()`.
* **Credential Linking:** `linkEmailPassword` (for phone users), `linkPhone` (for email/social users).
* **Re-authentication:** `reauthWithPassword`, `reauthWithGoogle`, `reauthWithPhone` for safe account deletion.

### 3. `lib/services/auth_errors.dart`
* `readableError(Object e)` centralized error translation mapping Firebase codes and Backend codes (`PHONE_EXISTS`, `EMAIL_EXISTS`, `NAME_REQUIRED`, `REAUTH_REQUIRED`) to helpful client messages.

### 4. `lib/services/backend_sync_service.dart`
* Calls `POST /auth/sync` on app startup and post-login.
* Inspects `is_profile_complete` and `missing[]`.
* If incomplete, redirects client to `CompleteProfileView`.

---

## Summary of Checklist for Deployment
- [x] Android `enableOnBackInvokedCallback="true"` verified in `AndroidManifest.xml`
- [x] SHA-1 & SHA-256 added to Firebase Console
- [x] `google-services.json` placed in `android/app/`
- [x] Pakistan (+92) and UK (+44) enabled in SMS Region Policy
- [x] MySQL schema deployed on backend
- [x] Node.js service running with `firebase-admin` service account credentials
- [x] Flutter app using `ApiClient`, `AuthService`, and `readableError`
