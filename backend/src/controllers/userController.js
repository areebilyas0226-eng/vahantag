const { query } = require("../config/database");

const getProfile = async (req, res, next) => {
  try {
    const { rows } = await query(
      "SELECT u.id,u.name,u.phone,u.email,u.blood_group,u.medical_notes,u.created_at, (SELECT COUNT(*) FROM assets WHERE user_id=u.id AND is_active=true) as asset_count, (SELECT COUNT(*) FROM subscriptions WHERE user_id=u.id AND status='active' AND expires_at>NOW()) as active_subs FROM users u WHERE u.id=$1",
      [req.user.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

const updateProfile = async (req, res, next) => {
  try {
    const { name, email, blood_group, medical_notes } = req.body;
    const { rows } = await query(
      "UPDATE users SET name=$1,email=$2,blood_group=$3,medical_notes=$4,updated_at=NOW() WHERE id=$5 RETURNING id,name,phone,email,blood_group,medical_notes",
      [name, email, blood_group, medical_notes, req.user.id]
    );
    res.json({ success: true, data: rows[0] });
  } catch (err) { next(err); }
};

module.exports = { getProfile, updateProfile };
