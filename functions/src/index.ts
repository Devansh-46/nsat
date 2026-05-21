import * as admin from "firebase-admin";
admin.initializeApp();

// Re-export all functions
export { syncStudents } from "./syncStudents";
export { fetchLeadDetails } from "./fetchLeadDetails";
export { sendOtp, verifyOtp } from "./otp";
export { scoreSubmission } from "./scoreSubmission";
export { sendNotification } from "./sendNotification";
export { setAdminClaim, removeAdminClaim } from "./adminClaims";
