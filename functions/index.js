const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");

admin.initializeApp();

// Helper to check if caller is an admin
const checkAdmin = (context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }
  const allowedEmails = ["mma831770@gmail.com", "abdellahismd@gmail.com"];
  if (context.auth.token.admin !== true &&
      !allowedEmails.includes(context.auth.token.email)) {
    throw new functions.https.HttpsError(
        "permission-denied",
        "You must be an administrator to execute this operation."
    );
  }
};

// Helper for audit logs
const logAdminAction = async (adminUid, adminName, action, targetUid, details) => {
  await admin.firestore().collection("audit_logs").add({
    adminUid,
    adminName,
    action,
    targetUid,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });
};

const LOGIN_RESULT_CODES = new Set([
  "success",
  "account_not_found",
  "invalid_password",
  "invalid_credential",
  "invalid_identifier",
  "account_suspended",
  "account_disabled",
  "network_error",
  "service_unavailable",
  "auth_error",
  "system_error",
  "repeated_failure",
]);

const LOGIN_METHODS = new Set(["email", "phone", "google", "apple", "unknown"]);

const hashValue = (value) => crypto.createHash("sha256").update(value).digest("hex");

const normalizeLoginIdentifier = (value, method) => {
  if (typeof value !== "string") return "";
  const trimmed = value.trim();
  if (!trimmed) return "";
  if (method === "phone") {
    const digits = trimmed.replace(/[^0-9]/g, "");
    return digits ? `phone.${digits}@auth.meraj3i.invalid` : "";
  }
  return trimmed.toLowerCase();
};

const maskLoginIdentifier = (value, method) => {
  if (!value) return null;
  if (method === "phone") return `••••${value.replace(/[^0-9]/g, "").slice(-4)}`;
  const [local, domain] = value.split("@");
  if (!domain) return "••••";
  return `${(local || "").slice(0, 1)}•••@${domain}`;
};

const safeLoginDescription = (result) => ({
  success: "تم تسجيل الدخول بنجاح",
  account_not_found: "الحساب غير موجود أو غير مرتبط بالبيانات المستخدمة",
  invalid_password: "كلمة المرور غير صحيحة",
  invalid_credential: "بيانات تسجيل الدخول غير صحيحة",
  invalid_identifier: "بيانات التعريف غير صحيحة",
  account_suspended: "محاولة دخول لحساب موقوف",
  account_disabled: "الحساب معطل",
  network_error: "فشل مؤقت بسبب الشبكة",
  service_unavailable: "الخدمة غير متاحة مؤقتًا",
  auth_error: "فشل في خدمة المصادقة",
  system_error: "فشل غير متوقع في النظام",
  repeated_failure: "محاولات دخول فاشلة متكررة",
}[result] || "فشل تسجيل الدخول");

const containsSensitiveKey = (value) => {
  if (!value || typeof value !== "object") return false;
  return Object.entries(value).some(([key, nested]) => {
    const normalized = key.toLowerCase();
    return /password|token|secret|apikey|api_key|otp|authorization|privatekey/.test(normalized) ||
      (typeof nested === "object" && containsSensitiveKey(nested));
  });
};

/**
 * Records a sanitized login outcome. Failed attempts are allowed before auth,
 * but only this backend can write them, resolve a known UID, and update support flags.
 */
exports.recordLoginAttempt = functions.https.onCall(async (data, context) => {
  if (!data || containsSensitiveKey(data)) {
    throw new functions.https.HttpsError("invalid-argument", "Sensitive login fields are not accepted.");
  }

  const result = typeof data.result === "string" ? data.result : "";
  const method = typeof data.method === "string" ? data.method : "unknown";
  if (!LOGIN_RESULT_CODES.has(result) || !LOGIN_METHODS.has(method)) {
    throw new functions.https.HttpsError("invalid-argument", "Invalid login event.");
  }
  if (result === "success" && !context.auth) {
    throw new functions.https.HttpsError("unauthenticated", "A successful event requires authentication.");
  }

  const db = admin.firestore();
  const now = admin.firestore.Timestamp.now();
  const identifier = normalizeLoginIdentifier(data.identifier, method);
  const requestIp = context.rawRequest?.ip || "unknown";
  const rateKey = hashValue(`${identifier || "anonymous"}:${requestIp}:${Math.floor(Date.now() / 60000)}`);
  const rateRef = db.collection("login_rate_limits").doc(rateKey);
  const rateSnap = await rateRef.get();
  const rateCount = rateSnap.exists ? Number(rateSnap.data()?.count || 0) : 0;
  if (rateCount >= 30) {
    throw new functions.https.HttpsError("resource-exhausted", "Too many login events.");
  }
  await rateRef.set({count: rateCount + 1, expiresAt: new Date(Date.now() + 15 * 60 * 1000)}, {merge: true});

  let uid = context.auth?.uid || null;
  if (!uid && identifier) {
    try {
      uid = (await admin.auth().getUserByEmail(identifier)).uid;
    } catch (error) {
      if (method === "phone") {
        const phoneSnapshot = await db.collection("users")
            .where("phoneNormalized", "==", data.identifier)
            .limit(1)
            .get();
        uid = phoneSnapshot.empty ? null : phoneSnapshot.docs[0].id;
      }
    }
  }

  const configSnap = await db.collection("admin_settings").doc("login_monitoring").get();
  const config = configSnap.data() || {};
  const supportThreshold = Math.max(2, Math.min(20, Number(config.supportThreshold || 3)));
  const retentionDays = Math.max(7, Math.min(365, Number(config.retentionDays || 90)));
  const event = {
    userId: uid,
    method,
    result,
    reason: safeLoginDescription(result),
    authCode: typeof data.authCode === "string" ? data.authCode.slice(0, 80) : null,
    identifierMasked: maskLoginIdentifier(data.identifier, method),
    platform: typeof data.platform === "string" ? data.platform.slice(0, 30) : null,
    deviceType: typeof data.deviceType === "string" ? data.deviceType.slice(0, 80) : null,
    deviceModel: typeof data.deviceModel === "string" ? data.deviceModel.slice(0, 120) : null,
    osVersion: typeof data.osVersion === "string" ? data.osVersion.slice(0, 40) : null,
    appVersion: typeof data.appVersion === "string" ? data.appVersion.slice(0, 40) : null,
    buildNumber: typeof data.buildNumber === "string" ? data.buildNumber.slice(0, 30) : null,
    consecutiveFailedAttempts: 0,
    needsSupport: false,
    createdAt: now,
    expiresAt: new Date(Date.now() + retentionDays * 24 * 60 * 60 * 1000),
  };

  if (!uid) {
    await db.collection("unlinked_login_attempts").add(event);
    return {linked: false};
  }

  const userRef = db.collection("users").doc(uid);
  const userSnapshot = await userRef.get();
  const userData = userSnapshot.data() || {};
  const previousFailures = Number(userData.failedLoginAttempts || 0);
  const failed = result !== "success";
  const consecutiveFailures = failed ? previousFailures + 1 : 0;
  const needsSupport = failed && consecutiveFailures >= supportThreshold;
  event.consecutiveFailedAttempts = consecutiveFailures;
  event.needsSupport = needsSupport;

  await db.collection("login_attempts").add(event);
  await userRef.set({
    failedLoginAttempts: consecutiveFailures,
    needsSupport,
    lastLoginAttemptAt: now,
    ...(failed ? {
      lastLoginFailureAt: now,
      lastLoginFailureReason: result,
    } : {
      lastLoginSuccessAt: now,
      lastLoginFailureReason: admin.firestore.FieldValue.delete(),
    }),
    loginActivityUpdatedAt: now,
  }, {merge: true});

  if (needsSupport && previousFailures < supportThreshold) {
    await db.collection("admin_notifications").add({
      type: "login_support_needed",
      title: "مستخدم يواجه مشكلة في تسجيل الدخول",
      body: `${userData.name || userData.fullName || "مستخدم"} لديه ${consecutiveFailures} محاولات دخول فاشلة: ${safeLoginDescription(result)}.`,
      userId: uid,
      reason: result,
      failedLoginAttempts: consecutiveFailures,
      lastAttemptAt: now,
      isRead: false,
      createdAt: now,
    });
  }

  return {linked: true, userId: uid, needsSupport, consecutiveFailedAttempts: consecutiveFailures};
});

/**
 * One-time script to set up the initial admins.
 * Can be called securely from a trusted client or initialized via CLI.
 */
exports.setInitialAdmins = functions.https.onCall(async (data, context) => {
  // In a real production app, you might want to remove this or protect it heavily.
  // For now, we only allow specific emails to claim the admin role.
  const allowedEmails = ["mma831770@gmail.com", "abdellahismd@gmail.com"];
  
  if (!context.auth || !context.auth.token.email) {
    throw new functions.https.HttpsError("unauthenticated", "User must be authenticated with email.");
  }

  if (allowedEmails.includes(context.auth.token.email)) {
    await admin.auth().setCustomUserClaims(context.auth.uid, { admin: true });
    return { message: "Admin claim granted successfully." };
  } else {
    throw new functions.https.HttpsError("permission-denied", "Email not authorized to be an admin.");
  }
});

/**
 * Suspend a user account.
 */
exports.suspendUser = functions.https.onCall(async (data, context) => {
  checkAdmin(context);
  const { uid, reason } = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "UID is required");

  await admin.auth().updateUser(uid, { disabled: true });
  await admin.firestore().collection("users").doc(uid).update({ 
    isSuspended: true,
    accountStatus: "suspended",
    status: "suspended",
    suspensionReason: reason || "تم التوقف من قبل الإدارة",
    reason: reason || "تم التوقف من قبل الإدارة",
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    suspensionStartAt: admin.firestore.FieldValue.serverTimestamp(),
    suspensionEndAt: null,
    suspendedBy: "admin",
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await logAdminAction(
    context.auth.uid, 
    context.auth.token.email || "Admin", 
    "SUSPEND_USER", 
    uid, 
    { reason }
  );

  return { message: "User suspended successfully" };
});

/**
 * Reactivate a user account.
 */
exports.reactivateUser = functions.https.onCall(async (data, context) => {
  checkAdmin(context);
  const { uid } = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "UID is required");

  await admin.auth().updateUser(uid, { disabled: false });
  await admin.firestore().collection("users").doc(uid).update({ 
    isSuspended: false,
    accountStatus: "active",
    status: "active",
    suspensionReason: "",
    reason: "",
    suspendedAt: admin.firestore.FieldValue.delete(),
    suspensionStartAt: admin.firestore.FieldValue.delete(),
    suspensionEndAt: admin.firestore.FieldValue.delete(),
    suspendedBy: admin.firestore.FieldValue.delete(),
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  });

  await logAdminAction(
    context.auth.uid, 
    context.auth.token.email || "Admin", 
    "REACTIVATE_USER", 
    uid, 
    {}
  );

  return { message: "User reactivated successfully" };
});

/**
 * Force password change.
 */
exports.requirePasswordChange = functions.https.onCall(async (data, context) => {
  checkAdmin(context);
  const { uid } = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "UID is required");

  // We set a custom claim or a firestore field. Let's use Firestore for UI reactivity.
  await admin.firestore().collection("users").doc(uid).update({
    mustChangePassword: true
  });

  await logAdminAction(
    context.auth.uid, 
    context.auth.token.email || "Admin", 
    "FORCE_PASSWORD_CHANGE", 
    uid, 
    {}
  );

  return { message: "User flagged for password change" };
});

/**
 * Delete a user account (Admin only).
 */
exports.deleteUserAdmin = functions.https.onCall(async (data, context) => {
  checkAdmin(context);
  const { uid } = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "UID is required");
  
  // Protect admins from deleting each other easily
  const userRecord = await admin.auth().getUser(uid);
  if (userRecord.customClaims && userRecord.customClaims.admin) {
    throw new functions.https.HttpsError("permission-denied", "Cannot delete another admin account directly.");
  }

  await admin.auth().deleteUser(uid);
  
  // Delete user document
  await admin.firestore().collection("users").doc(uid).delete();
  // We can also archive their data here if needed based on policies

  await logAdminAction(
    context.auth.uid, 
    context.auth.token.email || "Admin", 
    "DELETE_USER", 
    uid, 
    {}
  );

  return { message: "User deleted successfully" };
});

/**
 * Send Admin Notification via FCM
 */
exports.sendAdminNotification = functions.https.onCall(async (data, context) => {
  checkAdmin(context);
  const { title, body, topic, uid, dataPayload, type, targetAll } = data;
  if (!title || (!targetAll && !uid && !topic)) {
    throw new functions.https.HttpsError(
        "invalid-argument", "title and a notification target are required");
  }

  const db = admin.firestore();
  const targetUsers = [];
  if (uid) {
    const userDoc = await db.collection("users").doc(uid).get();
    if (!userDoc.exists) {
      throw new functions.https.HttpsError("not-found", "User not found");
    }
    targetUsers.push(userDoc);
  } else if (targetAll) {
    const users = await db.collection("users").get();
    targetUsers.push(...users.docs);
  }

  const tokenEntries = [];
  for (const userDoc of targetUsers) {
    const userData = userDoc.data() || {};
    const tokens = new Set();
    if (typeof userData.fcmToken === "string" && userData.fcmToken) {
      tokens.add(userData.fcmToken);
    }
    if (Array.isArray(userData.fcmTokens)) {
      userData.fcmTokens.filter((token) => typeof token === "string" && token)
          .forEach((token) => tokens.add(token));
    }
    for (const token of tokens) {
      tokenEntries.push({token, uid: userDoc.id});
    }
  }
  
  const payload = {
    notification: {
      title: title || "MERAJ3I",
      body: body || "",
    },
    data: {...(dataPayload || {}), type: type || "general"},
  };

  let successCount = 0;
  let failureCount = 0;
  const invalidTokens = [];
  for (let i = 0; i < tokenEntries.length; i += 500) {
    const chunk = tokenEntries.slice(i, i + 500);
    const response = await admin.messaging().sendEachForMulticast({
      tokens: chunk.map((entry) => entry.token),
      ...payload,
    });
    successCount += response.successCount;
    failureCount += response.failureCount;
    response.responses.forEach((result, index) => {
      if (!result.success && ["messaging/registration-token-not-registered",
        "messaging/invalid-registration-token"].includes(result.error?.code)) {
        invalidTokens.push(chunk[index]);
      }
    });
  }

  const notificationData = {
    title: title.toString(),
    body: (body || "").toString(),
    type: type || "general",
    isRead: false,
    sentAt: admin.firestore.FieldValue.serverTimestamp(),
    timestamp: Date.now(),
    targetAll: !!targetAll,
    sentBy: context.auth.uid,
  };
  await db.collection("notifications").add({
    ...notificationData,
    targetUid: uid || null,
    targetTopic: topic || null,
    recipientCount: targetUsers.length,
    successCount,
    failureCount,
  });
  let storedCount = 0;
  for (let i = 0; i < targetUsers.length; i += 400) {
    const batch = db.batch();
    for (const userDoc of targetUsers.slice(i, i + 400)) {
      const ref = userDoc.ref.collection("notifications").doc();
      batch.set(ref, {...notificationData, id: ref.id});
      storedCount++;
    }
    await batch.commit();
  }
  for (const invalid of invalidTokens) {
    await db.collection("users").doc(invalid.uid).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove(invalid.token),
      ...(invalid.token === (targetUsers.find((doc) => doc.id === invalid.uid)
          ?.data()?.fcmToken) ? {fcmToken: admin.firestore.FieldValue.delete()} : {}),
    });
  }

  await logAdminAction(
    context.auth.uid, 
    context.auth.token.email || "Admin", 
    "SEND_NOTIFICATION", 
    uid || topic, 
    { title, body, topic, uid, targetAll, successCount, failureCount, storedCount }
  );

  return {
    message: "Notification sent",
    recipientCount: targetUsers.length,
    tokenCount: tokenEntries.length,
    successCount,
    failureCount,
    invalidTokenCount: invalidTokens.length,
    storedCount,
  };
});

// Server-side moderation keeps the configurable word list private.
exports.moderateReview = functions.firestore
    .document("reviews/{reviewId}")
    .onCreate(async (snapshot) => {
      const review = snapshot.data() || {};
      const text = typeof review.text === "string" ? review.text.trim() : "";
      if (!text) return null;

      const normalize = (value) => value
          .normalize("NFKC")
          .replace(/[\u064B-\u065F\u0670]/g, "")
          .replace(/[إأآ]/g, "ا")
          .replace(/ى/g, "ي")
          .toLowerCase()
          .trim();
      const normalizedText = normalize(text);
      const wordsSnapshot = await admin.firestore()
          .collection("bad_words")
          .where("isActive", "==", true)
          .get();
      const matchedWord = wordsSnapshot.docs
          .map((doc) => normalize(doc.data().word || ""))
          .filter((word) => word.length >= 2)
          .find((word) => {
            const escaped = word.replace(/[.*+?^${}()|[\]\\]/g, "\\$&");
            return new RegExp(`(^|[\\s\\p{P}\\p{S}])${escaped}($|[\\s\\p{P}\\p{S}])`, "iu")
                .test(normalizedText);
          });

      await snapshot.ref.update({
        moderation: matchedWord ? "flagged" : "checked",
        moderationReason: matchedWord ? "matched_configured_word" : null,
        moderationCheckedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
      return null;
    });
