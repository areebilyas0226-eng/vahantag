const Razorpay = require("razorpay");
const crypto = require("crypto");
const { query } = require("../config/database");
const logger = require("../utils/logger");

const razorpay = new Razorpay({ key_id: process.env.RAZORPAY_KEY_ID, key_secret: process.env.RAZORPAY_KEY_SECRET });

const createOrder = async (amountPaisa, userId, metadata = {}) => {
  const rpOrder = await razorpay.orders.create({
    amount: amountPaisa, currency: "INR",
    receipt: "VT_" + Date.now(),
    notes: { userId, ...metadata }
  });
  const { rows } = await query(
    "INSERT INTO payment_orders (user_id, razorpay_order_id, amount_paisa, metadata) VALUES ($1,$2,$3,$4) RETURNING *",
    [userId, rpOrder.id, amountPaisa, JSON.stringify(metadata)]
  );
  return { orderId: rpOrder.id, amount: amountPaisa, keyId: process.env.RAZORPAY_KEY_ID, dbOrderId: rows[0].id };
};

const verifySignature = (orderId, paymentId, signature) => {
  const expected = crypto.createHmac("sha256", process.env.RAZORPAY_KEY_SECRET).update(orderId + "|" + paymentId).digest("hex");
  return expected === signature;
};

const verifyWebhook = (rawBody, signature) => {
  const expected = crypto.createHmac("sha256", process.env.RAZORPAY_WEBHOOK_SECRET).update(rawBody).digest("hex");
  return expected === signature;
};

module.exports = { createOrder, verifySignature, verifyWebhook, razorpay };
