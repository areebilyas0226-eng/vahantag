require("dotenv").config();
require("express-async-errors");
const express = require("express");
const helmet = require("helmet");
const cors = require("cors");
const morgan = require("morgan");
const logger = require("./utils/logger");
const { connectRedis } = require("./config/redis");
const { pool } = require("./config/database");
const { errorHandler, notFound } = require("./middleware/errorHandler");
const { apiLimiter } = require("./middleware/rateLimiter");

const app = express();
const PORT = process.env.PORT || 5000;

app.use(helmet({ contentSecurityPolicy: false, crossOriginEmbedderPolicy: false }));
app.use(cors({
  origin: process.env.NODE_ENV === "production"
    ? [process.env.FRONTEND_URL, "https://vahantag.com"]
    : "*",
  methods: ["GET","POST","PUT","DELETE","PATCH"],
  allowedHeaders: ["Content-Type","Authorization"],
  credentials: true
}));

app.use("/api/webhooks", express.raw({ type: "application/json" }));
app.use(express.json({ limit: "10mb" }));
app.use(express.urlencoded({ extended: true }));
if (process.env.NODE_ENV !== "test") {
  app.use(morgan("combined", { stream: { write: (m) => logger.http(m.trim()) } }));
}
app.use("/api/", apiLimiter);

app.get("/health", (req, res) => res.json({ status: "ok", app: "VahanTag API v2", version: "2.0.0", timestamp: new Date().toISOString() }));

app.use("/api/auth", require("./routes/auth"));
app.use("/api/user", require("./routes/user"));
app.use("/api/assets", require("./routes/assets"));
app.use("/api/emergency", require("./routes/emergency"));
app.use("/api/agent", require("./routes/agent"));
app.use("/api/admin", require("./routes/admin"));

app.use(notFound);
app.use(errorHandler);

const start = async () => {
  // PostgreSQL — non-fatal
  try {
    await pool.query("SELECT NOW()");
    logger.info("PostgreSQL connected");
  } catch (err) {
    logger.error("PostgreSQL connection failed (non-fatal):", err.message);
  }

  // Redis — non-fatal
  try {
    await connectRedis();
  } catch (err) {
    logger.error("Redis connection failed (non-fatal):", err.message);
  }

  // Server ALWAYS starts
  app.listen(PORT, "0.0.0.0", () => {
    logger.info("VahanTag API v2 running on port " + PORT);
    logger.info("Health: http://localhost:" + PORT + "/health");
  });
};

process.on("unhandledRejection", (err) => logger.error("Unhandled rejection:", err));
start();
module.exports = app;
