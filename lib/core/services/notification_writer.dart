import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Writes the in-app notification straight from the app, the instant an
/// action happens, so the bell updates immediately (no waiting for the server
/// function's cold start). Ids are deterministic and the Edge Functions use
/// the SAME ids, so a notification is never duplicated; the functions now only
/// need to deliver the push.
class NotificationWriter {
  static final _db = FirebaseFirestore.instance;

  static const _statusCopy = <String, List<String>>{
    // status: [title, body-template ({salon}), type]
    'confirmed': ['Booking Confirmed', 'Your appointment at {salon} has been confirmed', 'booking_confirmed'],
    'in_progress': ['Booking Confirmed', 'Your appointment at {salon} has been confirmed', 'booking_confirmed'],
    'cancelled': ['Booking Cancelled', 'Your appointment at {salon} was cancelled', 'booking_cancelled'],
    'completed': ['Service Completed', "Your visit to {salon} is marked complete. Don't forget to rate it!", 'booking_confirmed'],
  };

  /// Customer just created a booking → notify the salon owner.
  static Future<void> newBooking(String bookingId) async {
    try {
      final snap = await _db.collection('bookings').doc(bookingId).get();
      final b = snap.data();
      if (b == null || b['ownerId'] == null) return;

      final isUrgent = b['isUrgent'] == true;
      final customer = (b['customerName'] ?? 'A customer').toString();
      final slot = (b['timeSlot'] ?? '').toString();
      final title = isUrgent ? '⚡ URGENT Booking Request' : 'New Booking Request';
      final body = isUrgent
          ? '$customer needs a slot at $slot — please respond quickly'
          : slot.isNotEmpty
          ? '$customer booked a slot at $slot'
          : '$customer just made a new booking';

      await _db.collection('notifications').doc('new_booking_$bookingId').set({
        'userId': b['ownerId'],
        'title': title,
        'body': body,
        'type': 'booking_confirmed',
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationWriter.newBooking skipped: $e');
    }
  }

  /// Owner changed a booking's status → notify the customer.
  static Future<void> bookingStatus(String bookingId, String status) async {
    try {
      final copy = _statusCopy[status];
      if (copy == null) return;
      final snap = await _db.collection('bookings').doc(bookingId).get();
      final b = snap.data();
      if (b == null || b['customerId'] == null) return;
      final salon = (b['salonName'] ?? 'the salon').toString();

      await _db.collection('notifications').doc('status_${bookingId}_$status').set({
        'userId': b['customerId'],
        'title': copy[0],
        'body': copy[1].replaceAll('{salon}', salon),
        'type': copy[2],
        'bookingId': bookingId,
        'read': false,
        'createdAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('NotificationWriter.bookingStatus skipped: $e');
    }
  }
}