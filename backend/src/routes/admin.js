const express = require("express");
const router = express.Router();

const c = require("../controllers/adminController");
const { authenticate } = require("../middleware/auth");

// ================= MIDDLEWARE =================
router.use(authenticate("admin"));

// ================= DEBUG LOGGER (IMPORTANT) =================
router.use((req, res, next) => {
  console.log(`\n[ADMIN API] ${req.method} ${req.originalUrl}`);
  console.log("BODY:", req.body);
  next();
});

// ================= DASHBOARD =================
router.get("/dashboard", c.getDashboard);

// ================= TAGS =================

// 🔥 Generate Tags (with validation)
router.post("/tags/generate", (req, res, next) => {
  const { count } = req.body;

  if (!count || typeof count !== "number" || count <= 0) {
    return res.status(400).json({
      success: false,
      message: "Invalid 'count'. Must be a positive number.",
    });
  }

  next();
}, c.generateTags);

// Assign tags to agent
router.post("/tags/assign-agent", (req, res, next) => {
  const { agent_id, tag_codes, wholesale_price_paisa } = req.body;

  if (!agent_id || !Array.isArray(tag_codes) || tag_codes.length === 0) {
    return res.status(400).json({
      success: false,
      message: "agent_id and tag_codes are required",
    });
  }

  next();
}, c.assignTagsToAgent);

// List tags
router.get("/tags", c.listTags);

// ================= AGENTS =================
router.get("/agents", c.listAgents);

router.put("/agents/:id/approve", (req, res, next) => {
  if (!req.params.id) {
    return res.status(400).json({
      success: false,
      message: "Agent ID is required",
    });
  }
  next();
}, c.approveAgent);

// ================= USERS =================
router.get("/users", c.listUsers);

router.put("/users/:id/toggle", (req, res, next) => {
  if (!req.params.id) {
    return res.status(400).json({
      success: false,
      message: "User ID is required",
    });
  }
  next();
}, c.toggleUser);

// ================= CATEGORIES =================
router.get("/categories", c.getCategories);

router.put("/categories/:id/price", (req, res, next) => {
  if (!req.params.id) {
    return res.status(400).json({
      success: false,
      message: "Category ID is required",
    });
  }

  if (!req.body || Object.keys(req.body).length === 0) {
    return res.status(400).json({
      success: false,
      message: "Update data is required",
    });
  }

  next();
}, c.updateCategoryPrice);

// ================= REVENUE =================
router.get("/revenue", c.getRevenue);

// ================= FALLBACK =================
router.use((req, res) => {
  res.status(404).json({
    success: false,
    message: "Admin route not found",
  });
});

module.exports = router;