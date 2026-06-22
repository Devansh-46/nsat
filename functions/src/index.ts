import * as admin from "firebase-admin";
admin.initializeApp();

// Re-export all functions
export { syncStudents } from "./syncStudents";
export { fetchLeadDetails } from "./fetchLeadDetails";
export { sendOtp, verifyOtp, sendWhatsAppOtp, resendOtpViaSms } from "./otp";
export { scoreSubmission } from "./scoreSubmission";
export { autoSubmitExpired } from "./autoSubmitExpired";
export { sendNotification } from "./sendNotification";
export { setAdminClaim, removeAdminClaim, listAdmins, clearForcePasswordChange, updateAdminCourses, updateAdminPermissions, promoteSuperadmin, demoteSuperadmin } from "./adminClaims";
