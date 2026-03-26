const twilio = require("twilio");
const { query } = require("../config/database");
const logger = require("../utils/logger");

const initiateMaskedCall = async (tagId, callerPhone) => {
  const { rows } = await query(
    "SELECT u.phone as owner_phone FROM qr_tags qt JOIN users u ON qt.sold_to_user=u.id WHERE qt.id=$1 AND qt.status='active'",
    [tagId]
  );
  if (!rows.length) throw new Error("Tag not active");
  const client = twilio(process.env.TWILIO_ACCOUNT_SID, process.env.TWILIO_AUTH_TOKEN);
  const ownerPhone = rows[0].owner_phone;
  const call = await client.calls.create({
    url: process.env.BASE_URL + "/api/calls/twiml?target=" + encodeURIComponent(ownerPhone.startsWith("+") ? ownerPhone : "+91" + ownerPhone),
    to: callerPhone.startsWith("+") ? callerPhone : "+91" + callerPhone,
    from: process.env.TWILIO_PHONE_NUMBER,
    timeout: 30,
  });
  await query("INSERT INTO call_logs (tag_id, caller_phone, twilio_call_sid, status) VALUES ($1,$2,$3,'initiated')", [tagId, callerPhone, call.sid]);
  return { callSid: call.sid };
};

const generateTwiML = (target) => {
  const VR = twilio.twiml.VoiceResponse;
  const r = new VR();
  r.say("Connecting you to the asset owner. This call is private and protected by VahanTag.");
  const dial = r.dial({ callerId: process.env.TWILIO_PHONE_NUMBER, timeout: 30 });
  dial.number(target);
  return r.toString();
};

module.exports = { initiateMaskedCall, generateTwiML };
