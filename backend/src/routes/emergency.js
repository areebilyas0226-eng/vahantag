const router = require("express").Router();
const { getEmergencyPage, initiateCall, getWhatsApp, getTwiML } = require("../controllers/emergencyController");
const { scanLimiter, callLimiter } = require("../middleware/rateLimiter");
router.get("/page/:tagCode", scanLimiter, getEmergencyPage);
router.post("/:tagId/call", callLimiter, initiateCall);
router.get("/:tagId/whatsapp", scanLimiter, getWhatsApp);
router.get("/calls/twiml", getTwiML);
module.exports = router;
