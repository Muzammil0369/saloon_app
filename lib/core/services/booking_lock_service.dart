import 'package:cloud_firestore/cloud_firestore.dart';

class SlotTakenException implements Exception {
  @override
  String toString() => 'slot_taken';
}

/// Prevents two customers from booking the same staff member / time at the
/// same moment.
///
/// Every 30-minute slot a booking occupies gets a "lock" document whose id is
/// deterministic: `{ownerId}_{yyyyMMdd}_{staffId}_{minuteOfDay}`. The booking
/// and its locks are written in ONE Firestore transaction. If two people try
/// at the same time, Firestore lets only one transaction commit; the other
/// retries, sees the lock and throws [SlotTakenException].
///
/// A lock whose booking was cancelled is treated as free (and overwritten),
/// so no cleanup code is needed anywhere else.
class BookingLockService {
  static const Set<String> _freeingStatuses = {'cancelled', 'rejected'};

  static String lockId(
      String ownerId, DateTime day, String staffId, int minuteOfDay) {
    final d =
        '${day.year}${day.month.toString().padLeft(2, '0')}${day.day.toString().padLeft(2, '0')}';
    return '${ownerId}_${d}_${staffId}_${minuteOfDay % (24 * 60)}';
  }

  /// [startMinute] = start of the first slot (minutes since midnight, may
  /// exceed 1440 for after-midnight slots); [slotCount] = number of 30-minute
  /// slots the services need.
  static Future<void> createBookingWithLocks({
    required DocumentReference<Map<String, dynamic>> bookingRef,
    required Map<String, dynamic> bookingData,
    required String ownerId,
    required DateTime day,
    required String staffId,
    required int startMinute,
    required int slotCount,
  }) async {
    final db = FirebaseFirestore.instance;
    final lockRefs = <DocumentReference<Map<String, dynamic>>>[
      for (int k = 0; k < slotCount; k++)
        db
            .collection('slot_locks')
            .doc(lockId(ownerId, day, staffId, startMinute + 30 * k)),
    ];

    await db.runTransaction((tx) async {
      // ---- all reads first ----
      final lockSnaps = <DocumentSnapshot<Map<String, dynamic>>>[];
      for (final r in lockRefs) {
        lockSnaps.add(await tx.get(r));
      }

      for (final snap in lockSnaps) {
        if (!snap.exists) continue;
        final otherBookingId = snap.data()?['bookingId'] as String?;
        if (otherBookingId == null) throw SlotTakenException();

        final other =
        await tx.get(db.collection('bookings').doc(otherBookingId));
        final status = other.data()?['status'] as String?;
        final stillActive = other.exists && !_freeingStatuses.contains(status);
        if (stillActive) throw SlotTakenException();
        // otherwise: stale lock from a cancelled booking -> reuse it
      }

      // ---- then writes ----
      tx.set(bookingRef, bookingData);
      for (int k = 0; k < lockRefs.length; k++) {
        tx.set(lockRefs[k], {
          'ownerId': ownerId,
          'staffId': staffId,
          'bookingId': bookingRef.id,
          'minuteOfDay': (startMinute + 30 * k) % (24 * 60),
          'date': Timestamp.fromDate(DateTime(day.year, day.month, day.day)),
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    });
  }
}