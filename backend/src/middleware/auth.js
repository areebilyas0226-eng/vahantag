const jwt = require("jsonwebtoken");
const { query } = require("../config/database");
const logger = require("../utils/logger");

const authenticate = (role) => async (req, res, next) => {
  try {
    const token = req.headers.authorization?.split(" ")[1];
    if (!token) return res.status(401).json({ success: false, message: "Token required" });
    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    
    let table, idField;
    if (role === "admin") { table = "admin_users"; idField = "adminId"; }
    else if (role === "agent") { table = "agents"; idField = "agentId"; }
    else { table = "users"; idField = "userId"; }
    
    const { rows } = await query("SELECT * FROM " + table + " WHERE id=$1 AND is_active=true", [decoded[idField]]);
    if (!rows.length) return res.status(401).json({ success: false, message: "User not found" });
    
    req.user = rows[0];
    req.userRole = role;
    next();
  } catch (err) {
    if (err.name === "JsonWebTokenError" || err.name === "TokenExpiredError") {
      return res.status(401).json({ success: false, message: "Invalid or expired token" });
    }
    next(err);
  }
};

const generateTokens = (id, role) => {
  const idField = role === "admin" ? "adminId" : role === "agent" ? "agentId" : "userId";
  const payload = { [idField]: id, role };
  const accessToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "30d" });
  const refreshToken = jwt.sign(payload, process.env.JWT_SECRET, { expiresIn: "90d" });
  return { accessToken, refreshToken };
};

module.exports = { authenticate, generateTokens };
