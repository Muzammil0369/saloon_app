const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

/**
 * Sends a notification to the salon owner when a new booking is created.
 */
exports.sendBookingNotificationToOwner = onDocumentCreated("bookings/{bookingId}", async (event) => {
  const snapshot = event.data;
  if (!snapshot) {
    console.log("No data associated with the event");
    return;
  }

  const booking = snapshot.data();
  const ownerId = booking.ownerId;
  const salonName = booking.salonName || "Your Salon";
  const customerName = booking.customerName || "A customer";
  const totalPrice = booking.totalPrice || 0;

  if (!ownerId) {
    console.log("No ownerId found in booking:", event.params.bookingId);
    return;
  }

  try {
    // 1. Get the owner's FCM token from the 'owners' collection
    const ownerDoc = await admin.firestore().collection("owners").doc(ownerId).get();

    if (!ownerDoc.exists) {
      console.log("Owner document not found:", ownerId);
      return;
    }

    const fcmToken = ownerDoc.data().fcmToken;

    if (!fcmToken) {
      console.log("No FCM token found for owner:", ownerId);
      return;
    }

    // 2. Construct the notification message
    const message = {
      notification: {
        title: "New Booking Received! ✂️",
        body: `${customerName} has booked a service at ${salonName} for Rs. ${totalPrice}.`,
      },
      data: {
        bookingId: event.params.bookingId,
        type: "new_booking",
      },
      token: fcmToken,
    };

    // 3. Send the notification
    const response = await admin.messaging().send(message);
    console.log("Successfully sent notification:", response);
  } catch (error) {
    console.error("Error sending notification:", error);
  }
});

// Since I want to handle status UPDATES, I'll use onDocumentUpdated
const {onDocumentUpdated} = require("firebase-functions/v2/firestore");

exports.sendBookingStatusNotificationToCustomer = onDocumentUpdated("bookings/{bookingId}", async (event) => {
  const beforeData = event.data.before.data();
  const afterData = event.data.after.data();

  // Only trigger if status has changed
  if (beforeData.status === afterData.status) {
    return;
  }

  const customerId = afterData.customerId;
  const newStatus = afterData.status; // e.g., 'confirmed', 'rejected'
  const salonName = afterData.salonName || "The Salon";

  if (!customerId) return;

  try {
    // 1. Get customer's FCM token from 'users' collection
    const customerDoc = await admin.firestore().collection("users").doc(customerId).get();
    if (!customerDoc.exists) return;

    const fcmToken = customerDoc.data().fcmToken;
    if (!fcmToken) return;

    // 2. Construct message based on status
    let title = "Booking Update";
    let body = `Your booking at ${salonName} is now ${newStatus}.`;

    if (newStatus === "confirmed") {
      title = "Booking Confirmed! ✅";
      body = `Great news! ${salonName} has accepted your booking. See you soon!`;
    } else if (newStatus === "rejected") {
      title = "Booking Declined ❌";
      body = `Sorry, ${salonName} cannot fulfill your booking at this time. Your payment will be refunded.`;
    }

    const message = {
      notification: {title, body},
      data: {
        bookingId: event.params.bookingId,
        type: "status_update",
      },
      token: fcmToken,
    };

    await admin.messaging().send(message);
    console.log(`Status update notification sent to customer ${customerId}`);
  } catch (error) {
    console.error("Error sending status update notification:", error);
  }
});
