const router = require("express").Router();
const {
  sendOTPHandler,
  verifyOTPHandler,
  logoutHandler,
} = require("../controllers/authController");

const { otpLimiter } = require("../middleware/rateLimiter");
const { authenticate } = require("../middleware/auth");
const { body, validationResult } = require("express-validator");

// 🔥 COMMON VALIDATION HANDLER
const validate = (req, res, next) => {
  const errors = validationResult(req);
  if (!errors.isEmpty()) {
    return res.status(400).json({
      success: false,
      message: "Validation failed",
      errors: errors.array(),
    });
  }
  next();
};

// 🔥 VALID ROLES
const validRoles = ["admin", "agent", "user"];

const checkRole = (req, res, next) => {
  const { role } = req.params;
  if (!validRoles.includes(role)) {
    return res.status(400).json({
      success: false,
      message: "Invalid role",
    });
  }
  next();
};

// ================= SEND OTP =================
router.post(
  "/:role/send-otp",
  otpLimiter,
  checkRole,
  [
    body("phone")
      .matches(/^[6-9]\d{9}$/)
      .withMessage("Invalid phone number"),
  ],
  validate,
  sendOTPHandler
);

// ================= VERIFY OTP =================
router.post(
  "/:role/verify-otp",
  checkRole,
  [
    body("phone")
      .matches(/^[6-9]\d{9}$/)
      .withMessage("Invalid phone number"),
    body("otp")
      .isLength({ min: 6, max: 6 })
      .withMessage("OTP must be 6 digits"),
  ],
  validate,
  verifyOTPHandler
);

// ================= LOGOUT =================
router.post("/user/logout", authenticate("user"), logoutHandler);
router.post("/agent/logout", authenticate("agent"), logoutHandler);
router.post("/admin/logout", authenticate("admin"), logoutHandler);

module.exports = router;