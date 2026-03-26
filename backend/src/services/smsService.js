const twilio = require("twilio");
const logger = require("../utils/logger");

const sendOTP = async (phone, otp) => {
  try {
    // DEBUG — ye logs Railway mein dikhenge
    console.log("=== OTP DEBUG START ===");
    console.log("PHONE:", phone);
    console.log("SID:", process.env.TWILIO_ACCOUNT_SID ? "EXISTS" : "MISSING");
    console.log("TOKEN:", process.env.TWILIO_AUTH_TOKEN ? "EXISTS" : "MISSING");
    console.log("FROM:", process.env.TWILIO_PHONE_NUMBER);
    
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID, 
      process.env.TWILIO_AUTH_TOKEN
    );
    
    const to = phone.startsWith("+") ? phone : "+91" + phone;
    console.log("TO:", to);
    
    const message = await client.messages.create({
      body: `${otp} is your VahanTag OTP. Valid 10 minutes. Do not share. -VahanTag`,
      from: process.env.TWILIO_PHONE_NUMBER,
      to,
    });
    
    console.log("TWILIO RESPONSE SID:", message.sid);
    console.log("TWILIO STATUS:", message.status);
    console.log("=== OTP DEBUG END ===");
    
    logger.info("OTP sent to " + phone.slice(0,5) + "XXXXX");
    return { success: true };
    
  } catch (err) {
    console.log("=== OTP ERROR ===");
    console.log("ERROR CODE:", err.code);
    console.log("ERROR MESSAGE:", err.message);
    console.log("ERROR STATUS:", err.status);
    console.log("================");
    logger.error("OTP send failed:", err.message);
    throw new Error("Failed to send OTP");
  }
};

const sendSMS = async (phone, message) => {
  try {
    const client = twilio(
      process.env.TWILIO_ACCOUNT_SID, 
      process.env.TWILIO_AUTH_TOKEN
    );
    await client.messages.create({ 
      body: message, 
      from: process.env.TWILIO_PHONE_NUMBER, 
      to: phone.startsWith("+") ? phone : "+91" + phone 
    });
  } catch (err) { 
    console.log("SMS ERROR:", err.message);
    logger.error("SMS failed:", err.message); 
  }
};

module.exports = { sendOTP, sendSMS };