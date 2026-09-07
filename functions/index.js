const functions = require("firebase-functions");
const admin = require("firebase-admin");

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
    suspendedAt: admin.firestore.FieldValue.serverTimestamp(),
    suspendReason: reason || "No reason provided"
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
    suspendedAt: admin.firestore.FieldValue.delete(),
    suspendReason: admin.firestore.FieldValue.delete()
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
