const { query } = require("../config/database");
const { getRedis } = require("../config/redis");
const { sendOTP } = require("../services/smsService");
const { generateTokens } = require("../middleware/auth");
const logger = require("../utils/logger");

const genOTP = () =>
  Math.floor(100000 + Math.random() * 900000).toString();

// Normalize phone
const normalizePhone = (phone) => {
  const digits = phone.replace(/\D/g, "");
  if (digits.length === 12 && digits.startsWith("91")) return digits.slice(2);
  if (digits.length === 10) return digits;
  return digits.slice(-10);
};

// +91 format
const formatForSMS = (phone10) => "+91" + phone10;

/* ================= SEND OTP ================= */
const sendOTPHandler = async (req, res, next) => {
  try {
    const { phone } = req.body;
    const { role } = req.params;

    if (!phone) {
      return res.status(400).json({
        success: false,
        message: "Phone number required",
      });
    }

    const normalizedPhone = normalizePhone(phone);

    if (!/^[6-9]\d{9}$/.test(normalizedPhone)) {
      return res.status(400).json({
        success: false,
        message: "Invalid phone number",
      });
    }

    // ADMIN CHECK
    if (role === "admin") {
      const { rows } = await query(
        "SELECT * FROM users WHERE phone = $1 AND role = 'admin'",
        [normalizedPhone]
      );

      if (!rows.length) {
        return res.status(403).json({
          success: false,
          message: "No admin account found",
        });
      }
    }

    const otp = genOTP();
    const redisKey = `otp:${role}_${normalizedPhone}`;

    await getRedis().setEx(
      redisKey,
      600,
      JSON.stringify({ otp, attempts: 0 })
    );

    console.log("Generated OTP:", otp);

    await sendOTP(formatForSMS(normalizedPhone), otp);

    logger.info(`OTP sent [${role}] to ${normalizedPhone}`);

    res.json({
      success: true,
      message: "OTP sent",
      expiresIn: 600,
    });

  } catch (err) {
    next(err);
  }
};

/* ================= VERIFY OTP ================= */
const verifyOTPHandler = async (req, res, next) => {
  try {
    const { phone, otp, name } = req.body;
    const { role } = req.params;

    if (!phone || !otp) {
      return res.status(400).json({
        success: false,
        message: "Phone and OTP required",
      });
    }

    const normalizedPhone = normalizePhone(phone);
    const redisKey = `otp:${role}_${normalizedPhone}`;

    const raw = await getRedis().get(redisKey);

    if (!raw) {
      return res.status(400).json({
        success: false,
        message: "OTP expired",
      });
    }

    const stored = JSON.parse(raw);

    // limit attempts
    if (stored.attempts >= 3) {
      await getRedis().del(redisKey);
      return res.status(400).json({
        success: false,
        message: "Too many attempts",
      });
    }

    // wrong OTP
    if (stored.otp !== otp) {
      stored.attempts++;
      await getRedis().setEx(redisKey, 600, JSON.stringify(stored));

      return res.status(400).json({
        success: false,
        message: "Invalid OTP",
        attemptsLeft: 3 - stored.attempts,
      });
    }

    // success
    await getRedis().del(redisKey);

    let user;

    if (role === "admin") {
      const { rows } = await query(
        "SELECT * FROM users WHERE phone = $1 AND role = 'admin'",
        [normalizedPhone]
      );

      if (!rows.length) {
        return res.status(403).json({
          success: false,
          message: "No admin account found",
        });
      }

      user = rows[0];

      await query(
        "UPDATE users SET last_login = NOW(), phone_verified = true WHERE id = $1",
        [user.id]
      );
    }

    // generate tokens
    const { accessToken, refreshToken } = generateTokens(user.id, role);

    await getRedis().setEx(
      `refresh:${role}:${user.id}`,
      90 * 24 * 3600,
      refreshToken
    );

    // ✅ FINAL RESPONSE (IMPORTANT)
    res.json({
      success: true,
      message: "Login successful",
      data: {
        user,
        accessToken,
        refreshToken,
      },
    });

  } catch (err) {
    next(err);
  }
};

/* ================= LOGOUT ================= */
const logoutHandler = async (req, res, next) => {
  try {
    await getRedis().del(`refresh:${req.userRole}:${req.user.id}`);

    res.json({
      success: true,
      message: "Logged out",
    });
  } catch (err) {
    next(err);
  }
};

module.exports = {
  sendOTPHandler,
  verifyOTPHandler,
  logoutHandler,
};