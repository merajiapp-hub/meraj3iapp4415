/**
 * سكريبت لمنح صلاحيات Admin للحسابات الإدارية مباشرة
 * يعمل محلياً باستخدام Firebase Admin SDK بدون الحاجة لرفع Cloud Functions
 * 
 * كيفية الاستخدام:
 * 1. حمّل Service Account Key من Firebase Console:
 *    Firebase Console → Project Settings → Service accounts → Generate new private key
 * 2. ضع الملف في نفس مجلد هذا السكريبت باسم: serviceAccountKey.json
 * 3. نفذ: node set_admin_claims.js
 */

const admin = require('firebase-admin');
const serviceAccount = require('./serviceAccountKey.json');

admin.initializeApp({
  credential: admin.credential.cert(serviceAccount),
});

const ADMIN_EMAILS = ['mma831770@gmail.com', 'abdellahismd@gmail.com'];

async function setAdminClaims() {
  console.log('🔐 بدء عملية منح صلاحيات الإدارة...\n');

  for (const email of ADMIN_EMAILS) {
    try {
      const userRecord = await admin.auth().getUserByEmail(email);
      await admin.auth().setCustomUserClaims(userRecord.uid, { admin: true });
      
      console.log(`✅ تم منح صلاحية Admin للحساب: ${email}`);
      console.log(`   UID: ${userRecord.uid}`);
      console.log(`   الحالة: ${userRecord.disabled ? '🔴 معطّل' : '🟢 نشط'}\n`);
    } catch (error) {
      console.error(`❌ فشل منح الصلاحية للحساب: ${email}`);
      console.error(`   الخطأ: ${error.message}\n`);
    }
  }

  console.log('🎉 اكتملت العملية!');
  console.log('⚠️  ملاحظة: يجب على المدير تسجيل الخروج وإعادة الدخول لتفعيل الصلاحيات.');
  
  process.exit(0);
}

setAdminClaims().catch(console.error);
