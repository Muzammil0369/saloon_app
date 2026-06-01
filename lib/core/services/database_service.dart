import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // ── User Profiles ──

  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // ── Salons ──

  Stream<QuerySnapshot> getSalons() {
    return _firestore.collection('salons').snapshots();
  }

  Future<void> registerSalon(String uid, Map<String, dynamic> salonData) async {
    await _firestore.collection('salons').doc(uid).set(salonData);
    // Also mark user as owner
    await saveUserProfile(uid, {'role': 'owner'});
  }

  // ── Bookings ──

  Future<void> createBooking(Map<String, dynamic> bookingData) async {
    await _firestore.collection('bookings').add({
      ...bookingData,
      'createdAt': FieldValue.serverTimestamp(),
      'status': 'pending',
    });
  }

  Stream<QuerySnapshot> getCustomerBookings(String uid) {
    return _firestore.collection('bookings')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getOwnerBookings(String salonId) {
    return _firestore.collection('bookings')
        .where('salonId', isEqualTo: salonId)
        .snapshots();
  }
}
