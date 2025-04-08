/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */

const { onRequest } = require("firebase-functions/v2/https");
const logger = require("firebase-functions/logger");

// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const functions = require("firebase-functions");
const admin = require("firebase-admin");

admin.initializeApp();

// Danh sách email được xét là admin
const ADMIN_EMAILS = ["admin1@example.com", "trananhthy27@gmail.com"];

exports.assignAdminRole = functions.auth.user().onCreate(async (user) => {
  const email = user.email;

  if (ADMIN_EMAILS.includes(email)) {
    await admin.auth().setCustomUserClaims(user.uid, { admin: true });
    console.log(`✅ Đã gán quyền admin cho ${email}`);
  } else {
    console.log(`ℹ️ ${email} không phải admin`);
  }
});
