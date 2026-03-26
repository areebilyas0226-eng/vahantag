const logger = require("../utils/logger");
const errorHandler = (err, req, res, next) => {
  logger.error("Error:", { message: err.message, url: req.url, method: req.method });
  if (err.code === "23505") return res.status(409).json({ success: false, message: "Record already exists" });
  if (err.code === "23503") return res.status(400).json({ success: false, message: "Referenced record not found" });
  const status = err.statusCode || 500;
  const message = process.env.NODE_ENV === "production" && status === 500 ? "Internal server error" : err.message;
  res.status(status).json({ success: false, message });
};
const notFound = (req, res) => res.status(404).json({ success: false, message: "Route not found" });
class AppError extends Error { constructor(msg, code) { super(msg); this.statusCode = code; } }
module.exports = { errorHandler, notFound, AppError };
