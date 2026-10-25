const functions = require("firebase-functions");
const admin = require("firebase-admin");
const crypto = require("crypto");
const {countCorrectAnswers, improvementOverBest} =
  require("./honor_scoring");

admin.initializeApp();

const ROOT_ADMIN_EMAILS = ["mma831770@gmail.com", "abdellahismd@gmail.com"];
const ADMIN_PERMISSION_IDS = new Set([
  "dashboard.view", "analytics.view", "reports.view",
  "books.view", "books.create", "books.update", "books.delete",
  "categories.view", "categories.manage", "grades.view", "grades.manage",
  "subjects.view", "subjects.manage", "lessons.view", "lessons.manage",
  "questions.view", "questions.manage", "quizzes.view", "quizzes.manage",
  "results.view", "results.manage", "honor.view", "honor.manage",
  "users.view", "users.export", "users.update", "users.suspend", "users.delete",
  "roles.manage", "notifications.view", "notifications.manage",
  "news.view", "news.manage", "announcements.view",
  "announcements.manage", "reviews.view", "reviews.moderate",
  "reviews.delete", "bad_words.manage", "feature_flags.manage",
  "releases.manage", "settings.manage", "storage.view", "storage.manage",
  "support.view", "support.manage", "system_health.view", "security.view",
  "activity.view", "errors.view",
]);

const isRootAdmin = (auth) => auth &&
  auth.token?.email_verified === true &&
  ROOT_ADMIN_EMAILS.includes(String(auth.token.email || "").toLowerCase());

const requireRootAdmin = async (context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "Authentication is required."
    );
  }
  if (!isRootAdmin(context.auth)) {
    await logAdminAction(
        context.auth.uid,
        context.auth.token.email || context.auth.uid,
        "DENIED_ADMIN_ACCOUNT_MANAGEMENT",
        null,
        {}
    );
    throw new functions.https.HttpsError(
        "permission-denied",
        "Only a trusted root administrator can manage administrator accounts."
    );
  }
};

const requireRecentRootAdmin = async (context) => {
  await requireRootAdmin(context);
  const authTime = Number(context.auth.token.auth_time);
  const ageSeconds = Math.floor(Date.now() / 1000) - authTime;
  if (!Number.isFinite(authTime) || ageSeconds < 0 || ageSeconds > 300) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "RECENT_AUTH_REQUIRED"
    );
  }
};

// Read the live profile on each call so permission revocations take effect
// without waiting for an ID-token refresh.
const checkAdmin = async (context, permission) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }
  if (isRootAdmin(context.auth)) return;
  if (!ADMIN_PERMISSION_IDS.has(permission)) {
    throw new functions.https.HttpsError(
        "internal",
        "A valid permission is required for this administrative operation."
    );
  }

  if (context.auth.token.email_verified === true) {
    const profile = await admin.firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();
    const data = profile.data() || {};
    if (data.isAdmin === true &&
        data.adminActive === true &&
        Array.isArray(data.adminPermissions) &&
        data.adminPermissions.includes(permission)) return;
  }

  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || context.auth.uid,
      "DENIED_ADMIN_OPERATION",
      null,
      {permission}
  );
  throw new functions.https.HttpsError(
      "permission-denied",
      "You must be an administrator to execute this operation."
  );
};

const checkAnyAdmin = async (context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
        "unauthenticated",
        "The function must be called while authenticated."
    );
  }
  if (isRootAdmin(context.auth)) return;
  if (context.auth.token.email_verified === true) {
    const profile = await admin.firestore()
        .collection("users")
        .doc(context.auth.uid)
        .get();
    const data = profile.data() || {};
    if (data.isAdmin === true &&
        data.adminActive === true &&
        Array.isArray(data.adminPermissions) &&
        data.adminPermissions.length > 0) return;
  }
  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || context.auth.uid,
      "DENIED_ACTIVITY_RECORD",
      null,
      {}
  );
  throw new functions.https.HttpsError(
      "permission-denied",
      "You must have an active administrator permission to record activity."
  );
};

// Helper for audit logs
const logAdminAction = async (adminUid, adminName, action, targetUid, details) => {
  const record = {
    adminUid,
    adminName,
    action,
    targetUid,
    details,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  };
  const db = admin.firestore();
  const batch = db.batch();
  batch.create(db.collection("audit_logs").doc(), record);
  batch.create(db.collection("admin_audit_logs").doc(), record);
  await batch.commit();
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
 * Records a sanitized login outcome.
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
 */
exports.setInitialAdmins = functions.https.onCall(async (data, context) => {
  void data;
  await requireRootAdmin(context);
  return {message: "Trusted root administrator access is active."};
});

exports.recordAdminActivity = functions.https.onCall(async (data, context) => {
  await checkAnyAdmin(context);
  const allowedKeys = [
    "action", "targetType", "targetId", "targetName", "extra",
  ];
  if (!data || Object.keys(data).some((key) => !allowedKeys.includes(key)) ||
      typeof data.action !== "string" || !data.action.trim() ||
      data.action.length > 160 ||
      (data.targetType != null &&
        (typeof data.targetType !== "string" || data.targetType.length > 80)) ||
      (data.targetId != null &&
        (typeof data.targetId !== "string" || data.targetId.length > 200)) ||
      (data.targetName != null &&
        (typeof data.targetName !== "string" || data.targetName.length > 160)) ||
      (data.extra != null &&
        (typeof data.extra !== "object" || Array.isArray(data.extra) ||
         Object.keys(data.extra).length > 20 || containsSensitiveKey(data.extra)))) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "The activity record contains invalid or sensitive fields."
    );
  }
  const db = admin.firestore();
  await db.collection("admin_activity").add({
    adminId: context.auth.uid,
    adminEmail: context.auth.token.email || "unknown",
    action: data.action.trim(),
    targetType: data.targetType || null,
    targetId: data.targetId || null,
    targetName: data.targetName || null,
    deviceInfo: "لوحة الإدارة",
    platform: "Admin",
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    success: true,
    description: data.action.trim(),
    extra: data.extra || {},
  });
  const profileRef = db.collection("users").doc(context.auth.uid);
  const profile = await profileRef.get();
  if (profile.exists) {
    await profileRef.update({
      lastAdminActivityAt: admin.firestore.FieldValue.serverTimestamp(),
    });
  }
  return {recorded: true};
});

exports.getAdminDashboardStats = functions.https.onCall(async (data, context) => {
  const scope = data?.scope;
  if (scope !== "dashboard" && scope !== "analytics") {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid dashboard statistics scope is required."
    );
  }
  await checkAdmin(context, scope === "analytics" ?
    "analytics.view" : "dashboard.view");
  const db = admin.firestore();
  const count = async (collection, filters = []) => {
    let query = db.collection(collection);
    for (const [field, operator, value] of filters) {
      query = query.where(field, operator, value);
    }
    try {
      const snapshot = await query.count().get();
      return snapshot.data().count || 0;
    } catch (error) {
      console.error("Admin dashboard count failed.", {
        collection,
        filters,
        code: error.code || null,
        message: error.message,
      });
      throw error;
    }
  };
  const countPublishedQuizzes = async () => {
    try {
      const snapshot = await db.collection("quizzes")
          .where("kind", "==", "quiz")
          .get();
      return snapshot.docs.filter((document) =>
        document.data().status === "published"
      ).length;
    } catch (error) {
      console.error("Admin published quiz count failed.", {
        collection: "quizzes",
        code: error.code || null,
        message: error.message,
      });
      throw error;
    }
  };
  const [
    users, activeUsers, books, quizzes, lessons, grades, subjects,
    referenceCategories, solutions, swedd, sweddBooks,
  ] = await Promise.all([
    count("users"),
    count("users", [["isActive", "==", true]]),
    count("books"),
    countPublishedQuizzes(),
    count("lessons"),
    count("grades"),
    count("subjects"),
    count("reference_categories"),
    count("solutions"),
    count("swedd"),
    count("swedd_books"),
  ]);
  return {
    users, activeUsers, books, quizzes, lessons, grades, subjects,
    referenceCategories, solutions, swedd, sweddBooks,
  };
});

// ─────────────────────────────────────────────────────────────────────────────
// User Management Functions (Admin Only)
// ─────────────────────────────────────────────────────────────────────────────

const PROTECTED_EMAILS = ["mma831770@gmail.com", "abdellahismd@gmail.com"];
const validateAdminAssignment = (data) => {
  const role = typeof data.role === "string" ? data.role.trim() : "";
  const roleName = typeof data.roleName === "string" ? data.roleName.trim() : "";
  const permissions = data.permissions;
  if (!/^[a-z][a-z0-9_-]{1,39}$/.test(role) ||
      !roleName || roleName.length > 80 ||
      !Array.isArray(permissions) || permissions.length === 0 ||
      permissions.length > ADMIN_PERMISSION_IDS.size ||
      permissions.some((permission) =>
        typeof permission !== "string" ||
        !ADMIN_PERMISSION_IDS.has(permission) ||
        permission === "roles.manage") ||
      new Set(permissions).size !== permissions.length) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A valid role and a unique, non-empty set of assignable permissions are required."
    );
  }
  return {role, roleName, permissions};
};

exports.manageAdminUser = functions.https.onCall(async (data, context) => {
  await requireRecentRootAdmin(context);
  if (!data || typeof data.action !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Action is required.");
  }

  const db = admin.firestore();
  const actorUid = context.auth.uid;
  const actorName = context.auth.token.email || actorUid;
  const action = data.action;

  if (action === "create" || action === "grantExisting") {
    const email = typeof data.email === "string" ?
      data.email.trim().toLowerCase() : "";
    const fullName = typeof data.fullName === "string" ?
      data.fullName.trim() : "";
    if (!/^[^@\s]+@[^@\s]+\.[^@\s]+$/.test(email) ||
        email.length > 254 || fullName.length > 100) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "A valid email and a name of at most 100 characters are required."
      );
    }
    const assignment = validateAdminAssignment(data);
    let userRecord;
    if (action === "create") {
      const existingProfile = await db.collection("users")
          .where("email", "==", email).limit(1).get();
      if (!existingProfile.empty) {
        throw new functions.https.HttpsError(
            "already-exists",
            "A profile already uses this email. Grant the existing account instead."
        );
      }
      try {
        await admin.auth().getUserByEmail(email);
        throw new functions.https.HttpsError(
            "already-exists",
            "An authentication account already uses this email."
        );
      } catch (error) {
        if (error.code !== "auth/user-not-found") throw error;
      }
      try {
        userRecord = await admin.auth().createUser({
          email,
          emailVerified: false,
          displayName: fullName || undefined,
          disabled: false,
        });
      } catch (error) {
        if (error.code === "auth/email-already-exists") {
          throw new functions.https.HttpsError(
              "already-exists",
              "An authentication account already uses this email."
          );
        }
        throw error;
      }
    } else {
      try {
        userRecord = await admin.auth().getUserByEmail(email);
      } catch (error) {
        if (error.code === "auth/user-not-found") {
          throw new functions.https.HttpsError(
              "not-found",
              "No existing authentication account uses this email."
          );
        }
        throw error;
      }
      const existingProfile = await db.collection("users")
          .doc(userRecord.uid).get();
      if (existingProfile.data()?.isAdmin === true) {
        throw new functions.https.HttpsError(
            "already-exists",
            "This account is already an administrator."
        );
      }
    }

    const profileRef = db.collection("users").doc(userRecord.uid);
    try {
      await profileRef.set({
        uid: userRecord.uid,
        email,
        ...(fullName ? {fullName} : {}),
        isAdmin: true,
        adminActive: true,
        role: assignment.role,
        adminRoleName: assignment.roleName,
        adminPermissions: assignment.permissions,
        adminCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminCreatedBy: actorUid,
        adminUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminUpdatedBy: actorUid,
      }, {merge: true});
    } catch (error) {
      if (action === "create") {
        try {
          await admin.auth().deleteUser(userRecord.uid);
        } catch (cleanupError) {
          console.error("Failed to clean up an unassigned admin account.", {
            uid: userRecord.uid,
            error: cleanupError.message,
          });
        }
      }
      throw error;
    }

    await logAdminAction(actorUid, actorName,
        action === "create" ? "CREATE_ADMIN" : "GRANT_ADMIN",
        userRecord.uid, {
          email,
          role: assignment.role,
          permissions: assignment.permissions,
        });
    return {uid: userRecord.uid, email};
  }

  if (typeof data.uid !== "string" || !data.uid.trim()) {
    throw new functions.https.HttpsError("invalid-argument", "A target UID is required.");
  }
  const uid = data.uid.trim();
  let targetRecord;
  try {
    targetRecord = await admin.auth().getUser(uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", "Administrator account not found.");
    }
    throw error;
  }
  if (PROTECTED_EMAILS.includes(String(targetRecord.email || "").toLowerCase())) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Trusted root administrator accounts cannot be changed here."
    );
  }
  const profileRef = db.collection("users").doc(uid);
  const profile = await profileRef.get();
  const profileData = profile.data() || {};
  if (profileData.isAdmin !== true) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "The target account is not an administrator."
    );
  }

  if (action === "update") {
    const assignment = validateAdminAssignment(data);
    const fullName = typeof data.fullName === "string" ?
      data.fullName.trim() : "";
    if (fullName.length > 100) {
      throw new functions.https.HttpsError(
          "invalid-argument",
          "The name must be at most 100 characters."
      );
    }
    await profileRef.update({
      ...(fullName ? {fullName} : {}),
      role: assignment.role,
      adminRoleName: assignment.roleName,
      adminPermissions: assignment.permissions,
      adminUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminUpdatedBy: actorUid,
    });
    await logAdminAction(actorUid, actorName, "UPDATE_ADMIN_PERMISSIONS",
        uid, {
          previousRole: profileData.role || null,
          role: assignment.role,
          previousPermissions: profileData.adminPermissions || [],
          permissions: assignment.permissions,
        });
    return {uid};
  }

  if (action === "setActive") {
    if (typeof data.active !== "boolean") {
      throw new functions.https.HttpsError("invalid-argument", "Active status must be boolean.");
    }
    await profileRef.update({
      adminActive: data.active,
      adminUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminUpdatedBy: actorUid,
    });
    await logAdminAction(actorUid, actorName,
        data.active ? "ENABLE_ADMIN" : "DISABLE_ADMIN",
        uid, {previousActive: profileData.adminActive === true, active: data.active});
    if (!data.active) await admin.auth().revokeRefreshTokens(uid);
    return {uid, active: data.active};
  }

  if (action === "revoke") {
    await profileRef.update({
      isAdmin: false,
      adminActive: false,
      adminPermissions: [],
      role: admin.firestore.FieldValue.delete(),
      adminRoleName: admin.firestore.FieldValue.delete(),
      adminUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
      adminUpdatedBy: actorUid,
    });
    await logAdminAction(actorUid, actorName, "REVOKE_ADMIN", uid, {
      previousRole: profileData.role || null,
      previousPermissions: profileData.adminPermissions || [],
    });
    await admin.auth().revokeRefreshTokens(uid);
    return {uid, revoked: true};
  }

  throw new functions.https.HttpsError("invalid-argument", "Unsupported action.");
});

exports.manageAdminRole = functions.https.onCall(async (data, context) => {
  await requireRecentRootAdmin(context);
  if (!data || !["create", "update", "delete"].includes(data.action)) {
    throw new functions.https.HttpsError("invalid-argument", "Unsupported role action.");
  }
  const roleId = typeof data.roleId === "string" ? data.roleId.trim() : "";
  if (!/^custom_[a-z0-9_]{2,38}$/.test(roleId)) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "Custom role IDs must use the custom_ prefix and lowercase letters, numbers, or underscores."
    );
  }

  const db = admin.firestore();
  const roleRef = db.collection("admin_roles").doc(roleId);
  const roleSnapshot = await roleRef.get();
  if (data.action === "create" && roleSnapshot.exists) {
    throw new functions.https.HttpsError("already-exists", "This role ID already exists.");
  }
  if (data.action !== "create" && !roleSnapshot.exists) {
    throw new functions.https.HttpsError("not-found", "Custom role not found.");
  }

  if (data.action === "delete") {
    const assignedAdmins = await db.collection("users")
        .where("role", "==", roleId)
        .get();
    if (assignedAdmins.docs.some((document) =>
      document.data().isAdmin === true)) {
      throw new functions.https.HttpsError(
          "failed-precondition",
          "Reassign every administrator using this role before deleting it."
      );
    }
    await roleRef.delete();
    await logAdminAction(
        context.auth.uid,
        context.auth.token.email || context.auth.uid,
        "DELETE_ADMIN_ROLE",
        roleId,
        {}
    );
    return {roleId, deleted: true};
  }

  const roleName = typeof data.roleName === "string" ? data.roleName.trim() : "";
  const permissions = data.permissions;
  if (!roleName || roleName.length > 80 ||
      !Array.isArray(permissions) || permissions.length === 0 ||
      permissions.length > ADMIN_PERMISSION_IDS.size ||
      permissions.some((permission) =>
        typeof permission !== "string" ||
        !ADMIN_PERMISSION_IDS.has(permission) ||
        permission === "roles.manage") ||
      new Set(permissions).size !== permissions.length) {
    throw new functions.https.HttpsError(
        "invalid-argument",
        "A role name and a unique, non-empty set of assignable permissions are required."
    );
  }
  const now = admin.firestore.FieldValue.serverTimestamp();
  const roleRecord = {
    roleId,
    name: roleName,
    permissions,
    updatedAt: now,
    updatedBy: context.auth.uid,
    ...(data.action === "create" ? {
      createdAt: now,
      createdBy: context.auth.uid,
    } : {}),
  };
  await roleRef.set(roleRecord, {merge: true});

  if (data.action === "update") {
    const assignedAdmins = await db.collection("users")
        .where("role", "==", roleId)
        .get();
    let batch = db.batch();
    let writes = 0;
    for (const document of assignedAdmins.docs) {
      if (document.data().isAdmin !== true) continue;
      batch.update(document.ref, {
        adminPermissions: permissions,
        adminRoleName: roleName,
        adminUpdatedAt: admin.firestore.FieldValue.serverTimestamp(),
        adminUpdatedBy: context.auth.uid,
      });
      writes++;
      if (writes >= 450) {
        await batch.commit();
        batch = db.batch();
        writes = 0;
      }
    }
    if (writes > 0) await batch.commit();
  }

  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || context.auth.uid,
      data.action === "create" ? "CREATE_ADMIN_ROLE" : "UPDATE_ADMIN_ROLE",
      roleId,
      {
        roleName,
        permissions,
        previousPermissions: roleSnapshot.data()?.permissions || [],
      }
  );
  return {roleId, updated: true};
});

/**
 * Delete all subcollections of a Firestore document.
 */
const deleteSubcollections = async (docRef) => {
  const subcollections = await docRef.listCollections();
  for (const sub of subcollections) {
    const docs = await sub.get();
    let batch = admin.firestore().batch();
    let count = 0;
    for (const doc of docs.docs) {
      batch.delete(doc.ref);
      count++;
      if (count >= 400) {
        await batch.commit();
        batch = admin.firestore().batch();
        count = 0;
      }
    }
    if (count > 0) await batch.commit();
  }
};

const rejectAdministratorTarget = async (uid) => {
  const profile = await admin.firestore().collection("users").doc(uid).get();
  if (profile.data()?.isAdmin === true) {
    throw new functions.https.HttpsError(
        "failed-precondition",
        "Administrator accounts must be changed through administrator management."
    );
  }
  return profile;
};

/**
 * Suspend a user account.
 * - Disables in Firebase Authentication (blocks all new sessions)
 * - Updates Firestore with suspension details
 * - Records audit log
 */
exports.suspendUser = functions.https.onCall(async (data, context) => {
  await checkAdmin(context, "users.suspend");
  const { uid, reason, note } = data;
  if (!uid || typeof uid !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Valid UID is required");
  }
  await rejectAdministratorTarget(uid);

  // Verify user exists
  let userRecord;
  try {
    userRecord = await admin.auth().getUser(uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", "User not found in Firebase Auth");
    }
    throw error;
  }

  // Protect admin accounts
  if (PROTECTED_EMAILS.includes(userRecord.email)) {
    throw new functions.https.HttpsError("permission-denied", "Cannot suspend a protected admin account.");
  }

  // Disable in Firebase Authentication
  await admin.auth().updateUser(uid, { disabled: true });

  // Update Firestore
  await admin.firestore().collection("users").doc(uid).set({
    isSuspended: true,
    accountStatus: "suspended",
    status: "suspended",
    suspensionReason: reason || "تم الإيقاف من قبل الإدارة",
    reason: reason || "تم الإيقاف من قبل الإدارة",
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    suspensionStartAt: admin.firestore.FieldValue.serverTimestamp(),
    suspensionEndAt: null,
    suspendedBy: context.auth.uid,
    suspendedByEmail: context.auth.token.email || "Admin",
    adminNote: note || null,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || "Admin",
      "SUSPEND_USER",
      uid,
      { reason, note, email: userRecord.email }
  );

  return { success: true, message: "User suspended successfully" };
});

/**
 * Reactivate a suspended user account.
 * - Re-enables in Firebase Authentication
 * - Clears suspension fields in Firestore
 * - Records audit log
 */
exports.reactivateUser = functions.https.onCall(async (data, context) => {
  await checkAdmin(context, "users.suspend");
  const { uid } = data;
  if (!uid || typeof uid !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Valid UID is required");
  }
  await rejectAdministratorTarget(uid);

  // Verify user exists
  let userRecord;
  try {
    userRecord = await admin.auth().getUser(uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      throw new functions.https.HttpsError("not-found", "User not found in Firebase Auth");
    }
    throw error;
  }

  // Re-enable in Firebase Authentication (only if disabled)
  if (userRecord.disabled) {
    await admin.auth().updateUser(uid, { disabled: false });
  }

  // Clear suspension in Firestore
  const db = admin.firestore();
  await db.collection("users").doc(uid).set({
    isSuspended: false,
    isBanned: false,
    accountStatus: "active",
    status: "active",
    suspensionReason: admin.firestore.FieldValue.delete(),
    reason: admin.firestore.FieldValue.delete(),
    suspendedAt: admin.firestore.FieldValue.delete(),
    suspensionStartAt: admin.firestore.FieldValue.delete(),
    suspensionEndAt: admin.firestore.FieldValue.delete(),
    suspendedBy: admin.firestore.FieldValue.delete(),
    suspendedByEmail: admin.firestore.FieldValue.delete(),
    adminNote: admin.firestore.FieldValue.delete(),
    reactivatedAt: admin.firestore.FieldValue.serverTimestamp(),
    reactivatedBy: context.auth.uid,
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
  }, { merge: true });

  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || "Admin",
      "REACTIVATE_USER",
      uid,
      { email: userRecord.email }
  );

  return { success: true, message: "User reactivated successfully" };
});

/**
 * Force password change for a user.
 */
exports.requirePasswordChange = functions.https.onCall(async (data, context) => {
  await checkAdmin(context, "users.update");
  const { uid } = data;
  if (!uid) throw new functions.https.HttpsError("invalid-argument", "UID is required");
  await rejectAdministratorTarget(uid);

  await admin.firestore().collection("users").doc(uid).update({
    mustChangePassword: true,
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
 * Delete a user account completely (Admin only).
 *
 * Step 1: Verify admin + target user exists in Auth
 * Step 2: Protect admin accounts from deletion
 * Step 3: Mark Firestore doc as pendingDeletion (blocks re-creation)
 * Step 4: Disable Auth account (immediately invalidates all sessions)
 * Step 5: Delete Firestore subcollections (notifications, etc.)
 * Step 6: Delete main Firestore document
 * Step 7: Delete Firebase Auth account
 * Step 8: Write final audit log
 */
exports.deleteUserAdmin = functions.https.onCall(async (data, context) => {
  await checkAdmin(context, "users.delete");
  const { uid } = data;
  if (!uid || typeof uid !== "string") {
    throw new functions.https.HttpsError("invalid-argument", "Valid UID is required");
  }

  const db = admin.firestore();
  const userRef = db.collection("users").doc(uid);
  const existingProfile = await rejectAdministratorTarget(uid);

  // Step 1: Verify target user in Auth
  let userRecord = null;
  try {
    userRecord = await admin.auth().getUser(uid);
  } catch (error) {
    if (error.code === "auth/user-not-found") {
      // Auth already deleted — clean up Firestore if doc still exists
      const snap = existingProfile;
      if (snap.exists) {
        await deleteSubcollections(userRef);
        await userRef.delete();
      }
      await logAdminAction(
          context.auth.uid,
          context.auth.token.email || "Admin",
          "DELETE_USER_AUTH_ALREADY_GONE",
          uid,
          { note: "Auth was already deleted. Cleaned up Firestore." }
      );
      return { success: true, message: "Auth was already deleted. Firestore cleaned up.", uid };
    }
    throw error;
  }

  // Step 2: Protect admin accounts
  if (userRecord.customClaims && userRecord.customClaims.admin) {
    throw new functions.https.HttpsError("permission-denied", "Cannot delete an admin account.");
  }
  if (userRecord.email &&
      PROTECTED_EMAILS.includes(userRecord.email.toLowerCase())) {
    throw new functions.https.HttpsError("permission-denied", "Cannot delete a protected account.");
  }

  // Step 3: Mark as pendingDeletion to prevent ensureUserDocument re-creating the doc
  try {
    await userRef.set({
      pendingDeletion: true,
      deletionRequestedAt: admin.firestore.FieldValue.serverTimestamp(),
      deletionRequestedBy: context.auth.uid,
    }, { merge: true });
  } catch (_) { /* doc may not exist in Firestore — continue */ }

  // Step 4: Disable in Auth to invalidate all active sessions immediately
  try {
    await admin.auth().updateUser(uid, { disabled: true });
  } catch (e) {
    if (e.code !== "auth/user-not-found") throw e;
  }
  // Step 5 & 6: Delete Firestore subcollections then main doc
  const snap = await userRef.get();
  if (snap.exists) {
    await deleteSubcollections(userRef);
    await userRef.delete();
  }

  // Step 7: Delete Firebase Auth account
  try {
    await admin.auth().deleteUser(uid);
  } catch (authError) {
    if (authError.code !== "auth/user-not-found") {
      await logAdminAction(
          context.auth.uid,
          context.auth.token.email || "Admin",
          "DELETE_USER_AUTH_STEP_FAILED",
          uid,
          { error: authError.message, note: "Firestore was deleted but Auth deletion failed." }
      );
      throw new functions.https.HttpsError(
          "internal",
          `Firestore deleted but Auth deletion failed: ${authError.message}`
      );
    }
  }

  // Step 8: Final audit log
  await logAdminAction(
      context.auth.uid,
      context.auth.token.email || "Admin",
      "DELETE_USER_COMPLETE",
      uid,
      {
        email: userRecord.email || null,
        displayName: userRecord.displayName || null,
        deletedAt: new Date().toISOString(),
      }
  );

  return { success: true, message: "User deleted successfully", uid };
});

/**
 * Send Admin Notification via FCM
 */
exports.sendAdminNotification = functions.https.onCall(async (data, context) => {
  await checkAdmin(context, "notifications.manage");
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

/**
 * Keeps support-message notifications tied to real message creation events.
 * Fixed notification IDs make retries idempotent.
 */
exports.onSupportChatMessageCreated = functions.firestore
    .document("chats/{chatId}/messages/{messageId}")
    .onCreate(async (snapshot, context) => {
      const message = snapshot.data() || {};
      const chatId = context.params.chatId;
      const messageId = context.params.messageId;
      const senderId = typeof message.senderId === "string" ? message.senderId : "";
      const chatRef = admin.firestore().collection("chats").doc(chatId);
      const chatSnapshot = await chatRef.get();
      if (!chatSnapshot.exists) return null;

      const chat = chatSnapshot.data() || {};
      const userId = typeof chat.userId === "string" ? chat.userId : "";
      if (!userId || !senderId) return null;

      const db = admin.firestore();
      const now = admin.firestore.FieldValue.serverTimestamp();
      const userProfile = await db.collection("users").doc(userId).get();
      const userData = userProfile.data() || {};

      if (message.isAdmin === true) {
        const senderRecord = await admin.auth().getUser(senderId);
        const email = String(senderRecord.email || "").toLowerCase();
        const profile = await db.collection("users").doc(senderId).get();
        const trustedAdmin = senderRecord.emailVerified &&
          (senderRecord.customClaims?.admin === true ||
            ["mma831770@gmail.com", "abdellahismd@gmail.com"].includes(email) ||
            profile.data()?.isAdmin === true);
        if (!trustedAdmin || senderId === userId) {
          console.error("Ignoring support reply from an untrusted sender", {
            chatId,
            messageId,
            senderId,
          });
          return null;
        }

        const notificationRef = db.collection("users").doc(userId)
            .collection("notifications").doc(`support_reply_${messageId}`);
        const notificationCreated = await db.runTransaction(async (transaction) => {
          const existing = await transaction.get(notificationRef);
          const currentChatSnapshot = await transaction.get(chatRef);
          const currentChat = currentChatSnapshot.data() || {};
          const lastUserMessageAt = currentChat.lastUserMessageAt;
          const replyCreatedAt = message.createdAt;
          const isLatestReply = !(lastUserMessageAt &&
            replyCreatedAt &&
            typeof lastUserMessageAt.toMillis === "function" &&
            typeof replyCreatedAt.toMillis === "function" &&
            lastUserMessageAt.toMillis() > replyCreatedAt.toMillis());
          const lastAdminReplyAt = currentChat.lastAdminReplyAt;
          const isNotOlderThanExistingReply = !(lastAdminReplyAt &&
            replyCreatedAt &&
            typeof lastAdminReplyAt.toMillis === "function" &&
            typeof replyCreatedAt.toMillis === "function" &&
            lastAdminReplyAt.toMillis() > replyCreatedAt.toMillis());
          const lastUserMessageId = currentChat.lastUserMessageId;
          const pendingAdminNotificationRef = typeof lastUserMessageId === "string" ?
            db.collection("admin_notifications")
                .doc(lastUserMessageId) :
            null;
          const pendingAdminNotification = pendingAdminNotificationRef ?
            await transaction.get(pendingAdminNotificationRef) :
            null;
          if (!existing.exists) {
            transaction.create(notificationRef, {
              id: notificationRef.id,
              title: "تم الرد على رسالتك",
              body: "لديك رد جديد من فريق MERAJ3I.",
              type: 6,
              targetType: "chat",
              targetId: chatId,
              messageId,
              isRead: false,
              timestamp: Date.now(),
              createdAt: now,
            });
          }
          if (isLatestReply && isNotOlderThanExistingReply) {
            transaction.set(chatRef, {
              supportState: "awaiting_user",
              lastAdminReplyAt: replyCreatedAt || now,
            }, {merge: true});
            if (pendingAdminNotification?.exists &&
                !pendingAdminNotification.data()?.resolvedAt) {
              transaction.update(pendingAdminNotificationRef, {
                resolvedAt: replyCreatedAt || now,
              });
            }
          }
          return !existing.exists;
        });

        if (notificationCreated) {
          const tokens = new Set();
          if (typeof userData.fcmToken === "string" && userData.fcmToken) {
            tokens.add(userData.fcmToken);
          }
          if (Array.isArray(userData.fcmTokens)) {
            userData.fcmTokens
                .filter((token) => typeof token === "string" && token)
                .forEach((token) => tokens.add(token));
          }
          if (tokens.size > 0) {
            try {
              const response = await admin.messaging().sendEachForMulticast({
                tokens: [...tokens],
                notification: {
                  title: "تم الرد على رسالتك",
                  body: "لديك رد جديد من فريق MERAJ3I.",
                },
                data: {
                  type: "chat_reply",
                  targetType: "chat",
                  targetId: chatId,
                  notificationId: notificationRef.id,
                  title: "تم الرد على رسالتك",
                  body: "لديك رد جديد من فريق MERAJ3I.",
                },
              });
              if (response.failureCount > 0) {
                console.error("Some support reply push notifications failed", {
                  chatId,
                  messageId,
                  failureCount: response.failureCount,
                });
              }
            } catch (error) {
              console.error("Unable to send support reply push notification", {
                chatId,
                messageId,
                error,
              });
            }
          }
        }
        const replyCreatedAt = message.createdAt;
        if (replyCreatedAt && typeof replyCreatedAt.toMillis === "function") {
          const alerts = await db.collection("admin_notifications")
              .where("chatId", "==", chatId)
              .where("type", "==", "support_message")
              .limit(500)
              .get();
          let resolvedCount = 0;
          for (let start = 0; start < alerts.docs.length; start += 450) {
            const batch = db.batch();
            let batchCount = 0;
            for (const alert of alerts.docs.slice(start, start + 450)) {
              const alertData = alert.data();
              const eventAt = alertData.eventAt;
              if (!alertData.resolvedAt &&
                  eventAt &&
                  typeof eventAt.toMillis === "function" &&
                  eventAt.toMillis() <= replyCreatedAt.toMillis()) {
                batch.update(alert.ref, {
                  resolvedAt: replyCreatedAt,
                  resolvedBy: senderId,
                });
                resolvedCount++;
                batchCount++;
              }
            }
            if (batchCount > 0) await batch.commit();
          }
          if (alerts.size === 500) {
            console.error("Support notification resolution reached its 500-alert limit", {
              chatId,
            });
          }
        }
        return null;
      }

      if (message.isAdmin !== false || senderId !== userId) return null;

      const notificationRef = db.collection("admin_notifications")
          .doc(messageId);
      await db.runTransaction(async (transaction) => {
        const existing = await transaction.get(notificationRef);
        const currentChatSnapshot = await transaction.get(chatRef);
        const currentChat = currentChatSnapshot.data() || {};
        const userMessageAt = message.createdAt;
        const lastUserMessageAt = currentChat.lastUserMessageAt;
        const isLatestUserMessage = !(lastUserMessageAt &&
          userMessageAt &&
          typeof lastUserMessageAt.toMillis === "function" &&
          typeof userMessageAt.toMillis === "function" &&
          lastUserMessageAt.toMillis() > userMessageAt.toMillis());
        const lastAdminReplyAt = currentChat.lastAdminReplyAt;
        const repliedAfterThisMessage = lastAdminReplyAt &&
          userMessageAt &&
          typeof lastAdminReplyAt.toMillis === "function" &&
          typeof userMessageAt.toMillis === "function" &&
          lastAdminReplyAt.toMillis() >= userMessageAt.toMillis();
        if (!existing.exists) {
          transaction.create(notificationRef, {
            type: "support_message",
            chatId,
            messageId,
            userId,
            userName: String(userData.fullName || userData.name || chat.userName || "مستخدم"),
            userEmail: String(userData.email || ""),
            excerpt: typeof message.text === "string" ? message.text.slice(0, 160) : "",
            readBy: {},
            eventAt: userMessageAt || now,
            ...(repliedAfterThisMessage ? {resolvedAt: lastAdminReplyAt} : {}),
            createdAt: now,
          });
        }
        if (isLatestUserMessage) {
          transaction.set(chatRef, {
            ...(repliedAfterThisMessage ? {} : {supportState: "awaiting_admin"}),
            lastUserMessageId: messageId,
            lastUserMessageAt: userMessageAt || now,
          }, {merge: true});
        }
      });
      return null;
    });

/**
 * Recalculates completed exam scores from the published question bank and
 * awards only improvements over the student's best result for each quiz.
 */
exports.verifyCompletedExamAttempt = functions.firestore
    .document("exam_attempts/{attemptId}")
    .onWrite(async (change, context) => {
      const before = change.before.exists ? change.before.data() || {} : null;
      const attempt = change.after.exists ? change.after.data() || {} : null;
      if (!attempt || attempt.status !== "completed" ||
          before?.status === "completed") return null;

      const attemptId = context.params.attemptId;
      const userId = typeof attempt.userId === "string" ? attempt.userId : "";
      const quizId = typeof attempt.quizId === "string" ? attempt.quizId : "";
      const answers = attempt.answers;
      const startedAt = attempt.startedAt;
      const submittedAt = attempt.submittedAt;
      const now = admin.firestore.Timestamp.now();
      if (!userId || !quizId || !answers || typeof answers !== "object" ||
          Array.isArray(answers) ||
          !startedAt || typeof startedAt.toMillis !== "function" ||
          !submittedAt || typeof submittedAt.toMillis !== "function" ||
          startedAt.toMillis() > submittedAt.toMillis() ||
          submittedAt.toMillis() > now.toMillis() + 60_000) {
        console.warn("Rejected malformed completed exam attempt", {attemptId});
        return null;
      }

      const db = admin.firestore();
      const quizSnapshot = await db.collection("quizzes").doc(quizId).get();
      const quiz = quizSnapshot.data() || {};
      if (!quizSnapshot.exists || quiz.kind !== "quiz" ||
          quiz.status !== "published" || quiz.isActive === false) {
        console.warn("Rejected attempt for an unpublished quiz", {
          attemptId,
          quizId,
        });
        return null;
      }

      const questionSnapshot = await db.collection("quizzes").doc(quizId)
          .collection("questions")
          .orderBy("order")
          .get();
      const questions = questionSnapshot.docs
          .map((doc) => ({...doc.data(), _id: doc.id}))
          .filter((question) => {
            const text = question.question ?? question.text ?? "";
            const options = question.options ?? question.answers ?? [];
            return String(text).trim().length > 0 &&
              Array.isArray(options) && options.length >= 2;
          })
          .map((question) => {
            const options = question.options ?? question.answers;
            let correctIndex = typeof question.correctIndex === "number" &&
              Number.isFinite(question.correctIndex) ?
              Math.trunc(question.correctIndex) :
              null;
            if (correctIndex === null) {
              const correctAnswer = question.correctAnswer;
              correctIndex = typeof correctAnswer === "string" ?
                options.indexOf(correctAnswer) :
                -1;
              if (correctIndex < 0) {
                correctIndex = Number.parseInt(String(correctAnswer ?? ""), 10) || 0;
              }
            }
            return {
              id: question._id,
              options,
              correctIndex: Math.max(0, Math.min(correctIndex, options.length - 1)),
            };
          });

      const totalQuestions = questions.length;
      if (totalQuestions === 0 ||
          Number(attempt.totalQuestions) !== totalQuestions) {
        console.warn("Rejected attempt with an unexpected question count", {
          attemptId,
          quizId,
          expected: totalQuestions,
          received: attempt.totalQuestions,
        });
        return null;
      }

      const correctAnswers = countCorrectAnswers(questions, answers);
      if (correctAnswers === null) {
        console.warn("Rejected attempt with an invalid answer index", {
          attemptId,
          quizId,
        });
        return null;
      }

      const attemptRef = db.collection("honor_attempts").doc(attemptId);
      const questionRevision = hashValue(JSON.stringify(
          questions.map((question, index) => [
            question.id,
            index,
            question.options,
            question.correctIndex,
          ]),
      ));
      const bestRef = db.collection("honor_best_results")
          .doc(hashValue(`${userId}:${quizId}:${questionRevision}`));
      const boardRef = db.collection("honor_board").doc(userId);
      const userRef = db.collection("users").doc(userId);
      await db.runTransaction(async (transaction) => {
        const existingAttempt = await transaction.get(attemptRef);
        if (existingAttempt.exists) return;
        const bestSnapshot = await transaction.get(bestRef);
        const boardSnapshot = await transaction.get(boardRef);
        const userSnapshot = await transaction.get(userRef);
        const previousBest = bestSnapshot.data() || {};
        const board = boardSnapshot.data() || {};
        const hasPreviousBest = bestSnapshot.exists;
        const previousCorrect = Number(previousBest.correctAnswers || 0);
        const improvement = improvementOverBest(
            previousCorrect,
            correctAnswers,
        );
        const previousPoints = Number(board.points || 0);
        const previousVerifiedCorrect = Number(
            board.verifiedCorrectAnswers || 0);
        const previousVerifiedQuestions = Number(
            board.verifiedTotalQuestions || 0);
        if (!userSnapshot.exists) {
          console.warn("Skipped honor points for a missing user profile", {
            attemptId,
            userId,
          });
          return;
        }
        const userData = userSnapshot.data() || {};
        const accountStatus = String(userData.accountStatus || "")
            .toLowerCase();
        if (userData.isSuspended === true ||
            ["suspended", "disabled", "deleted"].includes(accountStatus)) {
          console.warn("Skipped honor points for an inactive account", {
            attemptId,
            userId,
          });
          return;
        }
        const displayName = String(
            userData.fullName || userData.name || "طالب متميز")
            .trim()
            .slice(0, 80);
        const profileImageUrl = String(
            userData.profileImageUrl || userData.photoUrl || "").slice(0, 2_000);

        transaction.create(attemptRef, {
          userId,
          quizId,
          correctAnswers,
          totalQuestions,
          submittedAt,
          verifiedAt: now,
        });
        transaction.set(bestRef, {
          userId,
          quizId,
          correctAnswers: Math.max(previousCorrect, correctAnswers),
          totalQuestions,
          updatedAt: now,
        });
        transaction.set(boardRef, {
          name: displayName || "طالب متميز",
          profileImageUrl,
          points: previousPoints + improvement * 10,
          verifiedExamCount: Number(board.verifiedExamCount || 0) +
            (hasPreviousBest ? 0 : 1),
          verifiedCorrectAnswers: previousVerifiedCorrect + improvement,
          verifiedTotalQuestions: previousVerifiedQuestions +
            (hasPreviousBest ? 0 : totalQuestions),
          avgScore: totalQuestions === 0 ? 0 :
            ((previousVerifiedCorrect + improvement) /
              (previousVerifiedQuestions +
                (hasPreviousBest ? 0 : totalQuestions))) * 100,
          lastActivity: now,
          updatedAt: now,
        }, {merge: true});
      });
      return null;
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
