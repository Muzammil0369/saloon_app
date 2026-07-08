import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get/get.dart';

class DatabaseService extends GetxService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Singleton pattern
  static DatabaseService get instance => Get.find();


  // ── User Profiles ──
  Future<void> saveUserProfile(String uid, Map<String, dynamic> data) async {
    await _firestore.collection('users').doc(uid).set(data, SetOptions(merge: true));
  }

  Future<DocumentSnapshot> getUserProfile(String uid) async {
    return await _firestore.collection('users').doc(uid).get();
  }

  // ── Salons/Owners ──

  // Stream all active salons (for Explore screen)
  Stream<QuerySnapshot> getActiveSalons() {
    return _firestore
        .collection('owners')
        .where('status', isEqualTo: 'approved')
        .where('isActive', isEqualTo: true)
        .snapshots();
  }

  // Get single salon details by owner ID (real-time)
  Stream<DocumentSnapshot> getSalonStream(String ownerId) {
    return _firestore.collection('owners').doc(ownerId).snapshots();
  }

  // Get single salon details once
  Future<DocumentSnapshot> getSalonById(String ownerId) async {
    return await _firestore.collection('owners').doc(ownerId).get();
  }

  Future<void> registerSalon(String uid, Map<String, dynamic> salonData, GeoPoint location) async {
    final data = {
      ...salonData,
      'location': location,
      'status': 'pending',
      'isActive': true,
      'showOnMap': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    };
    await _firestore.collection('owners').doc(uid).set(data, SetOptions(merge: true));
    await saveUserProfile(uid, {'role': 'owner', 'status': 'pending'});
  }

  // Update salon profile (owner updates their info)
  Future<void> updateSalonProfile(String ownerId, Map<String, dynamic> data) async {
    await _firestore.collection('owners').doc(ownerId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Services ──

  // Get services for a specific salon (real-time)
  Stream<QuerySnapshot> getSalonServices(String ownerId) {
    return _firestore
        .collection('services')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .orderBy('createdAt', descending: false)
        .snapshots();
  }

  // Get services once
  Future<List<Map<String, dynamic>>> getSalonServicesOnce(String ownerId) async {
    final snapshot = await _firestore
        .collection('services')
        .where('ownerId', isEqualTo: ownerId)
        .where('isActive', isEqualTo: true)
        .get();

    return snapshot.docs.map((doc) => {
      'id': doc.id,
      ...doc.data() as Map<String, dynamic>,
    }).toList();
  }

  // Add service (for owner)
  Future<void> addService(String ownerId, Map<String, dynamic> serviceData) async {
    await _firestore.collection('services').add({
      ...serviceData,
      'ownerId': ownerId,
      'isActive': true,
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Update service (for owner)
  Future<void> updateService(String serviceId, Map<String, dynamic> data) async {
    await _firestore.collection('services').doc(serviceId).update({
      ...data,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // Soft delete service
  Future<void> deleteService(String serviceId) async {
    await _firestore.collection('services').doc(serviceId).update({
      'isActive': false,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ── Salon Images ──
  Future<void> updateSalonImages(String ownerId, List<String> imageUrls) async {
    await _firestore.collection('owners').doc(ownerId).update({
      'salonPhotos': imageUrls,
      'thumbnail': imageUrls.isNotEmpty ? imageUrls.first : null,
      'updatedAt': FieldValue.serverTimestamp(),
    });
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
    return _firestore
        .collection('bookings')
        .where('customerId', isEqualTo: uid)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  Stream<QuerySnapshot> getOwnerBookings(String ownerId) {
    return _firestore
        .collection('bookings')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }

  // ── Reviews ──
  Stream<QuerySnapshot> getSalonReviews(String ownerId) {
    return _firestore
        .collection('reviews')
        .where('ownerId', isEqualTo: ownerId)
        .orderBy('createdAt', descending: true)
        .snapshots();
  }
}