const { query } = require("../config/database");
const { initiateMaskedCall, generateTwiML } = require("../services/callService");
const logger = require("../utils/logger");

const HELPLINES = {
  ambulance: { name: "Ambulance", number: "108", icon: "🚑" },
  police: { name: "Police", number: "100", icon: "👮" },
  women: { name: "Women Helpline", number: "1091", icon: "👩" },
  fire: { name: "Fire Brigade", number: "101", icon: "🔥" },
  disaster: { name: "Disaster Management", number: "108", icon: "⚠️" },
  child: { name: "Child Helpline", number: "1098", icon: "👶" },
};

// GET /e/:tagCode — PUBLIC emergency page
const getEmergencyPage = async (req, res, next) => {
  try {
    const { tagCode } = req.params;

    const { rows } = await query(
      `SELECT qt.id, qt.status, qt.expires_at, qt.scan_count,
              a.id as asset_id, a.name as asset_name, a.description, a.photo_url,
              a.registration_number, a.make, a.model, a.color, a.vehicle_type,
              a.pet_breed, a.brand, a.serial_number, a.additional_info,
              ac.name as category_name, ac.icon as category_icon, ac.slug as category_slug,
              u.name as owner_name, u.blood_group, u.medical_notes,
              s.status as sub_status, s.expires_at as sub_expires
       FROM qr_tags qt
       LEFT JOIN assets a ON a.tag_id = qt.id AND a.is_active = true
       LEFT JOIN asset_categories ac ON a.category_id = ac.id
       LEFT JOIN users u ON qt.sold_to_user = u.id
       LEFT JOIN subscriptions s ON s.tag_id = qt.id AND s.status = 'active'
       WHERE qt.tag_code = $1`,
      [tagCode.toUpperCase()]
    );

    if (!rows.length) return res.json({ success: true, pageType: "not_found" });
    const tag = rows[0];

    // Log scan
    await query("INSERT INTO scan_logs (tag_id, scanner_ip, scanner_user_agent) VALUES ($1,$2,$3)",
      [tag.id, req.ip, req.headers["user-agent"]]);
    await query("UPDATE qr_tags SET scan_count=scan_count+1, last_scanned_at=NOW() WHERE id=$1", [tag.id]);

    if (tag.status === "unactivated") return res.json({ success: true, pageType: "unactivated" });
    if (tag.status === "deactivated") return res.json({ success: true, pageType: "deactivated" });

    const subActive = tag.sub_status === "active" && new Date(tag.sub_expires) > new Date();

    // Asset info (always visible)
    const assetInfo = {
      name: tag.asset_name,
      category: tag.category_name,
      categoryIcon: tag.category_icon,
      categorySlug: tag.category_slug,
      description: tag.description,
      photoUrl: tag.photo_url,
      registrationNumber: tag.registration_number,
      make: tag.make,
      model: tag.model,
      color: tag.color,
      vehicleType: tag.vehicle_type,
      petBreed: tag.pet_breed,
      brand: tag.brand,
      serialNumber: tag.serial_number,
      ownerName: tag.owner_name,
    };

    // Medical info for emergency
    const medicalInfo = subActive ? {
      bloodGroup: tag.blood_group,
      medicalNotes: tag.medical_notes,
    } : null;

    if (!subActive) {
      return res.json({
        success: true, pageType: "expired",
        assetInfo, helplines: HELPLINES,
        contactAvailable: false,
      });
    }

    // Emergency contacts
    const { rows: contacts } = await query(
      `SELECT name, relation, is_primary,
              substring(phone, 1, 2) || '****' || substring(phone, length(phone)-3) as masked_phone
       FROM emergency_contacts WHERE asset_id=$1 ORDER BY priority`,
      [tag.asset_id]
    );

    return res.json({
      success: true, pageType: "active",
      tagId: tag.id,
      assetInfo, medicalInfo,
      emergencyContacts: contacts,
      helplines: HELPLINES,
      contactAvailable: true,
    });
  } catch (err) { next(err); }
};

// POST /api/emergency/:tagId/call
const initiateCall = async (req, res, next) => {
  try {
    const { callerPhone } = req.body;
    if (!callerPhone || !/^[6-9]\d{9}$/.test(callerPhone)) {
      return res.status(400).json({ success: false, message: "Valid Indian mobile required" });
    }
    const result = await initiateMaskedCall(req.params.tagId, callerPhone);
    await query("INSERT INTO scan_logs (tag_id, scanner_ip, action_taken) VALUES ($1,$2,'called')", [req.params.tagId, req.ip]);
    res.json({ success: true, message: "Calling you now! Please answer your phone.", data: result });
  } catch (err) { next(err); }
};

// GET /api/emergency/:tagId/whatsapp
const getWhatsApp = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT u.phone FROM qr_tags qt JOIN users u ON qt.sold_to_user=u.id JOIN subscriptions s ON s.tag_id=qt.id WHERE qt.id=$1 AND s.status='active' AND s.expires_at>NOW()",
      [req.params.tagId]
    );
    if (!rows.length) return res.status(403).json({ success: false, message: "Contact unavailable" });
    const phone = rows[0].phone.replace(/\D/g, "");
    const waPhone = phone.startsWith("91") ? phone : "91" + phone;
    const msg = encodeURIComponent("Hello! I found your asset. This message is sent via VahanTag emergency system.");
    await query("INSERT INTO scan_logs (tag_id, scanner_ip, action_taken) VALUES ($1,$2,'whatsapped')", [req.params.tagId, req.ip]);
    res.json({ success: true, data: { whatsappLink: "https://wa.me/" + waPhone + "?text=" + msg } });
  } catch (err) { next(err); }
};

const getTwiML = (req, res) => {
  const target = req.query.target;
  if (!target) return res.status(400).send("Bad request");
  res.type("text/xml").send(generateTwiML(target));
};

module.exports = { getEmergencyPage, initiateCall, getWhatsApp, getTwiML };
