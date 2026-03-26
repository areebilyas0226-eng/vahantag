const { query } = require("../config/database");
const QRCode = require("qrcode");

const getMyAssets = async (req, res, next) => {
  try {
    const { rows } = await query(
      `SELECT a.*, ac.name as category_name, ac.icon, ac.slug,
              qt.tag_code, qt.status as tag_status, qt.expires_at, qt.scan_count,
              s.status as sub_status, s.expires_at as sub_expires
       FROM assets a
       LEFT JOIN asset_categories ac ON a.category_id=ac.id
       LEFT JOIN qr_tags qt ON a.tag_id=qt.id
       LEFT JOIN subscriptions s ON s.tag_id=qt.id AND s.status='active'
       WHERE a.user_id=$1 AND a.is_active=true ORDER BY a.created_at DESC`,
      [req.user.id]
    );
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const addAsset = async (req, res, next) => {
  try {
    const { category_id, name, description, registration_number, make, model, year, color, vehicle_type, pet_breed, brand, serial_number, additional_info } = req.body;
    if (!category_id || !name) return res.status(400).json({ success: false, message: "Category and name required" });
    const { rows } = await query(
      `INSERT INTO assets (user_id, category_id, name, description, registration_number, make, model, year, color, vehicle_type, pet_breed, brand, serial_number, additional_info)
       VALUES ($1,$2,$3,$4,$5,$6,$7,$8,$9,$10,$11,$12,$13,$14) RETURNING *`,
      [req.user.id, category_id, name, description, registration_number?.toUpperCase(), make, model, year, color, vehicle_type, pet_breed, brand, serial_number, JSON.stringify(additional_info || {})]
    );
    res.status(201).json({ success: true, message: "Asset added", data: rows[0] });
  } catch (err) { next(err); }
};

const updateAsset = async (req, res, next) => {
  try {
    const { name, description, make, model, year, color, vehicle_type, pet_breed, brand, serial_number } = req.body;
    const { rows } = await query(
      "UPDATE assets SET name=$1,description=$2,make=$3,model=$4,year=$5,color=$6,vehicle_type=$7,pet_breed=$8,brand=$9,serial_number=$10,updated_at=NOW() WHERE id=$11 AND user_id=$12 RETURNING *",
      [name, description, make, model, year, color, vehicle_type, pet_breed, brand, serial_number, req.params.id, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ success: false, message: "Asset not found" });
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

const deleteAsset = async (req, res, next) => {
  try {
    await query("UPDATE assets SET is_active=false WHERE id=$1 AND user_id=$2", [req.params.id, req.user.id]);
    res.json({ success: true, message: "Asset removed" });
  } catch (err) { next(err); }
};

const activateTag = async (req, res, next) => {
  try {
    const { tag_code, asset_id, blood_group } = req.body;
    if (!tag_code || !asset_id) return res.status(400).json({ success: false, message: "Tag code and asset required" });

    const { rows: tagRows } = await query("SELECT * FROM qr_tags WHERE tag_code=$1", [tag_code.toUpperCase()]);
    if (!tagRows.length) return res.status(404).json({ success: false, message: "Invalid tag code" });
    if (tagRows[0].status !== "unactivated") return res.status(400).json({ success: false, message: "Tag already activated or invalid" });

    const { rows: assetRows } = await query("SELECT * FROM assets WHERE id=$1 AND user_id=$2", [asset_id, req.user.id]);
    if (!assetRows.length) return res.status(404).json({ success: false, message: "Asset not found" });

    // Get category price
    const { rows: catRows } = await query("SELECT * FROM asset_categories WHERE id=$1", [assetRows[0].category_id]);
    if (!catRows.length) return res.status(400).json({ success: false, message: "Category not found" });

    // Update blood group if provided
    if (blood_group) await query("UPDATE users SET blood_group=$1 WHERE id=$2", [blood_group, req.user.id]);

    // Create payment order for activation
    const { createOrder } = require("../services/paymentService");
    const isRenewal = tagRows[0].sold_to_user === req.user.id;
    const price = isRenewal ? catRows[0].renewal_price_paisa : catRows[0].yearly_price_paisa;
    const order = await createOrder(price, req.user.id, { tagCode: tag_code, assetId: asset_id, categoryId: assetRows[0].category_id });

    res.json({
      success: true,
      message: "Tag found! Complete payment to activate.",
      data: {
        order,
        tagCode: tag_code.toUpperCase(),
        asset: assetRows[0],
        category: catRows[0],
        price,
        isRenewal,
      }
    });
  } catch (err) { next(err); }
};

const verifyActivationPayment = async (req, res, next) => {
  try {
    const { razorpay_order_id, razorpay_payment_id, razorpay_signature } = req.body;
    const { verifySignature } = require("../services/paymentService");

    if (!verifySignature(razorpay_order_id, razorpay_payment_id, razorpay_signature)) {
      return res.status(400).json({ success: false, message: "Payment verification failed" });
    }

    const { rows: orderRows } = await query("SELECT * FROM payment_orders WHERE razorpay_order_id=$1", [razorpay_order_id]);
    if (!orderRows.length) return res.status(404).json({ success: false, message: "Order not found" });

    const meta = orderRows[0].metadata;
    const expiresAt = new Date();
    expiresAt.setFullYear(expiresAt.getFullYear() + 1);

    // Activate tag
    await query(
      "UPDATE qr_tags SET status='active', sold_to_user=$1, activated_at=NOW(), expires_at=$2, updated_at=NOW() WHERE tag_code=$3",
      [req.user.id, expiresAt, meta.tagCode]
    );

    // Link asset to tag
    const { rows: tagRows } = await query("SELECT id FROM qr_tags WHERE tag_code=$1", [meta.tagCode]);
    await query("UPDATE assets SET tag_id=$1 WHERE id=$2", [tagRows[0].id, meta.assetId]);

    // Create subscription
    await query(
      "INSERT INTO subscriptions (user_id, tag_id, asset_id, category_id, status, price_paisa, starts_at, expires_at, razorpay_order_id, razorpay_payment_id) VALUES ($1,$2,$3,$4,'active',$5,NOW(),$6,$7,$8)",
      [req.user.id, tagRows[0].id, meta.assetId, meta.categoryId, orderRows[0].amount_paisa, expiresAt, razorpay_order_id, razorpay_payment_id]
    );

    // Update payment order
    await query("UPDATE payment_orders SET status='paid', razorpay_payment_id=$1, razorpay_signature=$2, paid_at=NOW() WHERE razorpay_order_id=$3",
      [razorpay_payment_id, razorpay_signature, razorpay_order_id]);

    // Generate QR
    const qrUrl = (process.env.QR_BASE_URL || "https://vahantag.com/e") + "/" + meta.tagCode;
    const qrImage = await QRCode.toDataURL(qrUrl, { errorCorrectionLevel: "H", width: 512, color: { dark: "#1a1a2e", light: "#ffffff" } });

    res.json({ success: true, message: "Tag activated! Your asset is now protected.", data: { expiresAt, qrUrl, qrImage } });
  } catch (err) { next(err); }
};

const getTagQR = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT qt.tag_code FROM assets a JOIN qr_tags qt ON a.tag_id=qt.id WHERE a.id=$1 AND a.user_id=$2",
      [req.params.assetId, req.user.id]
    );
    if (!rows.length) return res.status(404).json({ success: false, message: "Tag not found" });
    const qrUrl = (process.env.QR_BASE_URL || "https://vahantag.com/e") + "/" + rows[0].tag_code;
    const qrImage = await QRCode.toDataURL(qrUrl, { errorCorrectionLevel: "H", width: 512, color: { dark: "#1a1a2e", light: "#ffffff" } });
    res.json({ success: true, data: { tagCode: rows[0].tag_code, qrUrl, qrImage } });
  } catch (err) { next(err); }
};

const getCategories = async (req, res, next) => {
  try {
    const { rows } = await query("SELECT * FROM asset_categories WHERE is_active=true ORDER BY sort_order");
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const getEmergencyContacts = async (req, res, next) => {
  try {
    const { rows } = await query("SELECT id,name,relation,is_primary,priority, substring(phone,1,2)||'****'||substring(phone,length(phone)-3) as masked_phone FROM emergency_contacts WHERE asset_id=$1 AND user_id=$2 ORDER BY priority", [req.params.assetId, req.user.id]);
    res.json({ success: true, data: rows });
  } catch (err) { next(err); }
};

const addEmergencyContact = async (req, res, next) => {
  try {
    const { name, phone, relation, is_primary } = req.body;
    if (!name || !phone) return res.status(400).json({ success: false, message: "Name and phone required" });
    const { rows: cnt } = await query("SELECT COUNT(*) FROM emergency_contacts WHERE asset_id=$1", [req.params.assetId]);
    if (parseInt(cnt[0].count) >= 3) return res.status(400).json({ success: false, message: "Max 3 emergency contacts" });
    if (is_primary) await query("UPDATE emergency_contacts SET is_primary=false WHERE asset_id=$1", [req.params.assetId]);
    const { rows } = await query(
      "INSERT INTO emergency_contacts (user_id,asset_id,name,phone,relation,is_primary,priority) VALUES ($1,$2,$3,$4,$5,$6,$7) RETURNING id,name,relation,is_primary",
      [req.user.id, req.params.assetId, name, phone, relation, is_primary||false, parseInt(cnt[0].count)+1]
    );
    res.status(201).json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

module.exports = { getMyAssets, addAsset, updateAsset, deleteAsset, activateTag, verifyActivationPayment, getTagQR, getCategories, getEmergencyContacts, addEmergencyContact };
