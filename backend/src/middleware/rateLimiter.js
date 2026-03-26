const rateLimit = require("express-rate-limit");

const otpLimiter = rateLimit({
  windowMs: 10 * 60 * 1000,
  max: 3,
  message: { success: false, message: "Too many OTP requests" },
  keyGenerator: (req) => req.body?.phone || req.ip,
  validate: { xForwardedForHeader: false }
});

const apiLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 60,
  message: { success: false, message: "Too many requests" },
  validate: { xForwardedForHeader: false }
});

const scanLimiter = rateLimit({
  windowMs: 60 * 1000,
  max: 20,
  message: { success: false, message: "Too many scan attempts" },
  validate: { xForwardedForHeader: false }
});

const callLimiter = rateLimit({
  windowMs: 60 * 60 * 1000,
  max: 5,
  message: { success: false, message: "Too many call attempts" },
  keyGenerator: (req) => req.ip,
  validate: { xForwardedForHeader: false }
});

module.exports = { otpLimiter, apiLimiter, scanLimiter, callLimiter };