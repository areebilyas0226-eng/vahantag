const { Pool } = require("pg");
const logger = require("../utils/logger");

const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: { rejectUnauthorized: false },
  max: 10,
  idleTimeoutMillis: 10000,
  connectionTimeoutMillis: 10000,
});

pool.on("connect", () => logger.info("PostgreSQL connected"));
pool.on("error", (err) => logger.error("PostgreSQL error:", err.message));

const query = async (text, params) => {
  let retries = 3;
  while (retries > 0) {
    try {
      return await pool.query(text, params);
    } catch (err) {
      retries--;
      if (retries === 0) throw err;
      await new Promise(r => setTimeout(r, 1000));
    }
  }
};

// Keep alive for Neon
setInterval(async () => {
  try { await pool.query("SELECT 1"); } catch(e) {}
}, 60000);

const getClient = () => pool.connect();
module.exports = { query, pool, getClient };
