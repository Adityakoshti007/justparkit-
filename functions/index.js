const functions = require("firebase-functions");
const admin = require("firebase-admin");
const nodemailer = require("nodemailer");

admin.initializeApp();

// Gmail credentials from Firebase config
const gmailEmail = functions.config().gmail.email;
const gmailPassword = functions.config().gmail.password;

// Create mail transporter
const transporter = nodemailer.createTransport({
  service: "gmail",
  auth: {
    user: gmailEmail,
    pass: gmailPassword,
  },
});

// Firestore trigger: send email on new booking
exports.sendBookingEmail = functions.firestore
    .document("bookings/{bookingId}")
    .onCreate(async (snap, context) => {
      try {
        const data = snap.data();
        if (!data) return null;

        const userId = data.userId;
        const parkingName = data.parkingName;
        const slotId = data.slotId;
        const price = data.price;

        // Fetch user email
        const userRecord = await admin.auth().getUser(userId);
        const userEmail = userRecord.email;

        if (!userEmail) return null;

        const mailOptions = {
          from: `"JustParkIt" <${gmailEmail}>`,
          to: userEmail,
          subject: "✅ Parking Booking Confirmed",
          html: `
          <h2>Booking Successful 🚗</h2>
          <p><b>Parking:</b> ${parkingName}</p>
          <p><b>Slot:</b> ${slotId}</p>
          <p><b>Total Paid:</b> ₹${price}</p>
          <br/>
          <p>Thank you for using <b>JustParkIt</b></p>
        `,
        };

        await transporter.sendMail(mailOptions);
        console.log("Booking email sent to:", userEmail);
        return null;
      } catch (error) {
        console.error("Email send failed:", error);
        return null;
      }
    });
