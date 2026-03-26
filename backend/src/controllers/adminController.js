const { query } = require("../config/database");
const QRCode = require("qrcode");
const { v4: uuidv4 } = require("uuid");
const logger = require("../utils/logger");

const genTagCode = () => {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const seg = (n) => Array.from({length:n}, () => chars[Math.floor(Math.random()*chars.length)]).join("");
  return "VT-" + seg(4) + "-" + seg(4);
};

const getDashboard = async (req, res, next) => {
  try {
    const [users, agents, tags, scans, revenue, subs] = await Promise.all([
      query("SELECT COUNT(*) FROM users WHERE is_active=true"),
      query("SELECT COUNT(*) FROM agents WHERE is_approved=true"),
      query("SELECT COUNT(*) FROM qr_tags WHERE status='active'"),
      query("SELECT COUNT(*) FROM scan_logs WHERE created_at > NOW() - INTERVAL '30 days'"),
      query("SELECT COALESCE(SUM(amount_paisa),0) as total FROM payment_orders WHERE status='paid' AND paid_at > NOW() - INTERVAL '30 days'"),
      query("SELECT COUNT(*) FROM subscriptions WHERE status='active' AND expires_at > NOW()"),
    ]);
    res.json({ success: true, data: {
      totalUsers: +users.rows[0].count,
      approvedAgents: +agents.rows[0].count,
      activeTags: +tags.rows[0].count,
      scansLast30Days: +scans.rows[0].count,
      revenueLast30Days: +revenue.rows[0].total,
      activeSubscriptions: +subs.rows[0].count,
    }});
  } catch (err) { next(err); }
};

const generateTags = async (req, res, next) => {
  try {
    const { count=10, batch_id } = req.body;
    if (count > 1000) return res.status(400).json({ success: false, message: "Max 1000 per batch" });
    const batchId = batch_id || "BATCH_" + Date.now();
    const codes = [];
    for (let i = 0; i < count; i++) {
      let code, exists = true;
      while (exists) {const { query } = require("../config/database");
const { v4: uuidv4 } = require("uuid");
const logger = require("../utils/logger");

// ================= UTIL =================
const genTagCode = () => {
  const chars = "ABCDEFGHJKLMNPQRSTUVWXYZ23456789";
  const seg = (n) =>
    Array.from({ length: n }, () =>
      chars[Math.floor(Math.random() * chars.length)]
    ).join("");
  return "VT-" + seg(4) + "-" + seg(4);
};

// ================= DASHBOARD =================
const getDashboard = async (req, res, next) => {
  try {
    const [users, agents, tags, scans, revenue, subs] = await Promise.all([
      query("SELECT COUNT(*) FROM users WHERE is_active=true"),
      query("SELECT COUNT(*) FROM agents WHERE is_approved=true"),
      query("SELECT COUNT(*) FROM qr_tags WHERE status='active'"),
      query("SELECT COUNT(*) FROM scan_logs WHERE created_at > NOW() - INTERVAL '30 days'"),
      query("SELECT COALESCE(SUM(amount_paisa),0) as total FROM payment_orders WHERE status='paid' AND paid_at > NOW() - INTERVAL '30 days'"),
      query("SELECT COUNT(*) FROM subscriptions WHERE status='active' AND expires_at > NOW()"),
    ]);

    return res.json({
      success: true,
      data: {
        totalUsers: +users.rows[0].count,
        approvedAgents: +agents.rows[0].count,
        activeTags: +tags.rows[0].count,
        scansLast30Days: +scans.rows[0].count,
        revenueLast30Days: +revenue.rows[0].total,
        activeSubscriptions: +subs.rows[0].count,
      },
    });
  } catch (err) {
    next(err);
  }
};

// ================= GENERATE TAGS (CRITICAL FIX) =================
const generateTags = async (req, res, next) => {
  try {
    let { count = 10, batch_id } = req.body;

    count = Number(count);

    if (!count || count < 1 || count > 1000) {
      return res.status(400).json({
        success: false,
        message: "Count must be between 1 and 1000",
      });
    }

    const batchId = batch_id || "BATCH_" + Date.now();
    const codes = [];

    for (let i = 0; i < count; i++) {
      let code, exists = true;

      while (exists) {
        code = genTagCode();
        const { rows } = await query(
          "SELECT id FROM qr_tags WHERE tag_code=$1",
          [code]
        );
        exists = rows.length > 0;
      }

      await query(
        "INSERT INTO qr_tags (id, tag_code, batch_id) VALUES ($1,$2,$3)",
        [uuidv4(), code, batchId]
      );

      codes.push(code);
    }

    logger.info(`Generated ${count} tags in batch ${batchId}`);

    // 🔥 FIX: FLAT RESPONSE (NO data.codes)
    return res.json({
      success: true,
      message: `${count} tags generated`,
      codes: codes,
      batchId: batchId,
      count: count,
    });

  } catch (err) {
    next(err);
  }
};

// ================= ASSIGN TAGS =================
const assignTagsToAgent = async (req, res, next) => {
  try {
    const { agent_id, tag_codes, wholesale_price_paisa } = req.body;

    if (!agent_id || !Array.isArray(tag_codes) || tag_codes.length === 0) {
      return res.status(400).json({
        success: false,
        message: "Agent and tag codes required",
      });
    }

    for (const code of tag_codes) {
      const upper = code.toUpperCase();

      const { rows } = await query(
        "SELECT id FROM qr_tags WHERE tag_code=$1 AND status='unactivated' AND assigned_to_agent IS NULL",
        [upper]
      );

      if (!rows.length) continue;

      await query(
        "UPDATE qr_tags SET assigned_to_agent=$1, assigned_at=NOW() WHERE tag_code=$2",
        [agent_id, upper]
      );

      await query(
        "INSERT INTO agent_inventory (agent_id, tag_id, purchase_price_paisa) VALUES ($1,$2,$3)",
        [agent_id, rows[0].id, wholesale_price_paisa || 10000]
      );
    }

    return res.json({
      success: true,
      message: "Tags assigned to agent",
    });

  } catch (err) {
    next(err);
  }
};

// ================= AGENTS =================
const listAgents = async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT a.*, 
      (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id) as total_tags,
      (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id AND status='sold') as sold_tags
      FROM agents a
      ORDER BY a.created_at DESC
    `);

    return res.json({ success: true, data: rows });

  } catch (err) {
    next(err);
  }
};

const approveAgent = async (req, res, next) => {
  try {
    await query(
      "UPDATE agents SET is_approved=true, approved_by=$1, updated_at=NOW() WHERE id=$2",
      [req.user.id, req.params.id]
    );

    return res.json({
      success: true,
      message: "Agent approved",
    });

  } catch (err) {
    next(err);
  }
};

// ================= USERS =================
const listUsers = async (req, res, next) => {
  try {
    const { page = 1, limit = 20 } = req.query;

    const { rows } = await query(
      `SELECT u.*, 
      (SELECT COUNT(*) FROM assets WHERE user_id=u.id AND is_active=true) as asset_count,
      (SELECT COUNT(*) FROM subscriptions WHERE user_id=u.id AND status='active') as active_subs
      FROM users u
      ORDER BY u.created_at DESC
      LIMIT $1 OFFSET $2`,
      [limit, (page - 1) * limit]
    );

    return res.json({ success: true, data: rows });

  } catch (err) {
    next(err);
  }
};

// ================= TAGS =================
const listTags = async (req, res, next) => {
  try {
    const { status = "" } = req.query;

    const baseQuery = `
      SELECT qt.*, u.name as owner_name, u.phone as owner_phone, a.name as agent_name
      FROM qr_tags qt
      LEFT JOIN users u ON qt.sold_to_user=u.id
      LEFT JOIN agents a ON qt.assigned_to_agent=a.id
    `;

    const finalQuery =
      baseQuery +
      (status ? " WHERE qt.status=$1" : "") +
      " ORDER BY qt.created_at DESC LIMIT 100";

    const { rows } = await query(finalQuery, status ? [status] : []);

    return res.json({ success: true, data: rows });

  } catch (err) {
    next(err);
  }
};

// ================= CATEGORY =================
const updateCategoryPrice = async (req, res, next) => {
  try {
    const { yearly_price_paisa, renewal_price_paisa, name } = req.body;

    const { rows } = await query(
      `UPDATE asset_categories 
       SET yearly_price_paisa=COALESCE($1,yearly_price_paisa),
           renewal_price_paisa=COALESCE($2,renewal_price_paisa),
           name=COALESCE($3,name),
           updated_at=NOW()
       WHERE id=$4 RETURNING *`,
      [yearly_price_paisa, renewal_price_paisa, name, req.params.id]
    );

    if (!rows.length) {
      return res.status(404).json({
        success: false,
        message: "Category not found",
      });
    }

    return res.json({
      success: true,
      message: "Category updated",
      data: rows[0],
    });

  } catch (err) {
    next(err);
  }
};

// ================= REVENUE =================
const getRevenue = async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT DATE_TRUNC('month',paid_at) as month,
             SUM(amount_paisa) as total,
             COUNT(*) as transactions
      FROM payment_orders
      WHERE status='paid'
      GROUP BY 1
      ORDER BY 1 DESC
      LIMIT 12
    `);

    return res.json({ success: true, data: rows });

  } catch (err) {
    next(err);
  }
};

// ================= TOGGLE USER =================
const toggleUser = async (req, res, next) => {
  try {
    const { rows } = await query(
      "UPDATE users SET is_active=NOT is_active WHERE id=$1 RETURNING id,is_active",
      [req.params.id]
    );

    return res.json({ success: true, data: rows[0] });

  } catch (err) {
    next(err);
  }
};

// ================= CATEGORIES =================
const getCategories = async (req, res, next) => {
  try {
    const { rows } = await query(`
      SELECT *,
      (SELECT COUNT(*) FROM assets WHERE category_id=ac.id) as total_assets
      FROM asset_categories ac
      ORDER BY sort_order
    `);

    return res.json({ success: true, data: rows });

  } catch (err) {
    next(err);
  }
};

// ================= EXPORT =================
module.exports = {
  getDashboard,
  generateTags,
  assignTagsToAgent,
  listAgents,
  approveAgent,
  listUsers,
  listTags,
  updateCategoryPrice,
  getRevenue,
  toggleUser,
  getCategories,
};
        code = genTagCode();
        const { rows } = await query("SELECT id FROM qr_tags WHERE tag_code=$1", [code]);
        exists = rows.length > 0;
      }
      await query("INSERT INTO qr_tags (id, tag_code, batch_id) VALUES ($1,$2,$3)", [uuidv4(), code, batchId]);
      codes.push(code);
    }
    logger.info("Generated " + count + " tags in batch " + batchId);
    res.json({ success: true, message: count + " tags generated", data: { codes, batchId, count } });
  } catch (err) { next(err); }
};

const assignTagsToAgent = async (req, res, next) => {
  try {
    const { agent_id, tag_codes, wholesale_price_paisa } = req.body;
    if (!agent_id || !tag_codes?.length) return res.status(400).json({ success: false, message: "Agent and tag codes required" });
    for (const code of tag_codes) {
      const { rows } = await query("SELECT id FROM qr_tags WHERE tag_code=$1 AND status='unactivated' AND assigned_to_agent IS NULL", [code.toUpperCase()]);
      if (!rows.length) continue;
      await query("UPDATE qr_tags SET assigned_to_agent=$1, assigned_at=NOW() WHERE tag_code=$2", [agent_id, code.toUpperCase()]);
      await query("INSERT INTO agent_inventory (agent_id, tag_id, purchase_price_paisa) VALUES ($1,$2,$3)",
        [agent_id, rows[0].id, wholesale_price_paisa || 10000]);
    }
    res.json({ success: true, message: "Tags assigned to agent" });
  } catch (err) { next(err); }
};

const listAgents = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT a.*, (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id) as total_tags, (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id AND status='sold') as sold_tags FROM agents a ORDER BY a.created_at DESC"
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const approveAgent = async (req, res, next) => {
  try {
    await query("UPDATE agents SET is_approved=true, approved_by=$1, updated_at=NOW() WHERE id=$2", [req.user.id, req.params.id]);
    res.json({ success: true, message: "Agent approved" });
  } catch (err) { next(err); }
};

const listUsers = async (req, res, next) => {
  try {
    const { page=1, limit=20 } = req.query;
    const { rows } = await query(
      "SELECT u.*, (SELECT COUNT(*) FROM assets WHERE user_id=u.id AND is_active=true) as asset_count, (SELECT COUNT(*) FROM subscriptions WHERE user_id=u.id AND status='active') as active_subs FROM users u ORDER BY u.created_at DESC LIMIT $1 OFFSET $2",
      [limit, (page-1)*limit]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const listTags = async (req, res, next) => {
  try {
    const { status="" } = req.query;
    const { rows } = await query(
      "SELECT qt.*, u.name as owner_name, u.phone as owner_phone, a.name as agent_name FROM qr_tags qt LEFT JOIN users u ON qt.sold_to_user=u.id LEFT JOIN agents a ON qt.assigned_to_agent=a.id" + (status ? " WHERE qt.status=$1" : "") + " ORDER BY qt.created_at DESC LIMIT 100",
      status ? [status] : []
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const updateCategoryPrice = async (req, res, next) => {
  try {
    const { yearly_price_paisa, renewal_price_paisa, name } = req.body;
    const { rows } = await query(
      "UPDATE asset_categories SET yearly_price_paisa=COALESCE($1,yearly_price_paisa), renewal_price_paisa=COALESCE($2,renewal_price_paisa), name=COALESCE($3,name), updated_at=NOW() WHERE id=$4 RETURNING *",
      [yearly_price_paisa, renewal_price_paisa, name, req.params.id]
    );
    if (!rows.length) return res.status(404).json({ success: false, message: "Category not found" });
    res.json({ success: true, message: "Category updated", data: rows[0] });
  } catch (err) { next(err); }
};

const getRevenue = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT DATE_TRUNC('month',paid_at) as month, SUM(amount_paisa) as total, COUNT(*) as transactions FROM payment_orders WHERE status='paid' GROUP BY 1 ORDER BY 1 DESC LIMIT 12"
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const toggleUser = async (req, res, next) => {
  try {
    const { rows } = await query("UPDATE users SET is_active=NOT is_active WHERE id=$1 RETURNING id,is_active", [req.params.id]);
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

const getCategories = async (req, res, next) => {
  try {
    const { rows } = await query("SELECT *, (SELECT COUNT(*) FROM assets WHERE category_id=ac.id) as total_assets FROM asset_categories ac ORDER BY sort_order");
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

module.exports = { getDashboard, generateTags, assignTagsToAgent, listAgents, approveAgent, listUsers, listTags, updateCategoryPrice, getRevenue, toggleUser, getCategories };
