const { createClient } = require("redis");
const logger = require("../utils/logger");

let client;
let isConnected = false;

const connectRedis = async () => {
  try {
    client = createClient({
      url: process.env.REDIS_URL,
      socket: { reconnectStrategy: (r) => Math.min(r * 100, 3000) }
    });

    client.on("error", (err) => logger.error("Redis error:", err.message));
    client.on("connect", () => {
      isConnected = true;
      logger.info("Redis connected");
    });
    client.on("disconnect", () => {
      isConnected = false;
    });

    await client.connect();
    return client;

  } catch (err) {
    // Non-fatal — server will still start without Redis
    logger.error("Redis failed to connect (non-fatal):", err.message);
    client = null;
    isConnected = false;
  }
};

const getRedis = () => {
  if (!client || !isConnected) return null;
  return client;
};

const setOTP = async (phone, otp) => {
  const r = getRedis();
  if (!r) return null;
  return r.setEx("otp:" + phone, 600, JSON.stringify({ otp, attempts: 0 }));
};

const getOTP = async (phone) => {
  const r = getRedis();
  if (!r) return null;
  const d = await r.get("otp:" + phone);
  return d ? JSON.parse(d) : null;
};

const delOTP = async (phone) => {
  const r = getRedis();
  if (!r) return null;
  return r.del("otp:" + phone);
};

const setCache = async (k, v, ttl = 300) => {
  const r = getRedis();
  if (!r) return null;
  return r.setEx("cache:" + k, ttl, JSON.stringify(v));
};

const getCache = async (k) => {
  const r = getRedis();
  if (!r) return null;
  const d = await r.get("cache:" + k);
  return d ? JSON.parse(d) : null;
};

const delCache = async (k) => {
  const r = getRedis();
  if (!r) return null;
  return r.del("cache:" + k);
};

module.exports = {
  connectRedis,
  getRedis,
  setOTP,
  getOTP,
  delOTP,
  setCache,
  getCache,
  delCache
};