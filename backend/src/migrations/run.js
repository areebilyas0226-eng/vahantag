require("dotenv").config();
const fs = require("fs");
const path = require("path");
const { Pool } = require("pg");
const pool = new Pool({ connectionString: process.env.DATABASE_URL, ssl: { rejectUnauthorized: false } });

const run = async () => {
  const client = await pool.connect();
  try {
    await client.query("CREATE TABLE IF NOT EXISTS migrations (id SERIAL PRIMARY KEY, filename VARCHAR(255) UNIQUE NOT NULL, executed_at TIMESTAMP DEFAULT NOW())");
    const files = fs.readdirSync(__dirname).filter(f => f.endsWith(".sql")).sort();
    for (const file of files) {
      const { rows } = await client.query("SELECT id FROM migrations WHERE filename=$1", [file]);
      if (rows.length) { console.log("Already run:", file); continue; }
      console.log("Running:", file);
      const sql = fs.readFileSync(path.join(__dirname, file), "utf8");
      await client.query(sql);
      await client.query("INSERT INTO migrations (filename) VALUES ($1)", [file]);
      console.log("Done:", file);
    }
    console.log("All migrations complete!");
    process.exit(0);
  } catch(e) { console.error("Migration error:", e.message); process.exit(1); }
  finally { client.release(); }
};
run();
