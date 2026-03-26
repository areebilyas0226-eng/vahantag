const router = require("express").Router();
const { sendOTPHandler, verifyOTPHandler, logoutHandler } = require("../controllers/authController");
const { otpLimiter } = require("../middleware/rateLimiter");
const { authenticate } = require("../middleware/auth");
const { body } = require("express-validator");

// SEND OTP
router.post(
  "/:role/send-otp",
  otpLimiter,
  [body("phone").matches(/^[6-9]\d{9}$/)],
  sendOTPHandler
);

// VERIFY OTP
router.post(
  "/:role/verify-otp",
  [
    body("phone").matches(/^[6-9]\d{9}$/),
    body("otp").isLength({ min: 6, max: 6 }),
  ],
  verifyOTPHandler
);

// LOGOUT
router.post("/user/logout", authenticate("user"), logoutHandler);
router.post("/agent/logout", authenticate("agent"), logoutHandler);
router.post("/admin/logout", authenticate("admin"), logoutHandler);

module.exports = router;