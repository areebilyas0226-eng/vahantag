const { query } = require("../config/database");

const getProfile = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT a.*, (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id) as total_tags, (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id AND status='sold') as sold_tags, (SELECT COUNT(*) FROM agent_inventory WHERE agent_id=a.id AND status='in_stock') as in_stock FROM agents a WHERE a.id=$1",
      [req.user.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, email, city, state, address } = req.body;
    const { rows } = await query(
      "UPDATE agents SET name=$1,email=$2,city=$3,state=$4,address=$5,updated_at=NOW() WHERE id=$6 RETURNING *",
      [name, email, city, state, address, req.user.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

const getInventory = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT ai.*, qt.tag_code, qt.status as tag_status FROM agent_inventory ai JOIN qr_tags qt ON ai.tag_id=qt.id WHERE ai.agent_id=$1 ORDER BY ai.created_at DESC",
      [req.user.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const recordSale = async (req, res, next) => {
  try {
    const { tag_code, customer_phone, customer_name, sold_price_paisa } = req.body;
    if (!tag_code || !customer_phone) return res.status(400).json({ success: false, message: "Tag code and customer phone required" });

    const { rows: tagRows } = await query(
      "SELECT qt.id FROM qr_tags qt JOIN agent_inventory ai ON qt.id=ai.tag_id WHERE qt.tag_code=$1 AND ai.agent_id=$2 AND ai.status='in_stock'",
      [tag_code.toUpperCase(), req.user.id]
    );
    if (!tagRows.length) return res.status(404).json({ success: false, message: "Tag not in your inventory" });

    // Register customer if new
    const { rows: userRows } = await query(
      "INSERT INTO users (phone, name, referred_by_agent) VALUES ($1,$2,$3) ON CONFLICT (phone) DO UPDATE SET updated_at=NOW() RETURNING id",
      [customer_phone, customer_name || null, req.user.id]
    );

    // Mark sale
    await query(
      "UPDATE agent_inventory SET status='sold', sold_to_user=$1, sold_at=NOW(), sold_price_paisa=$2 WHERE tag_id=$3 AND agent_id=$4",
      [userRows[0].id, sold_price_paisa, tagRows[0].id, req.user.id]
    );
    await query("UPDATE qr_tags SET sold_to_user=$1 WHERE id=$2", [userRows[0].id, tagRows[0].id]);
    await query("UPDATE agents SET total_tags_sold=total_tags_sold+1 WHERE id=$1", [req.user.id]);

    res.json({ success: true, message: "Sale recorded! Customer can now activate the tag.", data: { customerId: userRows[0].id, tagCode: tag_code.toUpperCase() } });
  } catch (err) { next(err); }
};

const getSalesHistory = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT ai.*, qt.tag_code, u.name as customer_name, u.phone as customer_phone FROM agent_inventory ai JOIN qr_tags qt ON ai.tag_id=qt.id LEFT JOIN users u ON ai.sold_to_user=u.id WHERE ai.agent_id=$1 AND ai.status='sold' ORDER BY ai.sold_at DESC",
      [req.user.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

module.exports = { getProfile, updateProfile, getInventory, recordSale, getSalesHistory };
